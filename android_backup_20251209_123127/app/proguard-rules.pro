# ========================================
# PIGEON GENERATED CODE - MUST BE FIRST
# ========================================
# These rules MUST come first to ensure Pigeon-based plugins work in release mode
# Google Sign In - Pigeon API (critical for channel establishment)
# Keep Pigeon generated classes for platform channels
-keep class dev.flutter.pigeon.** { *; }
-keep interface dev.flutter.pigeon.** { *; }
-keep class io.flutter.plugins.googlesignin.Messages** { *; }
-keep class io.flutter.plugins.googlesignin.Messages$** { *; }
-keep interface io.flutter.plugins.googlesignin.Messages$** { *; }
-keep class io.flutter.plugins.googlesignin.GoogleSignInApi { *; }
-keep class io.flutter.plugins.googlesignin.GoogleSignInApi$** { *; }

# Shared Preferences - Pigeon API (critical for channel establishment)
-keep class io.flutter.plugins.sharedpreferences.Messages** { *; }
-keep class io.flutter.plugins.sharedpreferences.Messages$** { *; }
-keep interface io.flutter.plugins.sharedpreferences.Messages$** { *; }
-keep class io.flutter.plugins.sharedpreferences.SharedPreferencesApi { *; }
-keep class io.flutter.plugins.sharedpreferences.SharedPreferencesApi$** { *; }
-keep class io.flutter.plugins.sharedpreferences.SharedPreferencesAsyncApi { *; }
-keep class io.flutter.plugins.sharedpreferences.SharedPreferencesAsyncApi$** { *; }

# Keep ALL Pigeon-generated host API classes
-keep class **.Pigeon** { *; }
-keep interface **.Pigeon** { *; }
-keep class **$*Api { *; }
-keep interface **$*Api { *; }
-keep class **Api { *; }
-keep interface **Api { *; }

# Keep all inner classes of plugin packages that might be Pigeon-generated
-keep class io.flutter.plugins.**$* { *; }
-keep interface io.flutter.plugins.**$* { *; }

# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.** { *; }
-keep interface io.flutter.embedding.** { *; }

# Keep all Flutter plugin registrants
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
-keep class * extends io.flutter.embedding.engine.plugins.FlutterPlugin { *; }
-keep class * implements io.flutter.embedding.engine.plugins.FlutterPlugin { *; }
-keep class * implements io.flutter.embedding.engine.plugins.activity.ActivityAware { *; }

# ========================================
# CRITICAL: ALL PLUGINS FROM GeneratedPluginRegistrant.java
# ========================================
# These are the EXACT plugin classes that must be kept
# Failure to keep ANY of these causes ALL plugins to fail

# 1. Agora RTC Engine
-keep class io.agora.agora_rtc_ng.** { *; }
-keep class io.agora.agora_rtc_ng.AgoraRtcNgPlugin { *; }

# 2. App Badge Plus
-keep class me.liolin.app_badge_plus.** { *; }
-keep class me.liolin.app_badge_plus.AppBadgePlusPlugin { *; }

# 3. App Links
-keep class com.llfbandit.app_links.** { *; }
-keep class com.llfbandit.app_links.AppLinksPlugin { *; }

# 4. Audio Session
-keep class com.ryanheise.audio_session.** { *; }
-keep class com.ryanheise.audio_session.AudioSessionPlugin { *; }

# 5. Clear All Notifications
-keep class com.example.clear_all_notifications.** { *; }
-keep class com.example.clear_all_notifications.ClearAllNotificationsPlugin { *; }

# 6. Connectivity Plus
-keep class dev.fluttercommunity.plus.connectivity.** { *; }
-keep class dev.fluttercommunity.plus.connectivity.ConnectivityPlugin { *; }

# 7. Device Info Plus
-keep class dev.fluttercommunity.plus.device_info.** { *; }
-keep class dev.fluttercommunity.plus.device_info.DeviceInfoPlusPlugin { *; }

# 8. Emoji Picker Flutter
-keep class com.fintasys.emoji_picker_flutter.** { *; }
-keep class com.fintasys.emoji_picker_flutter.EmojiPickerFlutterPlugin { *; }

