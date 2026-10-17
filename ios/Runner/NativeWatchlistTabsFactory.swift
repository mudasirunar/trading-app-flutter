import Flutter
import UIKit

/// Subclass that reports touch tracking / dragging state for NativeWatchlistTabs
final class TrackingWatchlistSegmentedControl: UISegmentedControl {
    var onTrackingChanged: ((Bool) -> Void)?

    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let result = super.beginTracking(touch, with: event)
        if result {
            onTrackingChanged?(true)
        }
        return result
    }

    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let result = super.continueTracking(touch, with: event)
        if result {
            onTrackingChanged?(true)
        }
        return result
    }

    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        super.endTracking(touch, with: event)
        onTrackingChanged?(false)
    }

    override func cancelTracking(with event: UIEvent?) {
        super.cancelTracking(with: event)
        onTrackingChanged?(false)
    }
}

/// Factory that Flutter calls to instantiate the native iOS Watchlist top tabs segmented control
class NativeWatchlistTabsFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        NativeWatchlistTabsPlatformView(frame: frame, viewId: viewId, messenger: messenger, args: args)
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        FlutterStandardMessageCodec.sharedInstance()
    }
}

/// 100% Native iOS UISegmentedControl Platform View for Watchlist Screen:
/// Segment 0: "My Watchlists" (SF Symbol: star.fill)
/// Segment 1: "All Markets" (SF Symbol: globe)
final class NativeWatchlistTabsPlatformView: NSObject, FlutterPlatformView {
    private let container = UIView()
    private let segmentedControl = TrackingWatchlistSegmentedControl()
    private let channel: FlutterMethodChannel
    private var isDarkMode: Bool = false
    private var isPillRaised: Bool = false

    private struct TabSpec {
        let title: String
        let iconName: String
        let color: UIColor
    }

    private let tabs: [TabSpec] = [
        TabSpec(
            title: "My Watchlists",
            iconName: "star.fill",
            color: UIColor(red: 47.0 / 255.0, green: 104.0 / 255.0, blue: 246.0 / 255.0, alpha: 1.0)
        ),
        TabSpec(
            title: "All Markets",
            iconName: "globe",
            color: UIColor(red: 47.0 / 255.0, green: 104.0 / 255.0, blue: 246.0 / 255.0, alpha: 1.0)
        )
    ]

