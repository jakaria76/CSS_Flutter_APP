plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")

    // 🔔 Firebase (FCM)
    id("com.google.gms.google-services")

    // ✅ Flutter plugin (ALWAYS LAST)
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.css"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.css"

        // 🔴 FCM requires minSdk 21+
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        // ✅ REQUIRED for flutter_local_notifications
        isCoreLibraryDesugaringEnabled = true

        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {

    // ✅ Firebase BOM
    implementation(platform("com.google.firebase:firebase-bom:34.7.0"))

    // 🔔 Firebase Cloud Messaging
    implementation("com.google.firebase:firebase-messaging")

    // ✅ REQUIRED by flutter_local_notifications
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