# 9. File Picker
-keep class com.mr.flutter.plugin.filepicker.** { *; }
-keep class com.mr.flutter.plugin.filepicker.FilePickerPlugin { *; }

# 10. Firebase Auth
-keep class io.flutter.plugins.firebase.auth.** { *; }
-keep class io.flutter.plugins.firebase.auth.FlutterFirebaseAuthPlugin { *; }

# 11. Firebase Core
-keep class io.flutter.plugins.firebase.core.** { *; }
-keep class io.flutter.plugins.firebase.core.FlutterFirebaseCorePlugin { *; }

# 12. Firebase Crashlytics
-keep class io.flutter.plugins.firebase.crashlytics.** { *; }
-keep class io.flutter.plugins.firebase.crashlytics.FlutterFirebaseCrashlyticsPlugin { *; }

# 13. Firebase Dynamic Links
-keep class io.flutter.plugins.firebase.dynamiclinks.** { *; }
-keep class io.flutter.plugins.firebase.dynamiclinks.FlutterFirebaseDynamicLinksPlugin { *; }

# 14. Firebase Messaging
-keep class io.flutter.plugins.firebase.messaging.** { *; }
-keep class io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingPlugin { *; }

# 15. Flutter Callkit Incoming
-keep class com.hiennv.flutter_callkit_incoming.** { *; }
-keep class com.hiennv.flutter_callkit_incoming.FlutterCallkitIncomingPlugin { *; }

# 16. Flutter Keyboard Visibility Temp Fork
-keep class com.jrai.flutter_keyboard_visibility_temp_fork.** { *; }
-keep class com.jrai.flutter_keyboard_visibility_temp_fork.FlutterKeyboardVisibilityTempForkPlugin { *; }

# 17. Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin { *; }

# 18. Flutter Android Lifecycle
-keep class io.flutter.plugins.flutter_plugin_android_lifecycle.** { *; }
-keep class io.flutter.plugins.flutter_plugin_android_lifecycle.FlutterAndroidLifecyclePlugin { *; }

# 19. Flutter Sound Record - CRITICAL (causes cascade failure)
-keep class com.josephcrowell.flutter_sound_record.** { *; }
-keep class com.josephcrowell.flutter_sound_record.FlutterSoundRecordPlugin { *; }
-dontwarn com.josephcrowell.flutter_sound_record.**

# 20. Flutter WebRTC
-keep class com.cloudwebrtc.webrtc.** { *; }
-keep class com.cloudwebrtc.webrtc.FlutterWebRTCPlugin { *; }

# 21. Flutter Toast
-keep class io.github.ponnamkarthik.toast.fluttertoast.** { *; }
-keep class io.github.ponnamkarthik.toast.fluttertoast.FlutterToastPlugin { *; }

# 22. Gal (Gallery)
-keep class studio.midoridesign.gal.** { *; }
-keep class studio.midoridesign.gal.GalPlugin { *; }

# 23. Google Mobile Ads
-keep class io.flutter.plugins.googlemobileads.** { *; }
-keep class io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin { *; }

# 24. Google Sign In
-keep class io.flutter.plugins.googlesignin.** { *; }
-keep class io.flutter.plugins.googlesignin.GoogleSignInPlugin { *; }

# 25. Image Picker
-keep class io.flutter.plugins.imagepicker.** { *; }
-keep class io.flutter.plugins.imagepicker.ImagePickerPlugin { *; }

# 26. Iris Method Channel (Agora)
-keep class com.agora.iris_method_channel.** { *; }
-keep class com.agora.iris_method_channel.IrisMethodChannelPlugin { *; }

# 27. Just Audio
-keep class com.ryanheise.just_audio.** { *; }
-keep class com.ryanheise.just_audio.JustAudioPlugin { *; }

# 28. NB Utils
-keep class com.example.nb_utils.** { *; }
-keep class com.example.nb_utils.NbUtilsPlugin { *; }

# 29. Package Info Plus
-keep class dev.fluttercommunity.plus.packageinfo.** { *; }
-keep class dev.fluttercommunity.plus.packageinfo.PackageInfoPlugin { *; }

# 30. Path Provider
-keep class io.flutter.plugins.pathprovider.** { *; }
-keep class io.flutter.plugins.pathprovider.PathProviderPlugin { *; }

