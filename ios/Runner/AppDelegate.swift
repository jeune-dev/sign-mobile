import Flutter
import UIKit
import Firebase
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Ne configure Firebase que si GoogleService-Info.plist est présent dans le bundle.
    // Sans ce garde, FirebaseApp.configure() lève une NSException fatale (crash natif,
    // avant même le démarrage de Dart) quand le fichier est absent — voir main.dart pour
    // le garde équivalent côté Dart, qui ne suffit pas seul car ce code natif s'exécute
    // avant lui.
    if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
      FirebaseApp.configure()
    } else {
      NSLog("⚠️ GoogleService-Info.plist introuvable : Firebase non initialisé sur iOS.")
    }
    UNUserNotificationCenter.current().delegate = self
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
