import UIKit
import Flutter
import UserNotifications
import fl_pip

@main
@objc class AppDelegate: FlFlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
     
    GeneratedPluginRegistrant.register(with: self)
    
    // Request notification authorization on app launch
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      
      // Use standard notification options (respects device mute settings)
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { granted, error in
          if granted {
            print("✅ Notification permission granted")
          } else {
            print("❌ Notification permission denied: \(String(describing: error))")
          }
        }
      )
    }
    
    // Register for remote notifications
    application.registerForRemoteNotifications()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Required for fl_pip - register plugins for PiP engine
  override func registerPlugin(_ registry: FlutterPluginRegistry) {
    GeneratedPluginRegistrant.register(with: registry)
  }
  
  // Handle successful registration for remote notifications
  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    print("📱 Successfully registered for remote notifications")
    print("📱 Device Token: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
  }
  
  // Handle failure to register for remote notifications
  override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
  }
  
  // Handle notification when app is in foreground (iOS 10+)
  @available(iOS 10.0, *)
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                      willPresent notification: UNNotification,
                                      withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    let userInfo = notification.request.content.userInfo
    print("🔔 Received notification in foreground: \(userInfo)")
    
    // Show notification even when app is in foreground
    if #available(iOS 14.0, *) {
      completionHandler([[.banner, .sound, .badge]])
    } else {
      completionHandler([[.alert, .sound, .badge]])
    }
  }
  
  // Handle notification tap (iOS 10+)
  @available(iOS 10.0, *)
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                      didReceive response: UNNotificationResponse,
                                      withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo
    print("🔔 User tapped notification: \(userInfo)")
    
    completionHandler()
  }
}
