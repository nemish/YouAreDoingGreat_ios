import Foundation

// MARK: - Identifiable Tag Wrapper
// Wrapper to make tag strings identifiable for sheet presentation
// Used across the app for presenting FilteredMomentsSheet

struct IdentifiableTag: Identifiable {
    let id = UUID()
    let value: String
}