# 31. Permission Handler
-keep class com.baseflow.permissionhandler.** { *; }
-keep class com.baseflow.permissionhandler.PermissionHandlerPlugin { *; }

# 32. Photo Manager
-keep class com.fluttercandies.photo_manager.** { *; }
-keep class com.fluttercandies.photo_manager.PhotoManagerPlugin { *; }

# 33. Pusher Channels Flutter
-keep class com.pusher.channels_flutter.** { *; }
-keep class com.pusher.channels_flutter.PusherChannelsFlutterPlugin { *; }

# 34. Quill Native Bridge
-keep class dev.flutterquill.quill_native_bridge.** { *; }
-keep class dev.flutterquill.quill_native_bridge.QuillNativeBridgePlugin { *; }

# 35. Share Plus
-keep class dev.fluttercommunity.plus.share.** { *; }
-keep class dev.fluttercommunity.plus.share.SharePlusPlugin { *; }

# 36. Shared Preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin { *; }

# 37. Sign In With Apple
-keep class com.aboutyou.dart_packages.sign_in_with_apple.** { *; }
-keep class com.aboutyou.dart_packages.sign_in_with_apple.SignInWithApplePlugin { *; }

# 38. SMS Autofill
-keep class com.jaumard.smsautofill.** { *; }
-keep class com.jaumard.smsautofill.SmsAutoFillPlugin { *; }

# 39. Sqflite
-keep class com.tekartik.sqflite.** { *; }
-keep class com.tekartik.sqflite.SqflitePlugin { *; }

# 40. URL Launcher
-keep class io.flutter.plugins.urllauncher.** { *; }
-keep class io.flutter.plugins.urllauncher.UrlLauncherPlugin { *; }

# 41. Video Player
-keep class io.flutter.plugins.videoplayer.** { *; }
-keep class io.flutter.plugins.videoplayer.VideoPlayerPlugin { *; }

# 42. Wakelock Plus
-keep class dev.fluttercommunity.plus.wakelock.** { *; }
-keep class dev.fluttercommunity.plus.wakelock.WakelockPlusPlugin { *; }

# 43. Webview Flutter
-keep class io.flutter.plugins.webviewflutter.** { *; }
-keep class io.flutter.plugins.webviewflutter.WebViewFlutterPlugin { *; }

# ========================================
# KEEP ALL THIRD-PARTY PLUGIN CLASSES BY BASE PACKAGE
# ========================================
-keep class dev.fluttercommunity.** { *; }
-keep class com.baseflow.** { *; }
-keep class com.dexterous.** { *; }
-keep class com.it_nomads.** { *; }
-keep class com.mr.flutter.** { *; }
-keep class creativemaybeno.** { *; }
-keep class com.josephcrowell.** { *; }

# Keep all BasicMessageChannel, MethodChannel, EventChannel classes
-keep class io.flutter.plugin.common.BasicMessageChannel { *; }
-keep class io.flutter.plugin.common.MethodChannel { *; }
-keep class io.flutter.plugin.common.EventChannel { *; }
-keep class io.flutter.plugin.common.BinaryMessenger { *; }
-keep class io.flutter.plugin.common.StandardMessageCodec { *; }
-keep class io.flutter.plugin.common.JSONMessageCodec { *; }
-keep class io.flutter.plugin.common.StringCodec { *; }
-keepclassmembers class io.flutter.plugin.common.** { *; }

# ========================================
# PIGEON GENERATED CODE - CRITICAL FOR PLUGIN COMMUNICATION
# ========================================
# Keep all Pigeon generated classes (platform channels)
-keep class io.flutter.plugins.** { *; }
-keep interface io.flutter.plugins.** { *; }
-keepclassmembers class io.flutter.plugins.** { *; }

# Google Sign In Pigeon API
-keep class io.flutter.plugins.googlesignin.** { *; }
-keep interface io.flutter.plugins.googlesignin.** { *; }
-keepclassmembers class io.flutter.plugins.googlesignin.** { *; }
-keep class dev.flutter.pigeon.google_sign_in_android.** { *; }
-keep interface dev.flutter.pigeon.google_sign_in_android.** { *; }

