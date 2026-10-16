import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let registrar = self.registrar(forPlugin: "NativeTabBarPlugin") {
      let factory = NativeTabBarFactory(messenger: registrar.messenger())
      registrar.register(factory, withId: "trading_app/native-tab-bar")
      registrar.register(factory, withId: "com.mudasir.tradingapp/liquid_bottom_bar")
    }

    if let registrar = self.registrar(forPlugin: "NativeSegmentedControlPlugin") {
      let factory = NativeSegmentedControlFactory(messenger: registrar.messenger())
      registrar.register(factory, withId: "trading_app/native-segmented-control")
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
