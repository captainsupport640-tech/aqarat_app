import java.io.FileInputStream
import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
} else {
    // قراءة البيانات من GitHub Secrets في حالة البناء السحابي
    System.getenv("KEY_ALIAS")?.let { keystoreProperties["keyAlias"] = it }
    System.getenv("KEY_PASSWORD")?.let { keystoreProperties["keyPassword"] = it }
    System.getenv("STORE_PASSWORD")?.let { keystoreProperties["storePassword"] = it }
    System.getenv("STORE_FILE_PATH")?.let { keystoreProperties["storeFile"] = it }
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.captain.aqarat"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) } ?: rootProject.file("upload-keystore.jks")
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    defaultConfig {
        applicationId = "com.captain.aqarat"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode.toInt()
        versionName = flutter.versionName

        multiDexEnabled = true
    }

    buildTypes {
        release {
            // اعتماد التوقيع بناءً على توفر المفتاح وليس على وجود الملف المحلي فقط
            signingConfig = if (keystoreProperties.getProperty("keyAlias") != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }

            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
}