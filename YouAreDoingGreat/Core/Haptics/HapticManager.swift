//
//  HapticManager.swift
//  YouAreDoingGreat
//
//  Centralized haptic feedback management with CHHapticEngine support.
//  Provides sophisticated vibration patterns synchronized with animations.
//

import Foundation
import CoreHaptics
import UIKit
import OSLog

private let logger = Logger(subsystem: "ee.required.you-are-doing-great", category: "haptics")

// MARK: - Haptic Manager

@MainActor
@Observable
final class HapticManager {
    static let shared = HapticManager()

    // MARK: - Properties

    /// User preference for haptic feedback (persisted to UserDefaults and cloud)
    private(set) var isEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: enabledKey)
        }
    }

    /// Haptic intensity multiplier (0.5-1.0 range, persisted to UserDefaults)
    private(set) var intensity: Float = 0.75 {
        didSet {
            UserDefaults.standard.set(intensity, forKey: intensityKey)
        }
    }

    private var engine: CHHapticEngine?
    private var supportsHaptics: Bool = false
    private var lastHapticTime: Date = .distantPast
    private let minimumInterval: TimeInterval = 0.1 // 100ms rate limiting

    // Fallback for unsupported devices
    private let lightFeedback = UIImpactFeedbackGenerator(style: .light)
    private let mediumFeedback = UIImpactFeedbackGenerator(style: .medium)

    // UserDefaults keys
    private let enabledKey = "com.youaredoinggreat.haptics.enabled"
    private let intensityKey = "com.youaredoinggreat.haptics.intensity"

    // MARK: - Initialization

    private init() {
        loadPreferences()
        supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
        logger.info("🎯 HapticManager initialized (supportsHaptics: \(self.supportsHaptics))")
    }

    // MARK: - Public Methods

    /// Start and warm up the haptic engine
    func start() async throws {
        guard supportsHaptics else {
            logger.info("⚠️ Device does not support haptics, using fallback")
            return
        }

        guard isEnabled else {
            logger.info("ℹ️ Haptics disabled by user")
            return
        }

        do {
            // Clean up existing engine if present
            if engine != nil {
                try? await engine?.stop()
                engine = nil
            }

            engine = try CHHapticEngine()

            // Set up handlers
            engine?.stoppedHandler = { [weak self] reason in
                Task { @MainActor [weak self] in
                    logger.warning("⚠️ Haptic engine stopped: \(reason.rawValue)")
                    self?.handleEngineStopped()
                }
            }

            engine?.resetHandler = { [weak self] in
                Task { @MainActor [weak self] in
                    logger.info("🔄 Haptic engine reset")
                    try? await self?.restartEngine()
                }
            }

            try await engine?.start()
            logger.info("✅ Haptic engine started successfully")

        } catch {
            logger.error("❌ Failed to start haptic engine: \(error.localizedDescription)")
            throw error
        }
    }

    /// Stop the haptic engine
    func stop() async {
        do {
            try await engine?.stop()
            logger.info("🛑 Haptic engine stopped")
        } catch {
            logger.error("❌ Failed to stop haptic engine: \(error.localizedDescription)")
        }
    }

    /// Play a haptic pattern
    func play(_ pattern: HapticPattern) async {
        // Check if haptics are enabled
        guard isEnabled else { return }

        // Check if device is in Low Power Mode
        guard !ProcessInfo.processInfo.isLowPowerModeEnabled else {
            logger.debug("⚡️ Low Power Mode enabled, skipping haptic")
            return
        }

        // Rate limiting: prevent haptics faster than 100ms
        let now = Date()
        guard now.timeIntervalSince(lastHapticTime) >= minimumInterval else {
            logger.debug("⏱️ Haptic rate limited (too frequent)")
            return
        }
        lastHapticTime = now

        // Play haptic based on device capabilities
        if supportsHaptics, engine != nil {
            await playCHHaptic(pattern)
        } else {
            playFallbackHaptic(pattern)
        }
    }

    /// Update haptic enabled preference
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        logger.info("⚙️ Haptics \(enabled ? "enabled" : "disabled")")

        if enabled {
            // Restart engine when re-enabling
            Task {
                try? await start()
            }
        } else {
            // Stop engine when disabling
            Task { await stop() }
        }
    }

    /// Update haptic intensity
    func setIntensity(_ intensity: Float) {
        self.intensity = max(0.5, min(1.0, intensity)) // Clamp to 0.5-1.0 range
        logger.info("⚙️ Haptic intensity set to \(Int(self.intensity * 100))%")
    }

    // MARK: - Private Methods

    /// Load preferences from UserDefaults
    private func loadPreferences() {
        if let storedEnabled = UserDefaults.standard.object(forKey: enabledKey) as? Bool {
            isEnabled = storedEnabled
        }

        if let storedIntensity = UserDefaults.standard.object(forKey: intensityKey) as? Float {
            intensity = storedIntensity
        }

        logger.info("📥 Loaded preferences (enabled: \(self.isEnabled), intensity: \(Int(self.intensity * 100))%)")
    }

    /// Play haptic using CHHapticEngine
    private func playCHHaptic(_ pattern: HapticPattern) async {
        do {
            guard let engine = engine else {
                // Engine not initialized, try to start it
                logger.warning("⚠️ Engine not initialized, attempting to start")
                try? await start()
                guard let engine = engine else {
                    playFallbackHaptic(pattern)
                    return
                }
                // Continue with newly started engine
                let hapticPattern = try createHapticPattern(for: pattern)
                let player = try engine.makePlayer(with: hapticPattern)
                try player.start(atTime: CHHapticTimeImmediate)
                return
            }

            let hapticPattern = try createHapticPattern(for: pattern)
            let player = try engine.makePlayer(with: hapticPattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch let error as NSError {
            logger.error("❌ Failed to play CHHaptic pattern \(String(describing: pattern)): \(error.localizedDescription) (code: \(error.code))")

            // Error -4805 is CHHapticErrorCodeServerInterrupted - engine stopped
            if error.code == -4805 {
                logger.warning("🔄 Engine interrupted (error -4805), attempting restart")
                Task {
                    try? await restartEngine()
                }
            }

            // Fallback to UIImpactFeedbackGenerator
            playFallbackHaptic(pattern)
        } catch {
            logger.error("❌ Failed to play CHHaptic pattern \(String(describing: pattern)): \(error.localizedDescription)")
            playFallbackHaptic(pattern)
        }
    }

    /// Play haptic using UIImpactFeedbackGenerator (fallback)
    private func playFallbackHaptic(_ pattern: HapticPattern) {
        switch pattern {
        case .gentleTap:
            lightFeedback.impactOccurred(intensity: CGFloat(intensity))

        case .confidentPress:
            // Longer press: medium impact + delayed light tap
            mediumFeedback.impactOccurred(intensity: CGFloat(intensity * 0.9))
            Task {
                try? await Task.sleep(nanoseconds: 150_000_000) // 150ms
                self.lightFeedback.impactOccurred(intensity: CGFloat(self.intensity * 0.5))
            }

        case .softPulse:
            // Approximate with light impact
            lightFeedback.impactOccurred(intensity: CGFloat(intensity * 0.8))

        case .warmArrival:
            // Beautiful multi-tap sequence: gentle → warm → sparkle
            lightFeedback.impactOccurred(intensity: CGFloat(intensity * 0.6))
            Task {
                try? await Task.sleep(nanoseconds: 200_000_000) // 200ms - warm presence
                self.mediumFeedback.impactOccurred(intensity: CGFloat(self.intensity * 0.65))
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms - sparkle
                self.lightFeedback.impactOccurred(intensity: CGFloat(self.intensity * 0.5))
            }

        case .celebrationBurst:
            // Triple tap sequence
            lightFeedback.impactOccurred(intensity: CGFloat(intensity))
            Task {
                try? await Task.sleep(nanoseconds: 80_000_000) // 80ms
                self.lightFeedback.impactOccurred(intensity: CGFloat(self.intensity))
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
                self.lightFeedback.impactOccurred(intensity: CGFloat(self.intensity))
            }

        case .gentleHeartbeat:
            // Single light pulse (reserved for v2 repeating implementation)
            lightFeedback.impactOccurred(intensity: CGFloat(intensity * 0.6))
        }
    }

    /// Create CHHapticPattern for a given pattern type
    private func createHapticPattern(for pattern: HapticPattern) throws -> CHHapticPattern {
        switch pattern {
        case .gentleTap:
            return try createGentleTapPattern()

        case .confidentPress:
            return try createConfidentPressPattern()

        case .softPulse:
            return try createSoftPulsePattern()

        case .warmArrival:
            return try createWarmArrivalPattern()

        case .celebrationBurst:
            return try createCelebrationBurstPattern()

        case .gentleHeartbeat:
            return try createGentleHeartbeatPattern()
        }
    }

    // MARK: - Haptic Pattern Definitions

    /// Gentle tap: Light impact for buttons and taps
    private func createGentleTapPattern() throws -> CHHapticPattern {
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4 * intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
            ],
            relativeTime: 0
        )

        return try CHHapticPattern(events: [event], parameters: [])
    }

    /// Confident press: Satisfying 400ms pattern for moment submission
    /// Initial strong tap + sustained rumble that gradually fades
    private func createConfidentPressPattern() throws -> CHHapticPattern {
        let events = [
            // Initial strong tap (0ms)
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9 * intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                ],
                relativeTime: 0
            ),
            // Sustained rumble: strong start (0-150ms)
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6 * intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                ],
                relativeTime: 0.02,
                duration: 0.15
            ),
            // Gentle fade (150-300ms)
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3 * intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ],
                relativeTime: 0.17,
                duration: 0.13
            ),
            // Final soft tail (300-400ms)
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                ],
                relativeTime: 0.30,
                duration: 0.10
            )
        ]

        return try CHHapticPattern(events: events, parameters: [])
    }

    /// Soft pulse: 200ms breathing pattern for offline praise
    private func createSoftPulsePattern() throws -> CHHapticPattern {
        let events = [
            // Fade in: 0→0.5 (0-100ms)
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                ],
                relativeTime: 0,
                duration: 0.1
            ),
            // Sustain: 0.5 (100-150ms)
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5 * intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                ],
                relativeTime: 0.1,
                duration: 0.05
            ),
            // Fade out: 0.5→0 (150-200ms)
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                ],
                relativeTime: 0.15,
                duration: 0.05
            )
        ]

        return try CHHapticPattern(events: events, parameters: [])
    }

    /// Warm Arrival: Beautiful 500ms pattern for AI praise (signature pattern)
    /// Gentle swell → warm embrace → sparkle finish
    /// Synchronized with AI praise animation to feel like emotional encouragement
    private func createWarmArrivalPattern() throws -> CHHapticPattern {
        let events = [
            // Gentle swell: 0→0.4 (0-120ms) - soft awakening
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                ],
                relativeTime: 0,
                duration: 0.12
            ),
            // Warm embrace: 0.4→0.65 (120-200ms) - comforting presence
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4 * intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.25)
                ],
                relativeTime: 0.12,
                duration: 0.08
            ),
            // Peak glow: 0.65 sustained (200-320ms) - fullness of support
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.65 * intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ],
                relativeTime: 0.20,
                duration: 0.12
            ),
            // Gentle sparkle tap (280ms) - moment of recognition
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5 * intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                ],
                relativeTime: 0.28
            ),
            // Graceful fade: 0.65→0.3 (320-420ms) - lingering warmth
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3 * intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.25)
                ],
                relativeTime: 0.32,
                duration: 0.10
            ),
            // Soft trail: 0.3→0 (420-500ms) - gentle release
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                ],
                relativeTime: 0.42,
                duration: 0.08
            )
        ]

        return try CHHapticPattern(events: events, parameters: [])
    }

    /// Celebration burst: Triple-tap sequence (reserved for v2)
    private func createCelebrationBurstPattern() throws -> CHHapticPattern {
        let events = [
            // First tap (0ms)
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6 * intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                ],
                relativeTime: 0
            ),
            // Second tap (80ms)
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7 * intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                ],
                relativeTime: 0.08
            ),
            // Third tap (180ms)
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8 * intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                ],
                relativeTime: 0.18
            )
        ]

        return try CHHapticPattern(events: events, parameters: [])
    }

    /// Gentle heartbeat: Repeating pulse (reserved for v2)
    private func createGentleHeartbeatPattern() throws -> CHHapticPattern {
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3 * intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
            ],
            relativeTime: 0
        )

        return try CHHapticPattern(events: [event], parameters: [])
    }

    // MARK: - Engine Lifecycle

    private func handleEngineStopped() {
        logger.warning("⚠️ Handling engine stopped event")

        // Attempt to restart
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 500ms delay
            try? await restartEngine()
        }
    }

    private func restartEngine() async throws {
        guard isEnabled else { return }

        logger.info("🔄 Restarting haptic engine")
        try? await engine?.stop()
        try await start()
    }
}
