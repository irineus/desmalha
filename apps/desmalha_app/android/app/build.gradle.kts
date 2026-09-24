plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.desmalha.desmalha_app"
    // ⚠️ flutter_secure_storage está PINADO na linha 9.x no pubspec porque a
    // 11.x exige compileSdk 37, e o runner do Codemagic não resolve a API 37
    // hoje (Gradle instala "android-37.0" e o AGP procura o hash "android-37"
    // — medido no build 37, 17/ago/2026). Subir o plugin de novo só junto com
    // um compileSdk que o CI comprovadamente resolve.
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Exigido pelo flutter_local_notifications (lembrete do DARF): o AAR
        // do plugin depende de desugaring mesmo com minSdk 26 — ver o README
        // dele, seção "Gradle setup".
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.desmalha.app"
        // minSdk 26 (Android 8.0): exigido por SQLCipher, Keystore de hardware
        // e custo do Argon2id — decisão travada, não rebaixar.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
