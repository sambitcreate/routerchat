import UIKit
import SwiftUI

// MARK: - UIImpactFeedbackGenerator Extensions
extension UIImpactFeedbackGenerator {
    /// Disables haptic feedback during keyboard operations to prevent delays
    static func disableHapticsDuringKeyboardOperations() {
        // Register for keyboard notifications
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { _ in
            // Temporarily disable haptic feedback when keyboard is about to show
            HapticFeedbackManager.shared.setEnabled(false)
        }

        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardDidHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            // Re-enable haptic feedback when keyboard is hidden
            HapticFeedbackManager.shared.setEnabled(true)
        }
    }
}

// MARK: - UIApplication Extensions
extension UIApplication {
    /// Optimizes keyboard performance by adjusting system settings
    static func optimizeKeyboardPerformance() {
        // Increase the gesture system gate timeout to prevent the error
        // Use a safer approach with UserDefaults directly
        UserDefaults.standard.set(5.0, forKey: "UIGestureEnvironmentSystemGateTimeout")

        // Register for keyboard notifications to optimize animations
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { _ in
            // Temporarily disable animations when keyboard is about to show
            UIView.setAnimationsEnabled(false)
        }

        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardDidShowNotification,
            object: nil,
            queue: .main
        ) { _ in
            // Re-enable animations after keyboard is shown
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                UIView.setAnimationsEnabled(true)
            }
        }
    }
}

// MARK: - View Extensions for Keyboard Handling
extension View {
    /// Dismisses the keyboard when tapping outside of a text field
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}
