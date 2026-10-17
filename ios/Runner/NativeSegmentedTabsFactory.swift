import Flutter
import UIKit

/// Subclass that reports touch tracking / dragging state for NativeSegmentedTabs
final class TrackingSegmentedTabsControl: UISegmentedControl {
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

/// Factory that Flutter calls to instantiate the native iOS reusable segmented tabs control
class NativeSegmentedTabsFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        NativeSegmentedTabsPlatformView(frame: frame, viewId: viewId, messenger: messenger, args: args)
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        FlutterStandardMessageCodec.sharedInstance()
    }
}

/// Backward compatibility alias
typealias NativeWatchlistTabsFactory = NativeSegmentedTabsFactory

/// 100% Native iOS UISegmentedControl Reusable Platform View:
/// - Fully customizable: optional icons, per-tab active pill tint color, per-tab text colors, and per-tab icon colors
/// - Passed from Flutter via PlatformSegmentedTabsControl (used by Watchlists, Alerts, and any other screen)
final class NativeSegmentedTabsPlatformView: NSObject, FlutterPlatformView {
    private let container = UIView()
    private let segmentedControl = TrackingSegmentedTabsControl()
    private let channel: FlutterMethodChannel
    private var isDarkMode: Bool = false
    private var isPillRaised: Bool = false

    private struct TabSpec {
        let title: String
        let iconName: String
        let pillColor: UIColor
        let activeTextColor: UIColor?
        let inactiveTextColor: UIColor?
        let activeIconColor: UIColor?
        let inactiveIconColor: UIColor?
    }

    private var tabs: [TabSpec] = []

    private static func parseColor(_ val: Any?, fallback: UIColor? = nil) -> UIColor? {
        if let num = val as? Int64 {
            let a = CGFloat((num >> 24) & 0xFF) / 255.0
            let r = CGFloat((num >> 16) & 0xFF) / 255.0
            let g = CGFloat((num >> 8) & 0xFF) / 255.0
            let b = CGFloat(num & 0xFF) / 255.0
            return UIColor(red: r, green: g, blue: b, alpha: a == 0 ? 1.0 : a)
        } else if let num = val as? Int {
            let a = CGFloat((num >> 24) & 0xFF) / 255.0
            let r = CGFloat((num >> 16) & 0xFF) / 255.0
            let g = CGFloat((num >> 8) & 0xFF) / 255.0
            let b = CGFloat(num & 0xFF) / 255.0
            return UIColor(red: r, green: g, blue: b, alpha: a == 0 ? 1.0 : a)
        }
        return fallback
    }

    private static func parseTabs(_ customTabs: [[String: Any]]) -> [TabSpec] {
        var loadedTabs: [TabSpec] = []
        let defaultBlue = UIColor(red: 47.0 / 255.0, green: 104.0 / 255.0, blue: 246.0 / 255.0, alpha: 1.0)
        for t in customTabs {
            let title = t["title"] as? String ?? ""
            let iconName = t["icon"] as? String ?? ""
            let pillColor = parseColor(t["pillColor"], fallback: defaultBlue)!
            let activeText = parseColor(t["activeTextColor"])
            let inactiveText = parseColor(t["inactiveTextColor"])
            let activeIcon = parseColor(t["activeIconColor"])
            let inactiveIcon = parseColor(t["inactiveIconColor"])

            loadedTabs.append(TabSpec(
                title: title,
                iconName: iconName,
                pillColor: pillColor,
                activeTextColor: activeText,
                inactiveTextColor: inactiveText,
                activeIconColor: activeIcon,
                inactiveIconColor: inactiveIcon
            ))
        }
        return loadedTabs
    }

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

