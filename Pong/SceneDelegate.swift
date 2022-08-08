import UIKit

/// This class handles the states of the "scenes" of the application display
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    /// In this function we could customize the main application display window
    /// If you decided to layout the UI in the code instead of the Storyboard
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let _ = (scene as? UIWindowScene) else { return }
    }
}

