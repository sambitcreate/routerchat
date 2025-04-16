import Foundation
import UIKit
import CoreHaptics

class HapticFeedbackManager {
    static let shared = HapticFeedbackManager()

    private var engine: CHHapticEngine?
    private var isSupported: Bool = false
    private var isEnabled: Bool = true

    // Cache generators to improve performance
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)

    private init() {
        // Prepare generators in advance
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()

        // Initialize haptic engine lazily to avoid startup delays
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.checkHapticSupport()
        }
    }

    private func checkHapticSupport() {
        isSupported = CHHapticEngine.capabilitiesForHardware().supportsHaptics
        if isSupported {
            do {
                engine = try CHHapticEngine()
                try engine?.start()

                // The engine stops when the app goes to the background, so restart it when the app becomes active
                engine?.resetHandler = { [weak self] in
                    guard let self = self else { return }
                    do {
                        try self.engine?.start()
                    } catch {
                        print("Failed to restart haptic engine: \(error.localizedDescription)")
                    }
                }

                // Stop the engine when the app goes to the background
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(appDidEnterBackground),
                    name: UIApplication.didEnterBackgroundNotification,
                    object: nil
                )

                // Restart the engine when the app becomes active
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(appWillEnterForeground),
                    name: UIApplication.willEnterForegroundNotification,
                    object: nil
                )
            } catch {
                print("Failed to create haptic engine: \(error.localizedDescription)")
                isSupported = false
            }
        }
    }

    @objc private func appDidEnterBackground() {
        // No need for try-catch as stop() doesn't throw in recent iOS versions
        engine?.stop()
    }

    @objc private func appWillEnterForeground() {
        // No need for try-catch as start() doesn't throw in recent iOS versions
        do {
            // Only try to start if engine exists
            if let engine = engine {
                try engine.start()
            }
        } catch {
            print("Failed to restart haptic engine: \(error.localizedDescription)")
        }
    }

    // MARK: - Public Methods

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }

    func playFeedback(for feedbackType: FeedbackType) {
        guard isEnabled else { return }

        switch feedbackType {
        case .success:
            playSuccessFeedback()
        case .error:
            playErrorFeedback()
        case .selection:
            playSelectionFeedback()
        case .light:
            playLightFeedback()
        case .medium:
            playMediumFeedback()
        case .heavy:
            playHeavyFeedback()
        }
    }

    // MARK: - Private Feedback Methods

    private func playSuccessFeedback() {
        if isSupported, let engine = engine {
            do {
                let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7)
                let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)

                let event = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [intensity, sharpness],
                    relativeTime: 0
                )

                let pattern = try CHHapticPattern(events: [event], parameters: [])
                let player = try engine.makePlayer(with: pattern)
                try player.start(atTime: 0)
            } catch {
                print("Failed to play success haptic feedback: \(error.localizedDescription)")
                fallbackToUIFeedback(style: .medium)
            }
        } else {
            fallbackToUIFeedback(style: .medium)
        }
    }

    private func playErrorFeedback() {
        if isSupported, let engine = engine {
            do {
                let intensity1 = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
                let sharpness1 = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)

                let intensity2 = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
                let sharpness2 = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)

                let event1 = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [intensity1, sharpness1],
                    relativeTime: 0
                )

                let event2 = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [intensity2, sharpness2],
                    relativeTime: 0.2
                )

                let pattern = try CHHapticPattern(events: [event1, event2], parameters: [])
                let player = try engine.makePlayer(with: pattern)
                try player.start(atTime: 0)
            } catch {
                print("Failed to play error haptic feedback: \(error.localizedDescription)")
                fallbackToUIFeedback(style: .heavy)
            }
        } else {
            fallbackToUIFeedback(style: .heavy)
        }
    }

    private func playSelectionFeedback() {
        if isSupported, let engine = engine {
            do {
                let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5)
                let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)

                let event = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [intensity, sharpness],
                    relativeTime: 0
                )

                let pattern = try CHHapticPattern(events: [event], parameters: [])
                let player = try engine.makePlayer(with: pattern)
                try player.start(atTime: 0)
            } catch {
                print("Failed to play selection haptic feedback: \(error.localizedDescription)")
                fallbackToUIFeedback(style: .light)
            }
        } else {
            fallbackToUIFeedback(style: .light)
        }
    }

    private func playLightFeedback() {
        fallbackToUIFeedback(style: .light)
    }

    private func playMediumFeedback() {
        fallbackToUIFeedback(style: .medium)
    }

    private func playHeavyFeedback() {
        fallbackToUIFeedback(style: .heavy)
    }

    private func fallbackToUIFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Use cached generators instead of creating new ones each time
            switch style {
            case .light:
                self.lightGenerator.impactOccurred()
            case .medium:
                self.mediumGenerator.impactOccurred()
            case .heavy:
                self.heavyGenerator.impactOccurred()
            case .soft, .rigid:
                // Handle newer feedback styles
                let generator = UIImpactFeedbackGenerator(style: style)
                generator.prepare()
                generator.impactOccurred()
            @unknown default:
                // Handle any future feedback styles
                let generator = UIImpactFeedbackGenerator(style: style)
                generator.prepare()
                generator.impactOccurred()
            }
        }
    }
}

enum FeedbackType {
    case success
    case error
    case selection
    case light
    case medium
    case heavy
}
