buildscript {
    val kotlinVersion = "2.1.10" // Use Kotlin 2.1.10
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.9.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Set custom build directory
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

// Set custom build directory for subprojects
subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}

// Ensure subprojects depend on the app module
subprojects {
    project.evaluationDependsOn(":app")
}

// Custom clean task to delete the custom build directory
tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}

// Configure Kotlin options
tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
    kotlinOptions {
        jvmTarget = "1.8"
        apiVersion = "2.1" // Match this with your Kotlin version
        languageVersion = "2.1" // Match this with your Kotlin version
    }
}