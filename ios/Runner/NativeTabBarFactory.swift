import Flutter
import UIKit

class NativeTabBarFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        NativeTabBarPlatformView(frame: frame, viewId: viewId, messenger: messenger, args: args)
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        FlutterStandardMessageCodec.sharedInstance()
    }
}

final class NativeTabBarPlatformView: NSObject, FlutterPlatformView, UITabBarDelegate {
    private let container = UIView()
    private let tabBar = UITabBar()
    private let channel: FlutterMethodChannel

    init(frame: CGRect, viewId: Int64, messenger: FlutterBinaryMessenger, args: Any?) {
        channel = FlutterMethodChannel(name: "trading_app/native-tab-bar_\(viewId)", binaryMessenger: messenger)
        super.init()

        container.frame = frame
        tabBar.delegate = self
        
        let homeItem = UITabBarItem(
            title: "Home",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )
        homeItem.tag = 0

        let watchlistItem = UITabBarItem(
            title: "Watchlist",
            image: UIImage(systemName: "star"),
            selectedImage: UIImage(systemName: "star.fill")
        )
        watchlistItem.tag = 1

        let portfolioItem = UITabBarItem(
            title: "Portfolio",
            image: UIImage(systemName: "briefcase"),
            selectedImage: UIImage(systemName: "briefcase.fill")
        )
        portfolioItem.tag = 2

        let settingsItem = UITabBarItem(
            title: "Settings",
            image: UIImage(systemName: "gearshape"),
            selectedImage: UIImage(systemName: "gearshape.fill")
        )
        settingsItem.tag = 3

        tabBar.items = [homeItem, watchlistItem, portfolioItem, settingsItem]
        tabBar.frame = container.bounds
        tabBar.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // Native iOS Apple translucent material / appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }

        container.addSubview(tabBar)

        let dict = args as? [String: Any]
        if let initial = dict?["selectedIndex"] as? Int,
           let items = tabBar.items, initial >= 0 && initial < items.count {
            tabBar.selectedItem = items[initial]
        }

        channel.setMethodCallHandler { [weak self] call, result in
            if call.method == "setTab", let idx = (call.arguments as? [String: Any])?["index"] as? Int {
                if let items = self?.tabBar.items, idx >= 0 && idx < items.count {
                    self?.tabBar.selectedItem = items[idx]
                }
                result(nil)
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
    }

    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        channel.invokeMethod("onTabSelected", arguments: ["index": item.tag])
    }

    func view() -> UIView {
        container
    }
}
