import SwiftUI
import SwiftData

struct GalaxyView: View {
    @Environment(\.modelContext) private var modelContext
    @State var viewModel: GalaxyViewModel
    @State private var momentsListViewModel: MomentsListViewModel

    @State private var offset: CGSize = .zero
    @State private var isPanEnabled: Bool = true
    @State private var scrollToLatestTrigger: Bool = false
    @State private var highlightedMomentId: UUID?

    // Zoom state
    @State private var currentZoom: CGFloat = 1.0
    @State private var zoomAnchor: UnitPoint = .center
    @State private var lastMagnification: CGFloat = 1.0

    init(viewModel: GalaxyViewModel, momentsListViewModel: MomentsListViewModel) {
        _viewModel = State(initialValue: viewModel)
        _momentsListViewModel = State(initialValue: momentsListViewModel)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Night sky gradient background
                nightSkyBackground

                if viewModel.isEmpty {
                    emptyStateView
                } else {
                    // Scrollable star field with zoom support
                    ScrollViewReader { proxy in
                        ScrollView([.horizontal, .vertical], showsIndicators: false) {
                            starFieldContent
                                .frame(
                                    width: viewModel.canvasSize.width,
                                    height: viewModel.canvasSize.height
                                )
                                .scaleEffect(currentZoom, anchor: zoomAnchor)
                        }
                        .disabled(!isPanEnabled)
                        .simultaneousGesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastMagnification
                                    lastMagnification = value

                                    let newZoom = currentZoom * delta
                                    withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.8)) {
                                        currentZoom = min(max(newZoom, 0.1), 3.0)
                                    }
                                }
                                .onEnded { _ in
                                    lastMagnification = 1.0

                                    // Elastic bounce back if beyond limits
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        if currentZoom < 0.1 {
                                            currentZoom = 0.1
                                        } else if currentZoom > 3.0 {
                                            currentZoom = 3.0
                                        }
                                    }
                                }
                        )
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { gesture in
                                    // Update zoom anchor based on touch position
                                    let location = gesture.location
                                    zoomAnchor = UnitPoint(
                                        x: location.x / geometry.size.width,
                                        y: location.y / geometry.size.height
                                    )
                                }
                        )
                        .onChange(of: scrollToLatestTrigger) { _, _ in
                            scrollToLatestMoment(proxy: proxy, geometry: geometry)
                        }
                    }
                }
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $viewModel.showMomentDetail) {
            Task { await viewModel.dismissDetail() }
        } content: {
            if let moment = viewModel.selectedMoment {
                MomentDetailSheet(
                    initialMomentId: moment.clientId,
                    filterTag: nil,
                    viewModel: momentsListViewModel
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .toastContainer()
            }
        }
        .task {
            await viewModel.loadMoments()

            // Calculate zoom to fit all stars on screen
            if !viewModel.isEmpty {
                currentZoom = calculateFitZoom()
            }

            // Trigger scroll to center after moments are loaded
            scrollToLatestTrigger.toggle()
        }
        .onChange(of: viewModel.showMomentDetail) { _, newValue in
            isPanEnabled = !newValue
        }
    }

    // MARK: - Night Sky Background
    private var nightSkyBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.05, green: 0.05, blue: 0.15),  // Deep navy at top
                Color(red: 0.1, green: 0.05, blue: 0.2),     // Purple-navy middle
                Color(red: 0.15, green: 0.1, blue: 0.25)     // Lighter purple at bottom
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "sparkles")
                .font(.system(size: 64))
                .foregroundStyle(Color.appPrimary)

            VStack(spacing: 8) {
                Text("Your galaxy awaits...")
                    .font(.appTitle)
                    .foregroundStyle(.white)

                Text("Log your first moment to place your first star.")
                    .font(.appBody)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .multilineTextAlignment(.center)
        .padding(40)
    }

    // MARK: - Star Field Content
    private var starFieldContent: some View {
        ZStack(alignment: .topLeading) {
            // Clear background to enable full canvas scrolling
            Color.clear

            // DEBUG: Week cluster borders
            ForEach(viewModel.layoutData.weekClusters) { cluster in
                Rectangle()
                    .strokeBorder(Color.cyan.opacity(0.5), lineWidth: 2)
                    .frame(width: cluster.bounds.width, height: cluster.bounds.height)
                    .position(cluster.centerPosition)
                    .overlay(
                        Text("Week \(cluster.weekNumber)")
                            .font(.caption)
                            .foregroundColor(.cyan)
                            .position(x: cluster.bounds.width / 2, y: 10)
                    )
            }

            // 1. Constellation lines (background layer)
            ForEach(viewModel.layoutData.weekClusters) { cluster in
                // DEBUG: Show cluster info
                Text("Week \(cluster.weekNumber): \(cluster.momentIds.count) moments")
                    .font(.system(size: 10))
                    .foregroundColor(.purple)
                    .position(x: cluster.centerPosition.x, y: cluster.centerPosition.y - 170)

                if let edges = viewModel.layoutData.constellationLines[cluster.weekNumber] {
                    // DEBUG: Show edge count
                    Text("EDGES: \(edges.count)")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                        .bold()
                        .position(x: cluster.centerPosition.x, y: cluster.centerPosition.y - 150)

                    ConstellationLinesLayer(edges: edges)
                } else {
                    Text("NO EDGES DICT")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)
                        .position(x: cluster.centerPosition.x, y: cluster.centerPosition.y - 150)
                }
            }

            // 2. Stars (foreground layer)
            ForEach(viewModel.moments, id: \.clientId) { moment in
                let starPosition = viewModel.position(for: moment)

                GalaxyStarNode(
                    moment: moment,
                    position: starPosition,
                    colorIndex: viewModel.colorIndex(for: moment),
                    isHighlighted: highlightedMomentId == moment.clientId,
                    onTap: {
                        Task {
                            await HapticManager.shared.play(.gentleTap)
                            viewModel.selectMoment(moment)
                        }
                    }
                )
                .id(moment.clientId) // Add ID for ScrollViewReader
                .opacity(viewModel.deletedMomentIds.contains(moment.clientId) ? 0 : 1)
                .animation(.easeOut(duration: 0.3), value: viewModel.deletedMomentIds)

                // DEBUG: Show star position coordinates
                Text("★(\(Int(starPosition.x)),\(Int(starPosition.y)))")
                    .font(.system(size: 6))
                    .foregroundColor(.orange)
                    .position(x: starPosition.x + 20, y: starPosition.y)
            }
        }
    }

    // MARK: - Zoom Calculation
    private func calculateFitZoom() -> CGFloat {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first else {
            return 0.8
        }

        let screenSize = window.bounds.size
        let canvasSize = viewModel.canvasSize

        // Calculate zoom to fit canvas within screen with some padding
        let widthZoom = (screenSize.width * 0.9) / canvasSize.width
        let heightZoom = (screenSize.height * 0.9) / canvasSize.height

        // Use the smaller zoom to ensure everything fits
        let fitZoom = min(widthZoom, heightZoom)

        // Clamp to our zoom limits (0.1x to 3.0x)
        return min(max(fitZoom, 0.1), 3.0)
    }

    // MARK: - Scroll to Latest Moment
    private func scrollToLatestMoment(proxy: ScrollViewProxy, geometry: GeometryProxy) {
        guard !viewModel.moments.isEmpty else { return }

        // Find the most recent moment (highest submittedAt)
        if let latestMoment = viewModel.moments.max(by: { $0.submittedAt < $1.submittedAt }) {
            // Scroll to the latest moment with animation after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    proxy.scrollTo(latestMoment.clientId, anchor: .center)
                }

                // Highlight the latest star
                highlightedMomentId = latestMoment.clientId

                // Remove highlight after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        highlightedMomentId = nil
                    }
                }
            }
        }
    }
}

