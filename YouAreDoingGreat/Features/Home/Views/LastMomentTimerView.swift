import SwiftUI

// MARK: - Last Moment Timer View

struct LastMomentTimerView: View {
    let timeValue: String
    let phrase: String

    var body: some View {
        VStack(spacing: 4) {
            if timeValue == "Just logged." {
                Text(timeValue)
                    .font(.appCaption)
                    .foregroundStyle(.textPrimary.opacity(0.7))
            } else {
                HStack(spacing: 0) {
                    Text(timeValue)
                        .font(.appCaption)
                        .foregroundStyle(.textPrimary.opacity(0.7))
                    Text(" since last moment")
                        .font(.appCaption)
                        .foregroundStyle(.textPrimary.opacity(0.4))
                }
            }
            Text(phrase)
                .font(.appCaption)
                .foregroundStyle(.textPrimary.opacity(0.4))
        }
        .multilineTextAlignment(.center)
    }

    // MARK: - Time Formatting

    static func formatTimeValue(totalMinutes: Int) -> String {
        if totalMinutes == 0 {
            return "Just logged."
        }

        let days = totalMinutes / (60 * 24)
        let hours = (totalMinutes % (60 * 24)) / 60
        let minutes = totalMinutes % 60

        var components: [String] = []

        if days > 0 {
            components.append("\(days) day\(days != 1 ? "s" : "")")
        }

        if hours > 0 {
            components.append("\(hours) hour\(hours != 1 ? "s" : "")")
        }

        if minutes > 0 {
            components.append("\(minutes) minute\(minutes != 1 ? "s" : "")")
        }

        // Edge case: if all components are 0 but totalMinutes > 0, show minutes
        // This shouldn't happen mathematically, but handle it gracefully
        if components.isEmpty {
            return "\(minutes) minute\(minutes != 1 ? "s" : "")"
        }

        return components.joined(separator: " ")
    }
}

// MARK: - Previews

#Preview("0 minutes") {
    ZStack {
        Color.background.ignoresSafeArea()
        LastMomentTimerView(
            timeValue: LastMomentTimerView.formatTimeValue(totalMinutes: 0),
            phrase: "Nice. That one mattered."
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("5 minutes") {
    ZStack {
        Color.background.ignoresSafeArea()
        LastMomentTimerView(
            timeValue: LastMomentTimerView.formatTimeValue(totalMinutes: 5),
            phrase: "Nice. That one mattered."
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("25 minutes") {
    ZStack {
        Color.background.ignoresSafeArea()
        LastMomentTimerView(
            timeValue: LastMomentTimerView.formatTimeValue(totalMinutes: 25),
            phrase: "If something else happened, feel free to add it."
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("2h 45m") {
    ZStack {
        Color.background.ignoresSafeArea()
        LastMomentTimerView(
            timeValue: LastMomentTimerView.formatTimeValue(totalMinutes: 165),
            phrase: "If nothing comes to mind, try something simple — it counts."
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("14h 30m") {
    ZStack {
        Color.background.ignoresSafeArea()
        LastMomentTimerView(
            timeValue: LastMomentTimerView.formatTimeValue(totalMinutes: 870),
            phrase: "There's always at least one win hiding somewhere."
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("1 day 15 minutes (0 hours)") {
    ZStack {
        Color.background.ignoresSafeArea()
        LastMomentTimerView(
            timeValue: LastMomentTimerView.formatTimeValue(totalMinutes: 1455), // 1 day + 15 minutes
            phrase: "It doesn't have to be big. Whatever moment works."
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("2 days 2 hours (0 minutes)") {
    ZStack {
        Color.background.ignoresSafeArea()
        LastMomentTimerView(
            timeValue: LastMomentTimerView.formatTimeValue(totalMinutes: 3000), // 2 days + 2 hours
            phrase: "Whatever it is, it's fine. Ordinary is fine. It all counts."
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("3 days (0 hours 0 minutes)") {
    ZStack {
        Color.background.ignoresSafeArea()
        LastMomentTimerView(
            timeValue: LastMomentTimerView.formatTimeValue(totalMinutes: 4320), // 3 days exactly
            phrase: "Whatever it is, it's fine. Ordinary is fine. It all counts."
        )
    }
    .preferredColorScheme(.dark)
}
