import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Lê android/key.properties, se existir (nunca commitado — ver .gitignore).
// Sem esse arquivo, o release continua assinado com a chave de debug (mesmo
// comportamento de antes), então o build nunca quebra por falta dele.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val temKeystoreReal = keystorePropertiesFile.exists()
if (temKeystoreReal) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

android {
    namespace = "com.dalehapp.daleh"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // applicationId DEFINITIVO da versão Android do DALEH — não trocar
        // depois de publicado na Play Store.
        applicationId = "com.dalehapp.daleh"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (temKeystoreReal) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Usa a assinatura de release real quando key.properties existir;
            // continua caindo pra chave de debug enquanto não existir (é
            // exatamente o estado atual, nada muda até a keystore ser criada).
            signingConfig = if (temKeystoreReal) signingConfigs.getByName("release") else signingConfigs.getByName("debug")
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