# Shared Preferences Pigeon API
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep interface io.flutter.plugins.sharedpreferences.** { *; }
-keepclassmembers class io.flutter.plugins.sharedpreferences.** { *; }
-keep class dev.flutter.pigeon.shared_preferences_android.** { *; }
-keep interface dev.flutter.pigeon.shared_preferences_android.** { *; }

# Keep all Pigeon package classes
-keep class dev.flutter.pigeon.** { *; }
-keep interface dev.flutter.pigeon.** { *; }
-keepclassmembers class dev.flutter.pigeon.** { *; }

# ========================================
# DIO HTTP CLIENT - CRITICAL FOR API CALLS
# ========================================
-keep class io.flutter.plugins.connectivity.** { *; }
-keep class io.flutter.plugin.common.** { *; }

# Keep Dio-related native methods and classes
-keepclassmembers class * {
    @io.flutter.plugin.common.MethodChannel.Result *;
}

# ========================================
# JSON SERIALIZATION - CRITICAL FOR API DATA
# ========================================
# Keep all data model classes for JSON parsing
-keep class com.kt.doctak.data.models.** { *; }
-keepclassmembers class com.kt.doctak.data.models.** { *; }

# Keep all JSON-related annotations and fields
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Keep Dart/Flutter model classes (JSON serialization)
-keep class * implements java.io.Serializable { *; }
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ========================================
# NETWORK CLASSES - HTTP REQUESTS/RESPONSES
# ========================================
# OkHttp (used by Dio internally)
-keepattributes Signature
-keepattributes *Annotation*
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okio.** { *; }

# Retrofit (if used)
-keep class retrofit2.** { *; }
-keepclasseswithmembers class * {
    @retrofit2.http.* <methods>;
}
-keepclassmembers,allowshrinking,allowobfuscation interface * {
    @retrofit2.http.* <methods>;
}
-dontwarn retrofit2.**

# Gson (JSON parser)
-keep class com.google.gson.** { *; }
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.stream.** { *; }
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# ========================================
# HTTP URL CONNECTION
# ========================================
-keep class java.net.** { *; }
-keep class javax.net.** { *; }
-dontwarn java.net.**
-dontwarn javax.net.**

# ========================================
# SSL/TLS - REQUIRED FOR HTTPS
# ========================================
-keep class javax.net.ssl.** { *; }
-keep class org.apache.http.** { *; }
-dontwarn org.apache.http.**
-dontwarn javax.net.ssl.**

# Keep SSL socket factory
-keep class * extends javax.net.ssl.SSLSocketFactory {
    *;
}

# Flutter Sound Record Plugin
-keep class com.josephcrowell.flutter_sound_record.** { *; }
-keep class com.josephcrowell.flutter_sound_record.FlutterSoundRecordPlugin { *; }
-dontwarn com.josephcrowell.flutter_sound_record.**
-dontwarn com.josephcrowell.flutter_sound_record.FlutterSoundRecordPlugin

# Doctak specific classes
-keep class com.kt.doctak.** { *; }

# Pusher client
-keep class com.github.chinloyal.pusher_client.** { *; }

# Agora RTC
-keep class io.agora.** { *; }
-keep class io.agora.rtc.** { *; }
-dontwarn io.agora.**

# ========================================
# FIREBASE - CRITICAL FOR PUSH NOTIFICATIONS
# ========================================
-keep class com.google.firebase.** { *; }
-keep class io.flutter.plugins.firebasemessaging.** { *; }
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.installations.** { *; }
-keep class com.google.firebase.analytics.** { *; }
-keep class com.google.firebase.crashlytics.** { *; }
-keep class com.google.firebase.iid.** { *; }
-dontwarn com.google.firebase.**

# Firebase messaging models
-keepclassmembers class com.google.firebase.messaging.RemoteMessage {
    public *;
}
-keepclassmembers class com.google.firebase.messaging.RemoteMessage$Notification {
    public *;
}

# Firebase InstanceId and related classes
-keepclassmembers class * {
    public static <fields>;
    public *;
}

# ========================================
# GOOGLE PLAY SERVICES & GOOGLE SIGN-IN
# ========================================

