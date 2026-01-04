import SwiftUI

// MARK: - Toast Message

struct ToastMessage: Equatable {
    enum Style {
        case success
        case deleted
        case error
        case info

        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .deleted: return "trash.fill"
            case .error: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }

        var iconColor: Color {
            switch self {
            case .success: return .green
            case .deleted: return .textSecondary
            case .error: return .orange
            case .info: return .textSecondary
            }
        }
    }

    let id: UUID
    let message: String
    let style: Style
    let duration: TimeInterval

    init(message: String, style: Style = .info, duration: TimeInterval = 3.0) {
        self.id = UUID()
        self.message = message
        self.style = style
        self.duration = duration
    }

    static func == (lhs: ToastMessage, rhs: ToastMessage) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Toast Service

@MainActor
@Observable
final class ToastService {
    static let shared = ToastService()

    var currentToast: ToastMessage?

    private var dismissTask: Task<Void, Never>?

    private init() {}

    // MARK: - Public Methods

    /// Show a toast with custom message and style
    func show(_ message: String, style: ToastMessage.Style = .info, duration: TimeInterval = 3.0) {
        // Cancel any pending dismiss
        dismissTask?.cancel()

        // Show new toast
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            currentToast = ToastMessage(message: message, style: style, duration: duration)
        }

        // Schedule auto-dismiss
        scheduleDismiss(after: duration)
    }

    /// Convenience method for deletion confirmation
    func showDeleted(_ itemName: String = "Moment") {
        show("\(itemName) deleted", style: .deleted)
    }

    /// Convenience method for success messages
    func showSuccess(_ message: String) {
        show(message, style: .success)
    }

    /// Convenience method for error messages
    func showError(_ message: String) {
        show(message, style: .error, duration: 4.0)
    }

    /// Manually dismiss the current toast
    func dismiss() {
        dismissTask?.cancel()
        withAnimation(.easeOut(duration: 0.2)) {
            currentToast = nil
        }
    }

    // MARK: - Private Methods

    private func scheduleDismiss(after duration: TimeInterval) {
        dismissTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))

            guard !Task.isCancelled else { return }

            withAnimation(.easeOut(duration: 0.25)) {
                currentToast = nil
            }
        }
    }
}
