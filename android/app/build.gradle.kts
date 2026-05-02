import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    id("com.google.firebase.firebase-perf")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { input ->
        keystoreProperties.load(input)
    }
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.1.2"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-crashlytics")
    implementation("com.google.firebase:firebase-perf")
}

android {
    namespace = "com.bitwiseacademy.bitwise_academy"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.bitwiseacademy.bitwise_academy"
        minSdk = flutter.minSdkVersion
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            // Strictly enforce release signing. If key.properties is missing or incomplete, the build fails.
            if (!keystorePropertiesFile.exists()) {
                throw GradleException("Signing configuration 'key.properties' not found at ${keystorePropertiesFile.absolutePath}. Release builds must be signed with a production key.")
            }

            val alias = keystoreProperties["keyAlias"] as? String
            val password = keystoreProperties["keyPassword"] as? String
            val store = keystoreProperties["storeFile"] as? String
            val pass = keystoreProperties["storePassword"] as? String

            if (alias.isNullOrBlank() || password.isNullOrBlank() || store.isNullOrBlank() || pass.isNullOrBlank()) {
                throw GradleException("One or more signing properties (keyAlias, keyPassword, storeFile, storePassword) are missing or empty in key.properties.")
            }

            keyAlias = alias
            keyPassword = password
            storeFile = project.file(store)
            storePassword = pass
        }
    }

    androidResources {
        // Prevent AAPT from compressing pixel art assets to preserve the Neo-Arcade aesthetic.
        noCompress("png", "jpg", "jpeg", "gif", "webp")
    }

    buildTypes {
        release {
            // Enable R8 code shrinking, obfuscation, and optimization.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            // Use the strictly enforced release signing configuration.
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
