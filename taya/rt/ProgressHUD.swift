import UIKit

/// Full-screen loading overlay with animated spinner and toast messages.
/// Provides a simple API for showing/dismissing loading states across the app.
final class ProgressHUD: UIView {

    // MARK: - Singleton

    static let shared = ProgressHUD()

    // MARK: - Layout Constants

    private enum Layout {
        static let spinnerSize: CGFloat = 80
        static let cornerRadius: CGFloat = 14
        static let overlayOpacity: CGFloat = 0.6
        static let spinnerOpacity: CGFloat = 0.9
        static let animationDuration: TimeInterval = 0.2
        static let scaleDown: CGFloat = 0.9
    }

    // MARK: - Subviews

    private lazy var spinner: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .large)
        view.color = .white
        view.bounds = CGRect(origin: .zero, size: CGSize(width: Layout.spinnerSize, height: Layout.spinnerSize))
        view.backgroundColor = .black
        view.layer.cornerRadius = Layout.cornerRadius
        view.layer.masksToBounds = true
        return view
    }()

    // MARK: - Init

    private override init(frame: CGRect) {
        super.init(frame: frame)
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundColor = UIColor(white: 0, alpha: 0)
        addSubview(spinner)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Not supported")
    }

    // MARK: - Public API

    /// Display loading spinner over the given view, or the key window if nil.
    class func show(on parentView: UIView? = nil) {
        let hud = ProgressHUD.shared
        DispatchQueue.main.async {
            let container = parentView ?? WindowHelper.keyWindow
            hud.frame = container.bounds
            hud.spinner.center = hud.center
            container.addSubview(hud)
            hud.animateIn()
        }
    }

    /// Hide and remove loading spinner.
    class func dismiss() {
        ProgressHUD.shared.animateOut()
    }

    /// Show a centered toast message that auto-dismisses.
    class func toast(_ text: String?, duration: TimeInterval = 1.0) {
        guard let text = text, !text.isEmpty else { return }
        DispatchQueue.main.async {
            let label = UILabel()
            label.backgroundColor = UIColor(white: 0, alpha: 0.8)
            label.layer.cornerRadius = 5
            label.layer.masksToBounds = true
            label.text = text
            label.font = .systemFont(ofSize: 16)
            label.textAlignment = .center
            label.numberOfLines = 0
            label.textColor = .white
            label.alpha = 0

            let window = WindowHelper.keyWindow
            window.addSubview(label)

            let maxWidth = UIScreen.main.bounds.width - 40
            let fitted = label.sizeThatFits(CGSize(width: maxWidth, height: .greatestFiniteMagnitude))
            label.bounds = CGRect(origin: .zero, size: CGSize(width: fitted.width + 30, height: fitted.height + 30))
            label.center = window.center

            UIView.animate(withDuration: 0.2) {
                label.alpha = 1
            } completion: { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    UIView.animate(withDuration: 0.2, animations: {
                        label.alpha = 0
                    }, completion: { _ in
                        label.removeFromSuperview()
                    })
                }
            }
        }
    }

    // MARK: - Animations

    private func animateIn() {
        DispatchQueue.main.async {
            self.backgroundColor = UIColor(white: 0, alpha: 0)
            self.spinner.transform = CGAffineTransform(scaleX: Layout.scaleDown, y: Layout.scaleDown)
            self.spinner.alpha = 0
            UIView.animate(withDuration: Layout.animationDuration) {
                self.backgroundColor = UIColor(white: 0, alpha: Layout.overlayOpacity)
                self.spinner.transform = .identity
                self.spinner.alpha = Layout.spinnerOpacity
                self.spinner.startAnimating()
            }
        }
    }

    private func animateOut() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: Layout.animationDuration, animations: {
                self.backgroundColor = UIColor(white: 0, alpha: 0)
                self.spinner.transform = CGAffineTransform(scaleX: Layout.scaleDown, y: Layout.scaleDown)
                self.spinner.alpha = 0
            }, completion: { _ in
                self.spinner.stopAnimating()
                self.removeFromSuperview()
            })
        }
    }
}

// MARK: - Window Helper

/// Centralized key window access, replacing scattered UIApplication.shared.windows usage.
enum WindowHelper {
    static var keyWindow: UIWindow {
        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) ?? UIApplication.shared.windows.first else {
            fatalError("No available window")
        }
        return window
    }
}