# Keep all Flutter embedding classes
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Pigeon generated classes
-keep class **.*Pigeon** { *; }
-keep interface **.*Pigeon** { *; }

# Keep Google Sign-In classes
-keep class io.flutter.plugins.googlesignin.** { *; }
-keep class com.google.android.gms.** { *; }
-keep interface com.google.android.gms.** { *; }

# Keep method channel related classes
-keepclassmembers class * {
    @io.flutter.embedding.engine.plugins.** *;
}

# Don't obfuscate
-dontobfuscate

-keep class com.google.android.gms.** { *; }
-keep interface com.google.android.gms.** { *; }
-keepclassmembers class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Google Sign-In specific classes
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.tasks.** { *; }

# Google Sign-In native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# WorkManager (for background notifications)
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**

# SLF4J classes
-keep class org.slf4j.** { *; }
-keep class org.slf4j.impl.** { *; }

# AndroidX classes
-keep class androidx.core.** { *; }
-keep class androidx.appcompat.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelable classes
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator CREATOR;
}

# Keep R class for resources
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Install Referrer API
-keep class com.android.installreferrer.** { *; }
-dontwarn com.android.installreferrer.**

# Jackson databind (for JSON processing)
-keep class com.fasterxml.jackson.** { *; }
-dontwarn com.fasterxml.jackson.**
-dontwarn java.beans.**

# DOM classes (referenced by Jackson)
-dontwarn org.w3c.dom.bootstrap.DOMImplementationRegistry

# Flutter Play Store Split Application
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }

# Additional keep rules for missing classes
-keep class java.beans.** { *; }
-dontwarn java.beans.**

# Specific rules for the classes mentioned in the error (keep only non-Play Core related)
-dontwarn java.beans.ConstructorProperties
-dontwarn java.beans.Transient
-dontwarn org.w3c.dom.bootstrap.DOMImplementationRegistry

# Missing classes detected by R8 - suppress warnings for excluded Google Play Core classes
-dontwarn com.google.android.play.core.common.PlayCoreDialogWrapperActivity
-dontwarn com.google.android.play.core.integrity.**
-dontwarn com.google.android.play.core.common.**
-dontwarn com.google.android.play.core.listener.**
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Alternative: If you don't need deferred components, you can exclude them
-dontwarn io.flutter.embedding.android.FlutterPlayStoreSplitApplication
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# ========================================
# DEBUGGING - KEEP USEFUL INFO FOR CRASH REPORTS
# ========================================
# Keep source file names and line numbers for better crash reports
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Keep method names for debugging
-keepattributes MethodParameters

# Don't remove logging completely (helps with Firebase Crashlytics)
# Only remove verbose/debug logs, keep warnings and errors
-assumenosideeffects class android.util.Log {
    public static int v(...);
    public static int d(...);
}

# ========================================
# REFLECTION - KEEP CLASSES USED VIA REFLECTION
# ========================================
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeInvisibleAnnotations
-keepattributes RuntimeVisibleParameterAnnotations
-keepattributes RuntimeInvisibleParameterAnnotations

# Keep classes that use reflection
-keepclassmembers class * {
    @androidx.annotation.Keep *;
}

# ========================================
# WEBVIEW (if used in app)
# ========================================
-keepclassmembers class * extends android.webkit.WebViewClient {
    public void *(android.webkit.WebView, java.lang.String, android.graphics.Bitmap);
    public boolean *(android.webkit.WebView, java.lang.String);
}
-keepclassmembers class * extends android.webkit.WebChromeClient {
    public void *(android.webkit.WebView, java.lang.String);
}

# Specific rules for the classes mentioned in the error (keep only non-Play Core related)
-dontwarn java.beans.ConstructorProperties
-dontwarn java.beans.Transient
-dontwarn org.w3c.dom.bootstrap.DOMImplementationRegistry

# Missing classes detected by R8 - suppress warnings for excluded Google Play Core classes
-dontwarn com.google.android.play.core.common.PlayCoreDialogWrapperActivity
-dontwarn com.google.android.play.core.integrity.**
-dontwarn com.google.android.play.core.common.**
-dontwarn com.google.android.play.core.listener.**
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Alternative: If you don't need deferred components, you can exclude them
-dontwarn io.flutter.embedding.android.FlutterPlayStoreSplitApplication
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Remove logging in release builds
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

