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

        if days > 0 {
            return "\(days) day\(days != 1 ? "s" : "") \(hours) hour\(hours != 1 ? "s" : "") \(minutes) minute\(minutes != 1 ? "s" : "")"
        } else if hours > 0 {
            return "\(hours) hour\(hours != 1 ? "s" : "") \(minutes) minute\(minutes != 1 ? "s" : "")"
        } else {
            return "\(minutes) minute\(minutes != 1 ? "s" : "")"
        }
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

#Preview("1 day 15h 55m") {
    ZStack {
        Color.background.ignoresSafeArea()
        LastMomentTimerView(
            timeValue: LastMomentTimerView.formatTimeValue(totalMinutes: 2395),
            phrase: "It doesn't have to be big. Whatever moment works."
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("12 days 22h 15m") {
    ZStack {
        Color.background.ignoresSafeArea()
        LastMomentTimerView(
            timeValue: LastMomentTimerView.formatTimeValue(totalMinutes: 18615),
            phrase: "Whatever it is, it's fine. Ordinary is fine. It all counts."
        )
    }
    .preferredColorScheme(.dark)
}
