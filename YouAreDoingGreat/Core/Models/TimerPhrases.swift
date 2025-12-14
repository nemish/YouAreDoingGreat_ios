import Foundation

// MARK: - Timer Phrases Model
// Codable model for loading contextual phrases based on time since last moment

struct TimerPhrases: Codable {
    let zeroToTenMin: [String]
    let tenToThirtyMin: [String]
    let thirtyMinToTwoHour: [String]
    let twoHourAndMore: [String]

    enum CodingKeys: String, CodingKey {
        case zeroToTenMin = "0_to_10_min"
        case tenToThirtyMin = "10_to_30_min"
        case thirtyMinToTwoHour = "30_min_to_2_hour"
        case twoHourAndMore = "2_hour_and_more"
    }

    // MARK: - Loading

    static func load() -> TimerPhrases? {
        guard let url = Bundle.main.url(forResource: "TimerPhrases", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let phrases = try? JSONDecoder().decode(TimerPhrases.self, from: data) else {
            return nil
        }
        return phrases
    }

    // MARK: - Phrase Selection

    /// Returns a random phrase from the appropriate bucket based on minutes since last moment
    func randomPhrase(forMinutesSinceLast minutes: Int) -> String {
        let bucket: [String]
        switch minutes {
        case 0..<10:
            bucket = zeroToTenMin
        case 10..<30:
            bucket = tenToThirtyMin
        case 30..<120:
            bucket = thirtyMinToTwoHour
        default:
            bucket = twoHourAndMore
        }
        return bucket.randomElement() ?? ""
    }
}