# ========================================
# DATA MODELS & JSON SERIALIZATION
# ========================================
# Critical for API responses and data persistence
-keep class com.kt.doctak.data.models.** { *; }
-keep class com.kt.doctak.data.** { *; }
-keepclassmembers class com.kt.doctak.data.models.** {
    <init>();
    <init>(...);
    public *;
    protected *;
}

# Gson annotations
-keepattributes Signature
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.stream.** { *; }
-keep class com.google.gson.** { *; }
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Jackson (alternative JSON parser)
-keep class com.fasterxml.jackson.** { *; }
-keep class com.fasterxml.jackson.databind.** { *; }
-keep class com.fasterxml.jackson.annotation.** { *; }
-keepclassmembers,allowobfuscation class * {
    @com.fasterxml.jackson.annotation.JsonProperty <fields>;
}

# ========================================
# NETWORK & HTTP CLASSES
# ========================================
# Keep all networking libraries intact
-keep class okhttp3.** { *; }
-keep class com.squareup.okhttp3.** { *; }
-keep class okio.** { *; }
-keep class retrofit2.** { *; }
-keepclasseswithmembers class * {
    @retrofit2.http.* <methods>;
}
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn retrofit2.**

# Keep OkHttp Connection classes
-keep class okhttp3.internal.** { *; }
-keepclassmembers class okhttp3.** {
    public *;
    private *;
}

# SSL/TLS support
-keep class javax.net.ssl.** { *; }
-keep class javax.security.** { *; }
-dontwarn javax.net.ssl.**

# HTTP request/response classes
-keep class java.net.** { *; }
-keep class java.io.** { *; }
-dontwarn java.net.**

# ========================================
# FIREBASE & GOOGLE PLAY SERVICES
# ========================================
# Critical for push notifications and authentication
-keep class com.google.firebase.** { *; }
-keep interface com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep interface com.google.android.gms.** { *; }
-keep class com.google.android.gms.internal.** { *; }
-keep interface com.google.android.gms.internal.** { *; }

-keepclassmembers class com.google.firebase.** { *; }
-keepclassmembers class com.google.android.gms.** { *; }

# Firebase Messaging
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.messaging.RemoteMessage { *; }
-keep class com.google.firebase.messaging.FirebaseMessaging { *; }
-keepclassmembers class com.google.firebase.messaging.RemoteMessage$Notification {
    public *;
}

# Firebase Crashlytics
-keep class com.google.firebase.crashlytics.** { *; }
-keep class com.google.firebase.crashlytics.internal.** { *; }

# Firebase Auth
-keep class com.google.firebase.auth.** { *; }
-keep class com.google.android.gms.auth.** { *; }

# Firebase Analytics
-keep class com.google.firebase.analytics.** { *; }

# Google Play Services specific classes
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.tasks.** { *; }
-keep class com.google.android.gms.signin.** { *; }

# Don't warn about Play Services
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ========================================
# PLUGIN COMMUNICATION CHANNELS
# ========================================
# Method Channel and Platform Channel classes
-keep class io.flutter.plugin.common.BasicMessageChannel { *; }
-keep class io.flutter.plugin.common.MethodChannel { *; }
-keep class io.flutter.plugin.common.EventChannel { *; }
-keep class io.flutter.plugin.common.BinaryMessenger { *; }
-keep class io.flutter.plugin.common.StandardMessageCodec { *; }
-keep class io.flutter.plugin.common.JSONMessageCodec { *; }
-keep class io.flutter.plugin.common.StringCodec { *; }
-keepclassmembers class io.flutter.plugin.common.** { *; }

# ========================================
# AGORA RTC ADDITIONAL CLASSES
# ========================================
-keep class io.agora.** { *; }
-keep class io.agora.rtc.** { *; }
-keep class io.agora.rtc2.** { *; }
-keep class io.agora.base.** { *; }
-keep class io.agora.utils.** { *; }
-keep class com.agora.** { *; }
-keepclassmembers class io.agora.** { *; }

