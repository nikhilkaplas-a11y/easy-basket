plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.easy_basket"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Change to your unique Application ID before publishing to Play Store
        // Format: com.yourcompany.appname (e.g., com.easybasket.app)
        applicationId = "com.easybasket.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // Keystore file path (relative to android/app/)
            val keystoreFile = file("../easy-basket-key.jks")
            if (keystoreFile.exists()) {
                storeFile = keystoreFile
                // Use environment variables for passwords (more secure)
                storePassword = System.getenv("KEYSTORE_PASSWORD") ?: ""
                keyAlias = "easy-basket-key"
                keyPassword = System.getenv("KEY_PASSWORD") ?: ""
            }
        }
    }

    buildTypes {
        release {
            // Use release signing config if keystore exists, otherwise use debug (for testing)
            val keystoreFile = file("../easy-basket-key.jks")
            if (keystoreFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                // Fallback to debug signing (remove this before production!)
                signingConfig = signingConfigs.getByName("debug")
            }
            // Disable minification for testing APK (enable for Play Store)
            isMinifyEnabled = false
            isShrinkResources = false
            // proguardFiles(
            //     getDefaultProguardFile("proguard-android-optimize.txt"),
            //     "proguard-rules.pro"
            // )
        }
    }
}

flutter {
    source = "../.."
}
