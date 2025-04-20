-keep class com.github.chinloyal.pusher_client.** { *; }
-keep class io.agora.** { *; }
-keep class io.agora.rtc.** { *; }
-dontwarn io.agora.**
# Keep Firebase InstanceId and related classes
-keepclassmembers class * {
    public static <fields>;
    public *;
}
# Keep Firebase Messaging classes
-keep class io.flutter.plugins.firebasemessaging.** { *; }
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.installations.** { *; }

# Keep FlutterFirebaseMessagingService

# Keep Firebase background services

# WorkManager (if using background notifications)
-keep class androidx.work.** { *; }
# Keep SLF4J classes
-keep class org.slf4j.** { *; }
-keep class org.slf4j.impl.** { *; }