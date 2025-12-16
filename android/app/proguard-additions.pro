# ========================================
# CRITICAL IMAGE/VIDEO LOADING FIXES FOR AGP 8.x
# ========================================

# Coil (Kotlin reflection and image request classes)
-keep class coil.** { *; }
-keep class coil.map.** { *; }
-keep class coil.request.** { *; }
-keep class coil.decode.** { *; }
-keep class coil.diskcache.** { *; }
-keep class coil.util.** { *; }

# ========================================
# GLIDE - IMAGE LOADING (FIX FOR IMAGES NOT LOADING)
# ========================================
-keep class com.bumptech.glide.** { *; }
-keep class com.github.bumptech.glide.** { *; }
-keep class androidx.vectordrawable.** { *; }
-keep public class * implements com.bumptech.glide.module.GlideModule
-keep class * extends com.bumptech.glide.module.AppGlideModule { <init>(...); }
-keep public enum com.bumptech.glide.load.ImageHeaderParser$** {
    **[] $VALUES;
    public *;
}
-keep class com.bumptech.glide.load.resource.bitmap.VideoDecoder { *; }
-keep class com.bumptech.glide.load.resource.bitmap.VideoDecoder$* { *; }
-keep class com.bumptech.glide.load.engine.executor.GlideExecutor { *; }
-keep class com.bumptech.glide.load.engine.executor.GlideExecutor$* { *; }
-keep class com.bumptech.glide.gifdecoder.** { *; }
-keep class com.bumptech.glide.load.resource.drawable.DrawableDecoderCompat { *; }
-keep class com.bumptech.glide.load.model.AssetUriLoader { *; }
-keep class com.bumptech.glide.util.pool.GlideTrace { *; }
-dontwarn com.bumptech.glide.**

# ========================================
# EXOPLAYER / MEDIA3 - VIDEO PLAYBACK (FIX FOR VIDEOS NOT PLAYING)
# ========================================
-keep class androidx.media3.** { *; }
-keep interface androidx.media3.** { *; }
-keepclassmembers class androidx.media3.** { *; }
-keep class androidx.media3.exoplayer.** { *; }
-keep class androidx.media3.common.** { *; }
-keep class androidx.media3.datasource.** { *; }
-keep class androidx.media3.container.** { *; }
-keep class androidx.media3.exoplayer.hls.** { *; }
-keep class androidx.media3.exoplayer.mediacodec.** { *; }
-keep class androidx.media3.exoplayer.analytics.** { *; }
-keep class androidx.media3.exoplayer.drm.** { *; }
-keep class androidx.media3.exoplayer.source.** { *; }
-dontwarn androidx.media3.**

# Legacy ExoPlayer (if used)
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**

# ========================================
# VIDEO PLAYER FLUTTER PLUGIN
# ========================================
-keep class io.flutter.plugins.videoplayer.** { *; }
-keep class io.flutter.plugins.videoplayer.texture.TextureVideoPlayer { *; }
-keep class io.flutter.plugins.videoplayer.texture.TextureVideoPlayer$* { *; }
-keepclassmembers class io.flutter.plugins.videoplayer.** { *; }

# ========================================
# IMAGE PICKER FLUTTER PLUGIN
# ========================================
-keep class io.flutter.plugins.imagepicker.** { *; }
-keep class io.flutter.plugins.imagepicker.ImagePickerDelegate { *; }
-keep class io.flutter.plugins.imagepicker.ImagePickerDelegate$* { *; }
-keepclassmembers class io.flutter.plugins.imagepicker.** { *; }

# ========================================
# PHOTO MANAGER FLUTTER PLUGIN
# ========================================
-keep class com.fluttercandies.photo_manager.** { *; }
-keepclassmembers class com.fluttercandies.photo_manager.** { *; }

# ========================================
# CACHED NETWORK IMAGE
# ========================================
-keep class com.baseflow.** { *; }
-keep class io.flutter.plugins.flutter_cache_manager.** { *; }
-dontwarn com.baseflow.**

# WebRTC (org.webrtc native bindings)
-keep class org.webrtc.** { *; }
-keepclassmembers class org.webrtc.** { *; }
-keepclassmembers class * {
    native <methods>;
}

# Agora SDK (native and reflection usages)
-keep class io.agora.** { *; }
-keep class com.naef.jnlua.** { *; }
-keep class com.facebook.fresco.** { *; }
-keep class com.facebook.imagepipeline.** { *; }

# Keep Pigeon generated bindings and model classes (if present)
-keep class com.kt.doctak.**Pigeon** { *; }
-keep class * implements com.kt.doctak.**.** { *; }

# Firebase / Parcelable / reflection safety
-keepclassmembers class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# Retain annotations and kotlin metadata that some libs rely on
-keep @kotlin.Metadata class * { *; }

# Keep resources that may be referenced via reflection (R8 does not support -keepresources, handled via resource shrinking config)

# Keep entrypoints used via reflection (e.g., plugin registrars)
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.plugin.** { *; }

# General safety rules to avoid removing classes used via reflection
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Do not warn about missing classes in optional libs (quiet R8)
-dontwarn org.webrtc.**
-dontwarn io.agora.**
-dontwarn coil.**
-dontwarn com.facebook.imagepipeline.**

# Allow R8 to optimize but keep required members
-keepattributes Exceptions,InnerClasses,Signature,Deprecated,SourceFile,LineNumberTable,*Annotation*,EnclosingMethod
