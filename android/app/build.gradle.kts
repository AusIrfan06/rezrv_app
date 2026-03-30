import java.util.Properties
import kotlin.io.path.exists
import kotlin.io.resolve
import kotlin.io.use

val localProperties = Properties()
val localPropertiesFile = rootProject.projectDir.resolve("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}

val flutterSdkPath = localProperties.getProperty("flutter.sdk")
    ?: throw GradleException("flutter.sdk not set in local.properties")

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.rezrv.app"
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.rezrv.app"
        minSdk = 24 // <-- Change this from 23 to 24
        targetSdk = 36

        val flutterVersionCode = project.findProperty("flutterVersionCode")?.toString() ?: "1"
        val flutterVersionName = project.findProperty("flutterVersionName")?.toString() ?: "1.0"

        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName
    }


    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}


dependencies {
    // 🟢 Keep these core AndroidX libraries
    implementation("androidx.lifecycle:lifecycle-common-java8:2.8.7")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.7")
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("androidx.core:core-ktx:1.15.0")
}