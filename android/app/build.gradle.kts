import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// ── Signing config (release) ──────────────────────────────────────────────────
// Créez android/key.properties avec :
//   storePassword=<mot_de_passe_keystore>
//   keyPassword=<mot_de_passe_cle>
//   keyAlias=noogo
//   storeFile=../noogo-release.jks
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.quickdevit.noogo"
    compileSdk = 36
    ndkVersion = "27.1.12297006"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.quickdevit.noogo"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "app"
    productFlavors {
        create("client") {
            dimension = "app"
            applicationId = "com.quickdevit.noogo"
            resValue("string", "app_name", "Noogo")
        }
        create("driver") {
            dimension = "app"
            applicationId = "com.quickdevit.noogo.driver"
            resValue("string", "app_name", "Noogo Livreur")
        }
        create("waiter") {
            dimension = "app"
            applicationId = "com.quickdevit.noogo.waiter"
            resValue("string", "app_name", "Noogo Serveur")
        }
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug") // fallback dev
            }
            // CI/CD-001 : R8 activé en release — réduit la taille de l'APK/AAB
            // et obfusque le code (noms de classes/méthodes raccourcis).
            // L'obfuscation Dart (--obfuscate) est gérée côté flutter build.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
