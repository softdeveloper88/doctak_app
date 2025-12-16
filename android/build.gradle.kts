allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Define extension variables
val kotlinVersion by extra { "2.2.0" }
val compileSdkVersion by extra { 36 }
val targetSdkVersion by extra { 36 }
val minSdkVersion by extra { 24 }

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    
    // Force compileSdk and NDK version for all subprojects
    afterEvaluate {
        if (extensions.findByName("android") != null) {
            extensions.configure<com.android.build.gradle.BaseExtension>("android") {
                ndkVersion = "28.1.13356709"
                compileSdkVersion(36)
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
    
    // Force compatible dependency versions for AGP 8.3.1
    configurations.all {
        resolutionStrategy {
            // Force older versions that are compatible with AGP 8.3.1
            force("androidx.browser:browser:1.8.0")
            force("androidx.core:core:1.13.1")
            force("androidx.core:core-ktx:1.13.1")
            force("androidx.activity:activity:1.9.3")
            force("androidx.activity:activity-ktx:1.9.3")
            force("androidx.fragment:fragment:1.8.5")
            force("androidx.fragment:fragment-ktx:1.8.5")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
