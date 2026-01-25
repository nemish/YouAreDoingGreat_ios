//
//  HapticPattern.swift
//  YouAreDoingGreat
//
//  Defines haptic feedback patterns for different interactions throughout the app.
//

import Foundation

/// Enum defining all haptic feedback patterns used in the app
enum HapticPattern {
    /// Light impact for buttons, taps, and subtle interactions
    case gentleTap

    /// Satisfying 400ms pattern for moment submission: strong tap → sustained rumble → gentle fade
    case confidentPress

    /// 200ms breathing pattern for offline praise appearance
    case softPulse

    /// Beautiful 500ms pattern for AI praise (signature): gentle swell → warm embrace → sparkle → graceful fade
    case warmArrival

    /// Triple-tap sequence (0ms/80ms/180ms) for favorites (reserved for v2)
    case celebrationBurst

    /// Repeating gentle pulse during loading states (reserved for v2)
    case gentleHeartbeat
}
