import UIKit
import Flutter
import Firebase
import FirebaseMessaging
import UserNotifications
import BackgroundTasks

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
      let pushManager = PushNotificationReceiver()
              pushManager.registerForPushNotifications()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    @objc func methodOfReceivedNotification(notification: Notification) {
             print("Value of notification : ", notification.object ?? "")
          
      
     }
     override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
       print(deviceToken)
         Messaging.messaging().apnsToken = deviceToken //*THIS WAS MISSING*
         super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken) //Not sure if calling super is required, but did anyway
       }
     @available(iOS 10.0, *)
     public override func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
         print(response.notification.request.content.userInfo)
         print("Allah")
    
         
     }
   
     @available(iOS 10.0, *)
     public override func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
         print(notification.request.content.userInfo)
        
     }
     
       

     override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Swift.Void) {
         
//         NotificationCenter.default.addObserver(self, selector: #selector(reinstateBackgroundTask),
//                          name: UIApplication.didBecomeActiveNotification, object: nil)
//
         
     }
}