    init(frame: CGRect, viewId: Int64, messenger: FlutterBinaryMessenger, args: Any?) {
        channel = FlutterMethodChannel(name: "trading_app/native-watchlist-tabs_\(viewId)", binaryMessenger: messenger)
        super.init()

        container.frame = frame
        container.backgroundColor = .clear

        let dict = args as? [String: Any]
        let initial = dict?["selectedIndex"] as? Int ?? 0
        if let darkParam = dict?["isDark"] as? Bool {
            isDarkMode = darkParam
        } else {
            isDarkMode = container.traitCollection.userInterfaceStyle == .dark
        }

        for i in 0..<tabs.count {
            segmentedControl.insertSegment(with: UIImage(), at: i, animated: false)
        }

        segmentedControl.frame = container.bounds
        segmentedControl.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        segmentedControl.selectedSegmentIndex = max(0, min(tabs.count - 1, initial))

        applyThemeStyle()
        updateSelectedColor(for: segmentedControl.selectedSegmentIndex)
        updateSegmentImages()

        segmentedControl.onTrackingChanged = { [weak self] isTracking in
            self?.handleTrackingChanged(isTracking)
        }
        segmentedControl.addTarget(self, action: #selector(touchDown(_:)), for: .touchDown)
        segmentedControl.addTarget(self, action: #selector(touchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        container.addSubview(segmentedControl)

        channel.setMethodCallHandler { [weak self] call, result in
            guard let self = self else { return }
            if call.method == "setTab", let idx = (call.arguments as? [String: Any])?["index"] as? Int {
                if idx >= 0 && idx < self.tabs.count {
                    self.segmentedControl.selectedSegmentIndex = idx
                    self.updateSelectedColor(for: idx)
                    self.isPillRaised = false
                    self.updateSegmentImages()
                }
                result(nil)
            } else if call.method == "setTheme", let dark = (call.arguments as? [String: Any])?["isDark"] as? Bool {
                self.isDarkMode = dark
                self.applyThemeStyle()
                self.updateSelectedColor(for: self.segmentedControl.selectedSegmentIndex)
                self.updateSegmentImages()
                result(nil)
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func handleTrackingChanged(_ isTracking: Bool) {
        guard !isDarkMode else { return }
        if isPillRaised != isTracking {
            isPillRaised = isTracking
            updateSegmentImages()
        }
    }

    @objc private func touchDown(_ sender: UISegmentedControl) {
        handleTrackingChanged(true)
    }

    @objc private func touchUp(_ sender: UISegmentedControl) {
        handleTrackingChanged(false)
    }

    private func applyThemeStyle() {
        if #available(iOS 13.0, *) {
            container.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
            segmentedControl.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
        }
    }

    private func updateSelectedColor(for index: Int) {
        if index >= 0 && index < tabs.count {
            segmentedControl.selectedSegmentTintColor = tabs[index].color
        }
    }

    private func updateSegmentImages() {
        let blackColor = UIColor(red: 15.0 / 255.0, green: 23.0 / 255.0, blue: 42.0 / 255.0, alpha: 1.0)
        let unselectedColor = isDarkMode
            ? UIColor(red: 226.0 / 255.0, green: 232.0 / 255.0, blue: 240.0 / 255.0, alpha: 0.95)
            : blackColor

        for i in 0..<tabs.count {
            let color: UIColor
            if isDarkMode {
                let isSelected = (i == segmentedControl.selectedSegmentIndex)
                color = isSelected ? UIColor.white : unselectedColor
            } else {
                // Light mode:
                // When pill is raised (dragged/held): ALL tabs turn black (both icon and text).
                // Only once placed / put at rest does the active tab turn white!
                if isPillRaised {
                    color = blackColor
                } else {
                    let isSelected = (i == segmentedControl.selectedSegmentIndex)
                    color = isSelected ? UIColor.white : blackColor
                }
            }

            let img = createSegmentImage(
                iconName: tabs[i].iconName,
                title: tabs[i].title,
                foregroundColor: color
            )
            segmentedControl.setImage(img, forSegmentAt: i)
        }
    }

    private func createSegmentImage(
        iconName: String,
        title: String,
        foregroundColor: UIColor,
        font: UIFont = UIFont.systemFont(ofSize: 12, weight: .bold)
    ) -> UIImage {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: foregroundColor
        ]
        let textSize = (title as NSString).size(withAttributes: attributes)
        let iconSize = CGSize(width: 14, height: 14)
        let spacing: CGFloat = 6.0
        let totalWidth = ceil(iconSize.width + spacing + textSize.width)
        let totalHeight = ceil(max(iconSize.height, textSize.height))

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: totalWidth, height: totalHeight))
        let image = renderer.image { _ in
            let iconRect = CGRect(
                x: 0,
                y: (totalHeight - iconSize.height) / 2,
                width: iconSize.width,
                height: iconSize.height
            )

            let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)
            let icon = UIImage(systemName: iconName, withConfiguration: config)?.withTintColor(foregroundColor, renderingMode: .alwaysOriginal)
            icon?.draw(in: iconRect)

            let textRect = CGRect(
                x: iconSize.width + spacing,
                y: (totalHeight - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            (title as NSString).draw(in: textRect, withAttributes: attributes)
        }
        return image.withRenderingMode(.alwaysOriginal)
    }

    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        let index = sender.selectedSegmentIndex
        updateSelectedColor(for: index)
        if !sender.isTracking {
            isPillRaised = false
        }
        updateSegmentImages()
        channel.invokeMethod("onTabSelected", arguments: ["index": index])
    }

    func view() -> UIView {
        container
    }
}