        if let customTabs = dict?["tabs"] as? [[String: Any]], !customTabs.isEmpty {
            tabs = Self.parseTabs(customTabs)
        } else {
            // Generic 2-tab fallback without any hardcoded screen-specific titles or icons
            let defaultBlue = UIColor(red: 47.0 / 255.0, green: 104.0 / 255.0, blue: 246.0 / 255.0, alpha: 1.0)
            tabs = [
                TabSpec(title: "Tab 1", iconName: "", pillColor: defaultBlue, activeTextColor: nil, inactiveTextColor: nil, activeIconColor: nil, inactiveIconColor: nil),
                TabSpec(title: "Tab 2", iconName: "", pillColor: defaultBlue, activeTextColor: nil, inactiveTextColor: nil, activeIconColor: nil, inactiveIconColor: nil)
            ]
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
            } else if call.method == "updateTabs", let newTabs = (call.arguments as? [String: Any])?["tabs"] as? [[String: Any]] {
                let loadedTabs = Self.parseTabs(newTabs)
                if loadedTabs.count == self.tabs.count {
                    self.tabs = loadedTabs
                    self.updateSelectedColor(for: self.segmentedControl.selectedSegmentIndex)
                    self.updateSegmentImages()
                } else if !loadedTabs.isEmpty {
                    self.segmentedControl.removeAllSegments()
                    self.tabs = loadedTabs
                    for i in 0..<self.tabs.count {
                        self.segmentedControl.insertSegment(with: UIImage(), at: i, animated: false)
                    }
                    self.segmentedControl.selectedSegmentIndex = min(self.segmentedControl.selectedSegmentIndex, self.tabs.count - 1)
                    self.updateSelectedColor(for: self.segmentedControl.selectedSegmentIndex)
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
            segmentedControl.selectedSegmentTintColor = tabs[index].pillColor
        }
    }

    private func updateSegmentImages() {
        let blackColor = UIColor(red: 15.0 / 255.0, green: 23.0 / 255.0, blue: 42.0 / 255.0, alpha: 1.0)
        let unselectedDefault = isDarkMode
            ? UIColor(red: 226.0 / 255.0, green: 232.0 / 255.0, blue: 240.0 / 255.0, alpha: 0.95)
            : blackColor

        for i in 0..<tabs.count {
            let tab = tabs[i]
            let isSelected = (i == segmentedControl.selectedSegmentIndex)
            let textColor: UIColor
            let iconColor: UIColor

            if isDarkMode {
                textColor = isSelected
                    ? (tab.activeTextColor ?? UIColor.white)
                    : (tab.inactiveTextColor ?? unselectedDefault)
                iconColor = isSelected
                    ? (tab.activeIconColor ?? textColor)
                    : (tab.inactiveIconColor ?? unselectedDefault)
            } else {
                // Light mode:
                // When pill is raised (dragged/held): ALL tabs turn to their inactive/black color.
                // Only once placed / put at rest does the active tab adopt active color!
                if isPillRaised {
                    textColor = tab.inactiveTextColor ?? blackColor
                    iconColor = tab.inactiveIconColor ?? textColor
                } else {
                    textColor = isSelected
                        ? (tab.activeTextColor ?? UIColor.white)
                        : (tab.inactiveTextColor ?? blackColor)
                    iconColor = isSelected
                        ? (tab.activeIconColor ?? textColor)
                        : (tab.inactiveIconColor ?? blackColor)
                }
            }

            let img = createSegmentImage(
                iconName: tab.iconName,
                title: tab.title,
                textColor: textColor,
                iconColor: iconColor
            )
            segmentedControl.setImage(img, forSegmentAt: i)
        }
    }

    private func createSegmentImage(
        iconName: String,
        title: String,
        textColor: UIColor,
        iconColor: UIColor,
        font: UIFont = UIFont.systemFont(ofSize: 12, weight: .bold)
    ) -> UIImage {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]
        let textSize = (title as NSString).size(withAttributes: attributes)
        let hasIcon = !iconName.isEmpty
        let iconSize = hasIcon ? CGSize(width: 14, height: 14) : CGSize.zero
        let spacing: CGFloat = hasIcon ? 6.0 : 0.0
        let totalWidth = ceil(iconSize.width + spacing + textSize.width)
        let totalHeight = ceil(max(iconSize.height, textSize.height))

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: totalWidth, height: totalHeight))
        let image = renderer.image { _ in
            if hasIcon {
                let iconRect = CGRect(
                    x: 0,
                    y: (totalHeight - iconSize.height) / 2,
                    width: iconSize.width,
                    height: iconSize.height
                )

                let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)
                let icon = UIImage(systemName: iconName, withConfiguration: config)?.withTintColor(iconColor, renderingMode: .alwaysOriginal)
                icon?.draw(in: iconRect)
            }

            let textRect = CGRect(
                x: hasIcon ? iconSize.width + spacing : 0,
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
