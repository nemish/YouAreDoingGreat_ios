import Foundation

// MARK: - Sparks Result
// Returned in POST /moments response alongside the moment item

struct SparksResult: Codable {
    let awarded: Int
    let totalSparks: Int
    let chapter: Int
    let chapterName: String
    let isNewChapter: Bool
}
