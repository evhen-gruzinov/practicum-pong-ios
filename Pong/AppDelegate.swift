import UIKit
import AVFoundation

/// This is the main state processing class of the application
///
/// It configures the application at startup and tracks the transition between different states
///
@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    /// This method is called once as soon as the application is started
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        configureAudioSession()
        return true
    }

    // MARK: - UISceneSession Lifecycle

    /// This method defines the settings of the main "scene" of the application display
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        return UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: connectingSceneSession.role
        )
    }

    // MARK: - AVAudioSession

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .ambient,
                mode: .default,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Error setting up and activating AVAudioSession: \(error)")
        }
    }
}

