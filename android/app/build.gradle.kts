plugins {
    id("com.android.application")
    id("com.google.gms.google-services") // Firebase
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.smart_task_app"
    compileSdk = 34
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17" 
    }

    defaultConfig {
        applicationId = "com.example.smart_task_app"
        minSdk = 23
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// ✅ `dependencies {}` MUST be outside `android {}`
dependencies {
    implementation("com.android.tools:desugar_jdk_libs:2.0.3") 
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")

    /* implementation(project(":flutter_barcode_scanner")) {
        exclude(group = "com.amolg", module = "flutterbarcodescanner") // ✅ Correct syntax
    } */
}

// ✅ Ensure your `allprojects {}` block exists in `android/build.gradle.kts`
allprojects {
    repositories {
        google()
        mavenCentral()
        
    }
}


