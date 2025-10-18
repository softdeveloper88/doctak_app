## ========================================
## R8 OPTIMIZATION RULES - DOCTAK APP
## ========================================
## These rules are specifically for R8 full mode optimization
## and complement the proguard-rules.pro file

## ========================================
## CRITICAL: KOTLIN METADATA - MUST KEEP FOR PIGEON
## ========================================
## Kotlin uses metadata annotations that R8 strips by default
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeInvisibleAnnotations

## Keep Kotlin metadata
-keep class kotlin.Metadata { *; }
-keepclassmembers class * {
    @kotlin.Metadata *;
}

## Keep Kotlin companion objects
-keepclassmembers class * {
    public static ** Companion;
}

## Keep Kotlin object declarations
-keepclassmembers class * extends java.lang.Enum {
    <fields>;
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

## ========================================
## CRITICAL: KEEP ALL HTTP/NETWORKING CODE
## ========================================
## R8 in full mode is very aggressive and can break networking
-keep,allowobfuscation,allowshrinking class * extends java.io.InputStream
-keep,allowobfuscation,allowshrinking class * extends java.io.OutputStream
-keep,allowobfuscation,allowshrinking class * extends java.net.URLConnection

## Keep all HTTP connection classes
-keep class java.net.HttpURLConnection { *; }
-keep class javax.net.ssl.HttpsURLConnection { *; }
-keep class java.net.URL { *; }
-keep class java.net.URI { *; }

## ========================================
## FLUTTER PLATFORM CHANNELS - CRITICAL
## ========================================
## Critical for Flutter-Native communication (API calls use platform channels)
-keep class io.flutter.embedding.engine.FlutterEngine { *; }
-keep class io.flutter.embedding.engine.dart.DartExecutor { *; }
-keep class io.flutter.plugin.common.** { *; }
-keepclassmembers class io.flutter.plugin.common.** { *; }

## Keep BasicMessageChannel which Pigeon uses
-keep class io.flutter.plugin.common.BasicMessageChannel { *; }
-keep class io.flutter.plugin.common.BasicMessageChannel$* { *; }
-keep class io.flutter.plugin.common.BinaryMessenger { *; }
-keep class io.flutter.plugin.common.BinaryMessenger$* { *; }
-keep class io.flutter.plugin.common.MessageCodec { *; }
-keep class io.flutter.plugin.common.StandardMessageCodec { *; }

## Keep all method channel handlers
-keep class * implements io.flutter.plugin.common.MethodCall$Handler { *; }
-keepclassmembers class * {
    @io.flutter.plugin.common.MethodChannel$Result *;
}

## ========================================
## PIGEON GENERATED CLASSES - CRITICAL (Kotlin)
## ========================================
## Keep all Pigeon generated API classes - NO OBFUSCATION, NO SHRINKING, NO OPTIMIZATION
## IMPORTANT: Completely protect these from R8
-keep class dev.flutter.pigeon.** { *; }
-keep interface dev.flutter.pigeon.** { *; }
-keepclassmembers class dev.flutter.pigeon.** { *; }
-keepnames class dev.flutter.pigeon.** { *; }

## ========================================
## GOOGLE SIGN-IN - NUCLEAR OPTION (Kotlin Pigeon v26)
## ========================================
## These are Kotlin files using Pigeon v26.1.0
## Keep EVERYTHING related to Google Sign-In without ANY optimization
-keep class io.flutter.plugins.googlesignin.** { *; }
-keep interface io.flutter.plugins.googlesignin.** { *; }
-keepclassmembers class io.flutter.plugins.googlesignin.** { *; }
-keepnames class io.flutter.plugins.googlesignin.** { *; }
-keep class * extends io.flutter.plugins.googlesignin.** { *; }
-keep class * implements io.flutter.plugins.googlesignin.** { *; }
-dontwarn io.flutter.plugins.googlesignin.**

## Keep specific Google Sign-In Kotlin classes by exact name
-keep class io.flutter.plugins.googlesignin.Messages { *; }
-keep class io.flutter.plugins.googlesignin.Messages$* { *; }
-keep class io.flutter.plugins.googlesignin.MessagesPigeonUtils { *; }
-keep class io.flutter.plugins.googlesignin.FlutterError { *; }
-keep interface io.flutter.plugins.googlesignin.GoogleSignInApi { *; }
-keep class io.flutter.plugins.googlesignin.GoogleSignInPlugin { *; }
-keep class io.flutter.plugins.googlesignin.GoogleSignInPlugin$* { *; }
-keep class io.flutter.plugins.googlesignin.ResultUtils { *; }

## ========================================
## SHARED PREFERENCES - NUCLEAR OPTION (Kotlin Pigeon v26)
## ========================================
## These are Kotlin files using Pigeon v26.1.0
## Keep EVERYTHING related to SharedPreferences without ANY optimization
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep interface io.flutter.plugins.sharedpreferences.** { *; }
-keepclassmembers class io.flutter.plugins.sharedpreferences.** { *; }
-keepnames class io.flutter.plugins.sharedpreferences.** { *; }
-keep class * extends io.flutter.plugins.sharedpreferences.** { *; }
-keep class * implements io.flutter.plugins.sharedpreferences.** { *; }
-dontwarn io.flutter.plugins.sharedpreferences.**

## Keep specific SharedPreferences Kotlin classes by exact name
-keep class io.flutter.plugins.sharedpreferences.MessagesAsync { *; }
-keep class io.flutter.plugins.sharedpreferences.MessagesAsync$* { *; }
-keep class io.flutter.plugins.sharedpreferences.MessagesAsyncPigeonUtils { *; }
-keep class io.flutter.plugins.sharedpreferences.SharedPreferencesError { *; }
-keep interface io.flutter.plugins.sharedpreferences.SharedPreferencesAsyncApi { *; }
-keep class io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin { *; }
-keep class io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin$* { *; }

## ========================================
## ALL FLUTTER PLUGINS - MAXIMUM PROTECTION
## ========================================
## Keep all Flutter plugin classes - ABSOLUTE PROTECTION FROM R8
-keep class io.flutter.plugins.** { *; }
-keep interface io.flutter.plugins.** { *; }
-keepclassmembers class io.flutter.plugins.** { *; }
-keepnames class io.flutter.plugins.** { *; }
-keep class * extends io.flutter.plugins.** { *; }
-keep class * implements io.flutter.plugins.** { *; }
-dontwarn io.flutter.plugins.**

## Keep ALL Flutter embedding classes (critical for plugin communication)
-keep class io.flutter.embedding.** { *; }
-keep interface io.flutter.embedding.** { *; }
-keepclassmembers class io.flutter.embedding.** { *; }
-keepnames class io.flutter.embedding.** { *; }

## Keep ALL Messages classes generated by Pigeon (critical for communication)
-keep class **.*Messages { *; }
-keep class **.*Messages$** { *; }
-keep interface **.*Messages { *; }
-keep interface **.*Messages$** { *; }
-keepclassmembers class **.*Messages { *; }
-keepclassmembers class **.*Messages$** { *; }
-keepnames class **.*Messages { *; }
-keepnames class **.*Messages$** { *; }

## Keep ALL codec classes used by Pigeon
-keep class **.*Codec { *; }
-keep class **.*Codec$** { *; }
-keep interface **.*Codec { *; }
-keep interface **.*Codec$** { *; }
-keepclassmembers class **.*Codec { *; }
-keepclassmembers class **.*Codec$** { *; }
-keepnames class **.*Codec { *; }
-keepnames class **.*Codec$** { *; }

## Keep Pigeon API interfaces
-keep interface **.*Api { *; }
-keep interface **.*Api$** { *; }
-keepnames interface **.*Api { *; }
-keepnames interface **.*Api$** { *; }

## ========================================
## GLIDE - IMAGE LOADING (CRITICAL FIX)
## ========================================
## These classes were being stripped causing images not to load
-keep public class * implements com.bumptech.glide.module.GlideModule
-keep class * extends com.bumptech.glide.module.AppGlideModule { <init>(...); }
-keep public enum com.bumptech.glide.load.ImageHeaderParser$** {
    **[] $VALUES;
    public *;
}
-keep class com.bumptech.glide.** { *; }
-keep interface com.bumptech.glide.** { *; }
-keepclassmembers class com.bumptech.glide.** { *; }
-keep class com.bumptech.glide.load.resource.bitmap.VideoDecoder { *; }
-keep class com.bumptech.glide.load.resource.bitmap.VideoDecoder$* { *; }
-keep class com.bumptech.glide.load.engine.executor.GlideExecutor { *; }
-keep class com.bumptech.glide.gifdecoder.** { *; }
-dontwarn com.bumptech.glide.**

## ========================================
## EXOPLAYER / MEDIA3 - VIDEO PLAYBACK (CRITICAL FIX)
## ========================================
## These classes were being stripped causing videos not to play
-keep class androidx.media3.** { *; }
-keep interface androidx.media3.** { *; }
-keepclassmembers class androidx.media3.** { *; }
-keep class androidx.media3.exoplayer.** { *; }
-keep class androidx.media3.common.** { *; }
-keep class androidx.media3.datasource.** { *; }
-keep class androidx.media3.container.** { *; }
-dontwarn androidx.media3.**

## Legacy ExoPlayer (if used)
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**

## ========================================
## VIDEO PLAYER PLUGIN (CRITICAL FIX)
## ========================================
## This exact class was being stripped
-keep class io.flutter.plugins.videoplayer.** { *; }
-keep class io.flutter.plugins.videoplayer.texture.TextureVideoPlayer { *; }
-keep class io.flutter.plugins.videoplayer.texture.TextureVideoPlayer$* { *; }
-keepclassmembers class io.flutter.plugins.videoplayer.** { *; }

## ========================================
## IMAGE PICKER PLUGIN (CRITICAL FIX)
## ========================================
-keep class io.flutter.plugins.imagepicker.** { *; }
-keep class io.flutter.plugins.imagepicker.ImagePickerDelegate { *; }
-keep class io.flutter.plugins.imagepicker.ImagePickerDelegate$* { *; }
-keepclassmembers class io.flutter.plugins.imagepicker.** { *; }

## ========================================
## CACHED NETWORK IMAGE - IMAGE LOADING
## ========================================
-keep class com.baseflow.** { *; }
-keep class io.flutter.plugins.flutter_cache_manager.** { *; }
-dontwarn com.baseflow.**

## ========================================
## JSON PARSING - KEEP REFLECTION CLASSES
## ========================================
## Gson uses reflection heavily
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
-keep,allowobfuscation @interface com.google.gson.annotations.SerializedName

## Keep all getter/setter methods for JSON models
-keepclassmembers public class * {
    public void set*(***);
    public *** get*();
    public *** is*();
}

## ========================================
## FIREBASE MESSAGING - CRITICAL
## ========================================
## Keep all Firebase messaging receiver methods
-keepclassmembers class * extends com.google.firebase.messaging.FirebaseMessagingService {
    public void onMessageReceived(com.google.firebase.messaging.RemoteMessage);
    public void onDeletedMessages();
    public void onMessageSent(java.lang.String);
    public void onSendError(java.lang.String, java.lang.Exception);
    public void onNewToken(java.lang.String);
}

## ========================================
## DISABLE AGGRESSIVE OPTIMIZATIONS
## ========================================
## These optimizations can break API calls
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-dontpreverify

## ========================================
## KEEP EXCEPTION STACK TRACES
## ========================================
## Essential for debugging API failures
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
-keepattributes Exceptions,InnerClasses,Signature,Deprecated,EnclosingMethod

## ========================================
## ANDROIDX LIFECYCLE - USED BY FLUTTER
## ========================================
-keep class androidx.lifecycle.** { *; }
-keepclassmembers class * extends androidx.lifecycle.ViewModel {
    <init>(...);
}
-keepclassmembers class * extends androidx.lifecycle.AndroidViewModel {
    <init>(android.app.Application);
}

## ========================================
## COROUTINES (if used)
## ========================================
-keepclassmembernames class kotlinx.** {
    volatile <fields>;
}

## ========================================
## KEEP ALL DART INTEROP CLASSES
## ========================================
## Flutter uses these for Dart-Java communication
-keep class io.flutter.embedding.engine.plugins.** { *; }
-keep class io.flutter.embedding.engine.FlutterJNI { *; }
-keep class io.flutter.view.FlutterCallbackInformation { *; }

## ========================================
## MULTIDEX - KEEP ESSENTIAL CLASSES
## ========================================
-keep class androidx.multidex.** { *; }
-keep class android.support.multidex.** { *; }

## ========================================
## GOOGLE SIGN-IN - CRITICAL
## ========================================
## Keep Google Sign-In classes
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.tasks.** { *; }
-keep interface com.google.android.gms.auth.** { *; }
-keep interface com.google.android.gms.common.** { *; }
-keep interface com.google.android.gms.tasks.** { *; }

## Keep all Google Play Services classes
-keep class com.google.android.gms.** { *; }
-keep interface com.google.android.gms.** { *; }
-keepclassmembers class com.google.android.gms.** { *; }

## ========================================
## SHARED PREFERENCES - CRITICAL
## ========================================
## Keep SharedPreferences classes
-keep class android.content.SharedPreferences { *; }
-keep class android.content.SharedPreferences$** { *; }
-keepclassmembers class android.content.SharedPreferences { *; }
-keepclassmembers class android.content.SharedPreferences$** { *; }

## ========================================
## CRITICAL: FLUTTER PLUGIN INTERFACE IMPLEMENTATIONS
## ========================================
## Keep ALL classes that implement FlutterPlugin interface
## This is CRITICAL because R8 strips plugin classes causing
## GeneratedPluginRegistrant to fail with ClassNotFoundException
-keep class * implements io.flutter.embedding.engine.plugins.FlutterPlugin { *; }
-keep class * implements io.flutter.embedding.engine.plugins.activity.ActivityAware { *; }
-keep class * implements io.flutter.plugin.common.PluginRegistry$Registrar { *; }
-keep class * implements io.flutter.embedding.engine.plugins.lifecycle.FlutterLifecycleAdapter { *; }
-keepclassmembers class * implements io.flutter.embedding.engine.plugins.FlutterPlugin { *; }

## Keep GeneratedPluginRegistrant completely
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
-keepclassmembers class io.flutter.plugins.GeneratedPluginRegistrant { *; }

## ========================================
## CRITICAL: THIRD-PARTY FLUTTER PLUGIN PACKAGES
## ========================================
## These are the actual plugin classes that R8 is stripping
## ROOT CAUSE: flutter_sound_record being stripped breaks ALL plugins

## flutter_sound_record - ROOT CAUSE OF ALL ISSUES
-keep class com.josephcrowell.flutter_sound_record.** { *; }
-keepclassmembers class com.josephcrowell.flutter_sound_record.** { *; }

## package_info_plus
-keep class io.github.nicosemba.package_info_plus.** { *; }
-keep class dev.fluttercommunity.plus.packageinfo.** { *; }
-keepclassmembers class dev.fluttercommunity.plus.packageinfo.** { *; }

## connectivity_plus
-keep class dev.fluttercommunity.plus.connectivity.** { *; }
-keepclassmembers class dev.fluttercommunity.plus.connectivity.** { *; }

## Firebase plugins
-keep class io.flutter.plugins.firebase.** { *; }
-keep class io.flutter.plugins.firebase.messaging.** { *; }
-keep class io.flutter.plugins.firebase.auth.** { *; }
-keep class io.flutter.plugins.firebase.core.** { *; }
-keep class io.flutter.plugins.firebase.crashlytics.** { *; }
-keepclassmembers class io.flutter.plugins.firebase.** { *; }

## Google Sign In
-keep class io.flutter.plugins.googlesignin.** { *; }
-keepclassmembers class io.flutter.plugins.googlesignin.** { *; }

## Shared Preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keepclassmembers class io.flutter.plugins.sharedpreferences.** { *; }

## path_provider
-keep class io.flutter.plugins.pathprovider.** { *; }
-keepclassmembers class io.flutter.plugins.pathprovider.** { *; }

## image_picker
-keep class io.flutter.plugins.imagepicker.** { *; }
-keepclassmembers class io.flutter.plugins.imagepicker.** { *; }

## file_picker
-keep class com.mr.flutter.plugin.filepicker.** { *; }
-keepclassmembers class com.mr.flutter.plugin.filepicker.** { *; }

## permission_handler
-keep class com.baseflow.permissionhandler.** { *; }
-keepclassmembers class com.baseflow.permissionhandler.** { *; }

## device_info_plus
-keep class dev.fluttercommunity.plus.device_info.** { *; }
-keepclassmembers class dev.fluttercommunity.plus.device_info.** { *; }

## flutter_local_notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepclassmembers class com.dexterous.flutterlocalnotifications.** { *; }

## url_launcher
-keep class io.flutter.plugins.urllauncher.** { *; }
-keepclassmembers class io.flutter.plugins.urllauncher.** { *; }

## share_plus
-keep class dev.fluttercommunity.plus.share.** { *; }
-keepclassmembers class dev.fluttercommunity.plus.share.** { *; }

## webview_flutter
-keep class io.flutter.plugins.webviewflutter.** { *; }
-keepclassmembers class io.flutter.plugins.webviewflutter.** { *; }

## video_player
-keep class io.flutter.plugins.videoplayer.** { *; }
-keepclassmembers class io.flutter.plugins.videoplayer.** { *; }

## camera
-keep class io.flutter.plugins.camera.** { *; }
-keepclassmembers class io.flutter.plugins.camera.** { *; }

## photo_manager
-keep class com.fluttercandies.photo_manager.** { *; }
-keepclassmembers class com.fluttercandies.photo_manager.** { *; }

## flutter_webrtc
-keep class com.cloudwebrtc.webrtc.** { *; }
-keepclassmembers class com.cloudwebrtc.webrtc.** { *; }

## agora_rtc_engine
-keep class io.agora.** { *; }
-keepclassmembers class io.agora.** { *; }

## flutter_callkit_incoming
-keep class com.hiennv.flutter_callkit_incoming.** { *; }
-keepclassmembers class com.hiennv.flutter_callkit_incoming.** { *; }

## pusher_channels_flutter
-keep class com.pusher.channels_flutter.** { *; }
-keepclassmembers class com.pusher.channels_flutter.** { *; }

## just_audio
-keep class com.ryanheise.just_audio.** { *; }
-keepclassmembers class com.ryanheise.just_audio.** { *; }

## audio_session
-keep class com.ryanheise.audio_session.** { *; }
-keepclassmembers class com.ryanheise.audio_session.** { *; }

## flutter_keyboard_visibility
-keep class com.jrai.flutter_keyboard_visibility.** { *; }
-keepclassmembers class com.jrai.flutter_keyboard_visibility.** { *; }

## emoji_picker_flutter
-keep class com.fintasys.emoji_picker_flutter.** { *; }
-keepclassmembers class com.fintasys.emoji_picker_flutter.** { *; }

## app_links
-keep class com.llfbandit.app_links.** { *; }
-keepclassmembers class com.llfbandit.app_links.** { *; }

## fluttertoast
-keep class io.github.ponnamkarthik.toast.fluttertoast.** { *; }
-keepclassmembers class io.github.ponnamkarthik.toast.fluttertoast.** { *; }

## google_mobile_ads
-keep class io.flutter.plugins.googlemobileads.** { *; }
-keepclassmembers class io.flutter.plugins.googlemobileads.** { *; }

## nb_utils
-keep class com.nb.nb_utils.** { *; }
-keep class com.example.nb_utils.** { *; }
-keepclassmembers class com.example.nb_utils.** { *; }

## doctak app main classes
-keep class com.kt.doctak.** { *; }
-keepclassmembers class com.kt.doctak.** { *; }

## ========================================
## WEBRTC - VIDEO CALLS (CRITICAL FIX)
## ========================================
## These classes were being stripped
-keep class org.webrtc.** { *; }
-keep interface org.webrtc.** { *; }
-keepclassmembers class org.webrtc.** { *; }
-keep class org.webrtc.HardwareVideoEncoder { *; }
-keep class org.webrtc.VideoFrameDrawer { *; }
-keep class org.webrtc.FileVideoCapturer { *; }
-keep class org.webrtc.FileVideoCapturer$* { *; }
-dontwarn org.webrtc.**

## ========================================
## AGORA - VIDEO CALLS (CRITICAL FIX)
## ========================================
## These classes were being stripped
-keep class io.agora.base.** { *; }
-keep class io.agora.base.internal.video.** { *; }
-keep class io.agora.rtc2.** { *; }
-keep class io.agora.rtc2.video.** { *; }
-keep class io.agora.rtc2.internal.** { *; }
-keep class io.agora.rtc2.extensions.** { *; }
-keepclassmembers class io.agora.** { *; }
-dontwarn io.agora.**

## ========================================
## CREDENTIALS API - GOOGLE SIGN IN
## ========================================
-keep class androidx.credentials.** { *; }
-keep class androidx.credentials.playservices.** { *; }
-keepclassmembers class androidx.credentials.** { *; }

## ========================================
## OKHTTP - NETWORKING (CRITICAL FIX)
## ========================================
## These classes were being stripped - causing network issues
-keep class okhttp3.** { *; }
-keep class okhttp3.internal.** { *; }
-keep class okhttp3.internal.connection.** { *; }
-keep class okhttp3.internal.http2.** { *; }
-keep interface okhttp3.** { *; }
-keepclassmembers class okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

## ========================================
## END OF R8 RULES
## ========================================
