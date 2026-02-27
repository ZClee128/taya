import UIKit

/// Displays the launch image during app initialization.
/// Shown as the initial root view controller while remote config loads.
final class LaunchViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let imageView = UIImageView(frame: UIScreen.main.bounds)
        imageView.image = UIImage(named: "LaunchImage")
        imageView.contentMode = .scaleAspectFill
        view.addSubview(imageView)
    }
}

// MARK: - Legacy Alias

typealias SplashScreenController = LaunchViewController
