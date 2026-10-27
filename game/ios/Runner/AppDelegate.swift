import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "RelivablePlatform") {
      RelivablePlatform.register(with: registrar)
    }
  }
}

/// The "relivable/updater" channel on iPhone and iPad (lib/updater.dart and
/// lib/share/share_io.dart): opens links, including AltStore or SideStore
/// for updates, and shares Life Recap cards with the system share sheet.
class RelivablePlatform: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "relivable/updater", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(RelivablePlatform(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "openUrl":
      guard let s = args["url"] as? String, let url = URL(string: s) else {
        result("error")
        return
      }
      // False when no app handles the link (e.g. AltStore is not installed).
      UIApplication.shared.open(url, options: [:]) { ok in
        result(ok ? "opened" : "unavailable")
      }
    case "shareImage":
      guard let bytes = args["bytes"] as? FlutterStandardTypedData,
        let image = UIImage(data: bytes.data),
        let top = RelivablePlatform.topController()
      else {
        result("error")
        return
      }
      var items: [Any] = [image]
      if let text = args["text"] as? String, !text.isEmpty { items.append(text) }
      let sheet = UIActivityViewController(activityItems: items, applicationActivities: nil)
      if let pop = sheet.popoverPresentationController {
        pop.sourceView = top.view
        pop.sourceRect = CGRect(
          x: top.view.bounds.midX, y: top.view.bounds.maxY - 90, width: 1, height: 1)
        pop.permittedArrowDirections = [.down]
      }
      top.present(sheet, animated: true)
      result("shared")
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private static func topController() -> UIViewController? {
    let window = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
    var top = window?.rootViewController
    while let next = top?.presentedViewController { top = next }
    return top
  }
}