// MARK: - Constellation Lines Layer
private struct ConstellationLinesLayer: View {
    let edges: Set<DelaunayTriangulator.Edge>

    var body: some View {
        ForEach(Array(edges).indices, id: \.self) { index in
            let edge = Array(edges)[index]

            // DEBUG: Draw thick colored line
            Path { path in
                path.move(to: edge.start)
                path.addLine(to: edge.end)
            }
            .stroke(Color.cyan, lineWidth: 3.0)

            // DEBUG: Mark endpoints with circles
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
                .position(edge.start)

            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)
                .position(edge.end)

            // DEBUG: Show coordinates
            Text("(\(Int(edge.start.x)),\(Int(edge.start.y)))")
                .font(.system(size: 8))
                .foregroundColor(.yellow)
                .position(x: edge.start.x, y: edge.start.y - 10)
        }
    }
}

// MARK: - Preview
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Moment.self, configurations: config)
    let context = container.mainContext

    // Add sample moments
    let moment1 = Moment(
        text: "Completed a challenging project",
        submittedAt: Date(),
        happenedAt: Date(),
        timezone: TimeZone.current.identifier,
        timeAgo: nil,
        offlinePraise: "Nice — that counts!"
    )

    let moment2 = Moment(
        text: "Finished a great workout",
        submittedAt: Date().addingTimeInterval(-86400),
        happenedAt: Date().addingTimeInterval(-86400),
        timezone: TimeZone.current.identifier,
        timeAgo: nil,
        offlinePraise: "Amazing progress!"
    )

    // Set favorite and insert moments
    moment2.isFavorite = true
    context.insert(moment1)
    context.insert(moment2)

    let repository = SwiftDataMomentRepository(modelContext: context)
    let galaxyViewModel = GalaxyViewModel(
        repository: repository,
        screenSize: CGSize(width: 393, height: 852)
    )

    let apiClient = DefaultAPIClient()
    let momentService = MomentService(apiClient: apiClient, repository: repository)
    let momentsListViewModel = MomentsListViewModel(
        momentService: momentService,
        repository: repository
    )

    return GalaxyView(
        viewModel: galaxyViewModel,
        momentsListViewModel: momentsListViewModel
    )
    .modelContainer(container)
}
