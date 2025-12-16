import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

// Load key.properties for signing configuration
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.kt.doctak"
    compileSdk = 36
    ndkVersion = "28.1.13356709"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.kt.doctak"
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
        
        ndk {
            abiFilters += listOf("armeabi-v7a", "arm64-v8a", "x86_64")
        }
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String? ?: ""
            keyPassword = keystoreProperties["keyPassword"] as String? ?: ""
            val storeFilePath = keystoreProperties["storeFile"] as String?
            storeFile = storeFilePath?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String? ?: ""
        }
    }

    buildTypes {
        getByName("debug") {
            isDebuggable = true
            signingConfig = signingConfigs.getByName("debug")
        }
        getByName("release") {
            isDebuggable = false
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("release")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
                "r8-rules.pro",
                "proguard-additions.pro"
            )
            ndk {
                debugSymbolLevel = "FULL"
            }
        }
    }
    
    lint {
        disable += "InvalidPackage"
    }
}

// Task to copy APK to flutter-apk directory
tasks.register<Copy>("copyReleaseApkToFlutterDir") {
    from("${layout.buildDirectory.get()}/app/outputs/apk/release")
    into("${layout.buildDirectory.get()}/app/outputs/flutter-apk")
    include("*.apk")
    rename("(.*)\\.apk", "app-release.apk")
    doFirst {
        file("${layout.buildDirectory.get()}/app/outputs/flutter-apk").mkdirs()
    }
}

afterEvaluate {
    tasks.findByName("assembleRelease")?.finalizedBy("copyReleaseApkToFlutterDir")
}

flutter {
    source = "../.."
}

dependencies {
    // Core library desugaring for Java 8+ APIs on older Android versions
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    
    // Firebase BOM - manages all Firebase and Play Services versions
    implementation(platform("com.google.firebase:firebase-bom:33.10.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-crashlytics")
    implementation("com.google.firebase:firebase-messaging")
    
    // SLF4J to suppress logging warnings
    implementation("org.slf4j:slf4j-simple:2.0.9")
    
    // Install referrer
    implementation("com.android.installreferrer:installreferrer:2.2")
    
    // AndroidX
    implementation("androidx.core:core-ktx:1.15.0")
    implementation("androidx.multidex:multidex:2.0.1")
    implementation("androidx.work:work-runtime-ktx:2.9.1")
}

// Apply callkit manifest patch
apply(from = "../callkit_manifest_patch.gradle")