# ========================================
# FLUTTER SOUND RECORD CLASSES
# ========================================
-keep class com.josephcrowell.flutter_sound_record.** { *; }
-keep class com.josephcrowell.flutter_sound_record.FlutterSoundRecordPlugin { *; }
-keepclassmembers class com.josephcrowell.flutter_sound_record.** { *; }
-dontwarn com.josephcrowell.flutter_sound_record.**

# ========================================
# WEBRTC CLASSES
# ========================================
-keep class org.webrtc.** { *; }
-keep class com.cloudwebrtc.webrtc.** { *; }
-keep class org.webrtc.* { *; }

# ========================================
# ANDROID FRAMEWORK KEEP RULES
# ========================================
# Activity and Fragment classes
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider
-keep public class * extends android.app.backup.BackupAgent
-keep public class * extends androidx.appcompat.app.AppCompatActivity

# View inflation methods
-keepclassmembers public class * extends android.view.View {
    public <init>(android.content.Context);
    public <init>(android.content.Context, android.util.AttributeSet);
    public void set*(***);
    *** get*();
}

# Parcelable and Serializable
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}
-keep class * implements java.io.Serializable {
    *;
}

# Enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ========================================
# R CLASS RESOURCES
# ========================================
-keepclassmembers class **.R$* {
    public static <fields>;
}
-keep class **.R { *; }
-keep class **.R$* { *; }

# ========================================
# ANDROIDX & SUPPORT LIBRARIES
# ========================================
-keep class androidx.** { *; }
-keep interface androidx.** { *; }
-keep class android.support.** { *; }
-keep interface android.support.** { *; }

# WorkManager
-keep class androidx.work.** { *; }
-keep class androidx.work.impl.** { *; }

# Lifecycle components
-keep class androidx.lifecycle.** { *; }
-keep class androidx.appcompat.** { *; }

# ========================================
# KOTLIN COROUTINES
# ========================================
-keep class kotlin.** { *; }
-keep class kotlinx.coroutines.** { *; }
-keep class kotlinx.coroutines.flow.** { *; }
-keep interface kotlinx.coroutines.** { *; }

# ========================================
# NATIVE METHODS
# ========================================
-keepclasseswithmembernames,includedescriptorclasses class * {
    native <methods>;
}

# ========================================
# REFLECTION & ANNOTATIONS
# ========================================
-keepattributes Signature
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeInvisibleAnnotations
-keepattributes RuntimeVisibleParameterAnnotations
-keepattributes RuntimeInvisibleParameterAnnotations
-keepattributes AnnotationDefault

-keepclassmembers class * {
    @androidx.annotation.Keep *;
}
-keepclassmembers class * {
    @android.support.annotation.Keep *;
}

# ========================================
# APP-SPECIFIC CLASSES
# ========================================
-keep class com.kt.doctak.** { *; }
-keep class com.kt.doctak.MainActivity { *; }
-keep class com.kt.doctak.DoctakApplication { *; }
-keep class com.kt.doctak.presentation.** { *; }

# Keep all public and protected members in app package
-keepclassmembers class com.kt.doctak.** {
    public *;
    protected *;
}

# ========================================
# OTHER IMPORTANT LIBRARIES
# ========================================
# Image loading and caching
-keep class com.bumptech.glide.** { *; }
-keep class androidx.media3.** { *; }
-keep class androidx.media3.exoplayer.** { *; }

# Datastore
-keep class androidx.datastore.** { *; }

# SQL libraries
-keep class android.database.** { *; }

# ========================================
# FINAL SAFETY RULES
# ========================================
# Ensure critical entry points are preserved
-keepclasseswithmembernames class * {
    public <init>(...);
}

# Keep all custom applications
-keep class * extends android.app.Application

# Keep Exception classes for meaningful stack traces
-keepclassmembers class * extends java.lang.Exception {
    <init>();
    <init>(java.lang.String);
    <init>(java.lang.Throwable);
    <init>(java.lang.String, java.lang.Throwable);
}

# Preserve toString, equals, hashCode for debugging
-keepclassmembers class * {
    public java.lang.String toString();
    public int hashCode();
    public boolean equals(java.lang.Object);
}

# Allow access modification
-allowaccessmodification

# ========================================
# END OF PROGUARD CONFIGURATION
# ========================================