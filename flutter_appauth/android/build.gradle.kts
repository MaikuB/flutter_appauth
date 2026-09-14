import com.android.build.gradle.LibraryExtension

group = "io.crossingthestreams.flutterappauth"
version = "1.0-SNAPSHOT"

buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:9.0.1")
    }
}

rootProject.allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

apply(plugin = "com.android.library")

configure<LibraryExtension> {
    compileSdk = 35

    namespace = "io.crossingthestreams.flutterappauth"

    defaultConfig {
        minSdk = 24
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }
    lint {
        disable += "InvalidPackage"
    }
}

dependencies {
    "implementation"("net.openid:appauth:0.11.1")
}
