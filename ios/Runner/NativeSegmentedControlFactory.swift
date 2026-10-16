import Flutter
import UIKit

/// Factory that Flutter calls to instantiate the native iOS segmented control
class NativeSegmentedControlFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        NativeSegmentedControlPlatformView(frame: frame, viewId: viewId, messenger: messenger, args: args)
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        FlutterStandardMessageCodec.sharedInstance()
    }
}

/// 100% Native iOS UISegmentedControl Platform View with Icons + High-Contrast Typography
final class NativeSegmentedControlPlatformView: NSObject, FlutterPlatformView {
    private let container = UIView()
    private let segmentedControl = UISegmentedControl()
    private let channel: FlutterMethodChannel
    private var isDarkMode: Bool = false

    private struct TabSpec {
        let title: String
        let iconName: String
        let color: UIColor
    }

    private let tabs: [TabSpec] = [
        TabSpec(
            title: "Gainers",
            iconName: "trending.up",
            color: UIColor(red: 5.0 / 255.0, green: 150.0 / 255.0, blue: 105.0 / 255.0, alpha: 1.0)
        ),
        TabSpec(
            title: "Losers",
            iconName: "trending.down",
            color: UIColor(red: 220.0 / 255.0, green: 38.0 / 255.0, blue: 38.0 / 255.0, alpha: 1.0)
        ),
        TabSpec(
            title: "Active",
            iconName: "flame.fill",
            color: UIColor(red: 217.0 / 255.0, green: 119.0 / 255.0, blue: 6.0 / 255.0, alpha: 1.0)
        )
    ]

    init(frame: CGRect, viewId: Int64, messenger: FlutterBinaryMessenger, args: Any?) {
        channel = FlutterMethodChannel(name: "trading_app/native-segmented-control_\(viewId)", binaryMessenger: messenger)
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

        // Initialize segments with placeholder images
        for i in 0..<tabs.count {
            segmentedControl.insertSegment(with: UIImage(), at: i, animated: false)
        }

        segmentedControl.frame = container.bounds
        segmentedControl.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        segmentedControl.selectedSegmentIndex = max(0, min(2, initial))

        applyThemeStyle()
        updateSelectedColor(for: segmentedControl.selectedSegmentIndex)
        updateSegmentImages()

        segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        container.addSubview(segmentedControl)

        // Listen for programmatic updates from Flutter
        channel.setMethodCallHandler { [weak self] call, result in
            guard let self = self else { return }
            if call.method == "setTab", let idx = (call.arguments as? [String: Any])?["index"] as? Int {
                if idx >= 0 && idx < self.tabs.count {
                    self.segmentedControl.selectedSegmentIndex = idx
                    self.updateSelectedColor(for: idx)
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
        // Deep solid Slate 900 (#0F172A) for Light Mode to guarantee 100% visible, bold text
        // Crisp Slate 200 (#E2E8F0) for Dark Mode
        let unselectedColor = isDarkMode
            ? UIColor(red: 226.0 / 255.0, green: 232.0 / 255.0, blue: 240.0 / 255.0, alpha: 0.95)
            : UIColor(red: 15.0 / 255.0, green: 23.0 / 255.0, blue: 42.0 / 255.0, alpha: 1.0)

        for i in 0..<tabs.count {
            let isSelected = (i == segmentedControl.selectedSegmentIndex)
            let color = isSelected ? UIColor.white : unselectedColor
            let img = createSegmentImage(
                iconName: tabs[i].iconName,
                title: tabs[i].title,
                foregroundColor: color
            )
            segmentedControl.setImage(img, forSegmentAt: i)
        }
    }

    /// Renders composite Icon + Title into an image with exact renderingMode to bypass vibrancy dimming
    private func createSegmentImage(
        iconName: String,
        title: String,
        foregroundColor: UIColor,
        font: UIFont = UIFont.systemFont(ofSize: 11, weight: .bold)
    ) -> UIImage {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: foregroundColor
        ]
        let textSize = (title as NSString).size(withAttributes: attributes)
        let iconSize = CGSize(width: 13, height: 13)
        let spacing: CGFloat = 4.0
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

            if iconName == "trending.up" {
                // Stock market zigzag uptrend icon (identical to Icons.trending_up_rounded)
                foregroundColor.setStroke()
                let path = UIBezierPath()
                path.lineWidth = 1.6
                path.lineCapStyle = .round
                path.lineJoinStyle = .round
                // Zigzag path
                path.move(to: CGPoint(x: iconRect.minX + 1.0, y: iconRect.minY + 9.5))
                path.addLine(to: CGPoint(x: iconRect.minX + 4.8, y: iconRect.minY + 5.8))
                path.addLine(to: CGPoint(x: iconRect.minX + 7.8, y: iconRect.minY + 8.2))
                path.addLine(to: CGPoint(x: iconRect.minX + 12.0, y: iconRect.minY + 2.5))
                // Arrowhead
                path.move(to: CGPoint(x: iconRect.minX + 8.0, y: iconRect.minY + 2.5))
                path.addLine(to: CGPoint(x: iconRect.minX + 12.0, y: iconRect.minY + 2.5))
                path.addLine(to: CGPoint(x: iconRect.minX + 12.0, y: iconRect.minY + 6.5))
                path.stroke()
            } else if iconName == "trending.down" {
                // Stock market zigzag downtrend icon (identical to Icons.trending_down_rounded)
                foregroundColor.setStroke()
                let path = UIBezierPath()
                path.lineWidth = 1.6
                path.lineCapStyle = .round
                path.lineJoinStyle = .round
                // Zigzag path
                path.move(to: CGPoint(x: iconRect.minX + 1.0, y: iconRect.minY + 2.5))
                path.addLine(to: CGPoint(x: iconRect.minX + 4.8, y: iconRect.minY + 6.2))
                path.addLine(to: CGPoint(x: iconRect.minX + 7.8, y: iconRect.minY + 3.8))
                path.addLine(to: CGPoint(x: iconRect.minX + 12.0, y: iconRect.minY + 9.5))
                // Arrowhead
                path.move(to: CGPoint(x: iconRect.minX + 8.0, y: iconRect.minY + 9.5))
                path.addLine(to: CGPoint(x: iconRect.minX + 12.0, y: iconRect.minY + 9.5))
                path.addLine(to: CGPoint(x: iconRect.minX + 12.0, y: iconRect.minY + 5.5))
                path.stroke()
            } else {
                let config = UIImage.SymbolConfiguration(pointSize: 11, weight: .bold)
                let icon = UIImage(systemName: iconName, withConfiguration: config)?.withTintColor(foregroundColor, renderingMode: .alwaysOriginal)
                icon?.draw(in: iconRect)
            }

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
        updateSegmentImages()
        channel.invokeMethod("onTabSelected", arguments: ["index": index])
    }

    func view() -> UIView {
        container
    }
}
