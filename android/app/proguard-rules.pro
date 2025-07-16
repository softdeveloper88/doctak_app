# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Doctak specific classes
-keep class com.kt.doctak.** { *; }

# Pusher client
-keep class com.github.chinloyal.pusher_client.** { *; }

# Agora RTC
-keep class io.agora.** { *; }
-keep class io.agora.rtc.** { *; }
-dontwarn io.agora.**

# Firebase classes
-keep class com.google.firebase.** { *; }
-keep class io.flutter.plugins.firebasemessaging.** { *; }
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.installations.** { *; }
-keep class com.google.firebase.analytics.** { *; }
-keep class com.google.firebase.crashlytics.** { *; }

# Firebase InstanceId and related classes
-keepclassmembers class * {
    public static <fields>;
    public *;
}

# WorkManager (for background notifications)
-keep class androidx.work.** { *; }

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

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
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

# Remove logging in release builds
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}