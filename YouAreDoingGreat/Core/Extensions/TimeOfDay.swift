import Foundation
import SwiftUI

// MARK: - Time of Day
// Determines styling based on when a moment happened

enum TimeOfDay {
    case earlyMorning  // 5-8 AM
    case morning       // 8-12 PM
    case afternoon     // 12-5 PM
    case evening       // 5-8 PM
    case night         // 8 PM - 5 AM

    init(from date: Date) {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)

        switch hour {
        case 5..<8:
            self = .earlyMorning
        case 8..<12:
            self = .morning
        case 12..<17:
            self = .afternoon
        case 17..<20:
            self = .evening
        default:
            self = .night
        }
    }

    // Background color for moment cards - dark shades with subtle variations
    var backgroundColor: Color {
        switch self {
        case .earlyMorning:
            return Color.white.opacity(0.12) // Lighter for morning energy
        case .morning:
            return Color.white.opacity(0.10)
        case .afternoon:
            return Color.white.opacity(0.08) // Standard darkness
        case .evening:
            return Color.white.opacity(0.06) // Darker
        case .night:
            return Color.white.opacity(0.04) // Darkest for night
        }
    }

    // Accent color for icons (full brightness)
    var accentColor: Color {
        switch self {
        case .earlyMorning:
            return Color(red: 0x2a / 255, green: 0x9d / 255, blue: 0x8f / 255) // Teal
        case .morning:
            return Color(red: 0x00 / 255, green: 0x77 / 255, blue: 0xb6 / 255) // Blue
        case .afternoon:
            return Color(red: 0xe7 / 255, green: 0x6f / 255, blue: 0x51 / 255) // Orange
        case .evening:
            return Color(red: 0xae / 255, green: 0x20 / 255, blue: 0x12 / 255) // Red
        case .night:
            return Color(red: 0x00 / 255, green: 0x35 / 255, blue: 0x66 / 255) // Dark blue
        }
    }

    // Border color (subtle, less bright than icons)
    var borderColor: Color {
        accentColor.opacity(0.4)
    }

    // Icon name for time of day
    var iconName: String {
        switch self {
        case .earlyMorning:
            return "sunrise.fill"
        case .morning:
            return "cloud.sun.fill"
        case .afternoon:
            return "sun.max.fill"
        case .evening:
            return "sunset.fill"
        case .night:
            return "moon.stars.fill"
        }
    }

    // Text color for content on this background
    var textColor: Color {
        .white
    }
}
