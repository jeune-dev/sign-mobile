import java.util.Properties
import java.io.FileInputStream

// Priorité 1 : variables d'environnement CI (GitHub Actions, Bitrise, Codemagic…)
// Priorité 2 : key.properties local (dev uniquement — ne pas committer avec de vrais credentials)
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

fun signingProp(envKey: String, propKey: String): String? =
    System.getenv(envKey)?.takeIf { it.isNotBlank() }
        ?: keystoreProperties[propKey]?.toString()?.takeIf { it.isNotBlank() }

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase — Google Services plugin
    id("com.google.gms.google-services")
}

android {
    namespace = "com.signapp.sign_application"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Requis par flutter_local_notifications (utilise les API java.time via desugaring)
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.signapp.sign_application"
        minSdk = flutter.minSdkVersion  // Android 6.0 (Marshmallow) — couvre 99%+ des appareils actifs en 2026
        targetSdk = 35  // Android 15 — obligatoire Play Store à partir d'août 2025
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ✅ D'ABORD signingConfigs
    // En CI : KEYSTORE_ALIAS, KEYSTORE_KEY_PASSWORD, KEYSTORE_FILE, KEYSTORE_STORE_PASSWORD
    // En local : lire depuis key.properties (ne pas committer)
    signingConfigs {
        create("release") {
            keyAlias      = signingProp("KEYSTORE_ALIAS",          "keyAlias")
            keyPassword   = signingProp("KEYSTORE_KEY_PASSWORD",   "keyPassword")
            storePassword = signingProp("KEYSTORE_STORE_PASSWORD", "storePassword")
            val storeFilePath = signingProp("KEYSTORE_FILE", "storeFile")
            storeFile = storeFilePath?.let { file(it) }
        }
    }

    // ✅ ENSUITE buildTypes
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // VULN-C02 : Obfuscation activée en production
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    // Core library desugaring — requis par flutter_local_notifications
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // Firebase BoM — gère automatiquement les versions de tous les SDK Firebase
    // (35.0.0 n'existe pas sur les dépôts Maven/Google ; dernière publiée : 34.15.0)
    implementation(platform("com.google.firebase:firebase-bom:34.15.0"))

    // Firebase Crashlytics — monitoring des crashes en production
    implementation("com.google.firebase:firebase-crashlytics")
}

flutter {
    source = "../.."
}
