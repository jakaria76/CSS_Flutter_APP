plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")

    // Firebase / Google Services
    id("com.google.gms.google-services")

    // Flutter plugin (MUST be last)
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.css"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.css"

        // Firebase + modern plugins require 21+
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        // Required for flutter_local_notifications & Java 8+ APIs
        isCoreLibraryDesugaringEnabled = true

        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        release {
            // DEBUG signing for now (OK for testing)
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {

    // Firebase BOM (keeps versions aligned)
    implementation(platform("com.google.firebase:firebase-bom:34.7.0"))

    // Firebase Cloud Messaging
    implementation("com.google.firebase:firebase-messaging")

    // Required by flutter_local_notifications
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
