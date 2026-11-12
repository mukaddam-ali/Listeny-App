import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Real release signing, read from a local, gitignored key.properties (see
// android/key.properties.example) — never committed, never hardcoded here.
// A checkout without one can still configure/run non-release tasks (e.g.
// `flutter build apk --debug`); an actual release build fails instead of
// falling back to debug signing — see the signingConfigs/buildTypes/
// task-execution guard below.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasKeystoreProperties = keystorePropertiesFile.exists()
if (hasKeystoreProperties) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.listeny.listeny"
    // permission_handler_android (14.0.0) requires compiling against API 37;
    // flutter.compileSdkVersion (36 on this Flutter release) is too low.
    // Overriding compileSdk is always safe/backward-compatible on its own —
    // it only affects which APIs are visible at compile time, not minSdk or
    // runtime behavior.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.listeny.lite"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
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
        // Always created (never gated on hasKeystoreProperties) so referencing
        // it below never fails *configuration* — that would break every
        // build, including `flutter build apk --debug`, on a checkout
        // without a keystore. Left with placeholder/unset credentials when
        // key.properties is absent; the task-execution guard below is what
        // actually refuses a signing-less release build.
        create("release") {
            if (hasKeystoreProperties) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Real release builds are always signed with the actual release
            // key now — deliberately no debug-signing fallback (unlike
            // earlier): a "release" APK silently signed with the debug key
            // can never actually be distributed/updated through the real
            // signing key, so a checkout without one should fail loudly
            // instead of producing an APK that looks like a real release
            // build but isn't. See the task-execution guard below for where
            // that failure actually happens.
            signingConfig = signingConfigs.getByName("release")
            // Keep audio_service classes unobfuscated (R8 renaming broke the
            // media notification on some devices in release builds).
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

// A real release build (assembleRelease/bundleRelease/...) must be signed
// with the actual release key — never silently fall back to debug signing
// for a distribution build. This check runs at task-EXECUTION time, not
// configuration time, so a checkout without android/key.properties can still
// configure and run `flutter build apk --debug`/other non-release tasks;
// only an actual release-variant task fails, with a clear, actionable error.
tasks.matching { it.name.contains("Release") }.configureEach {
    doFirst {
        if (!hasKeystoreProperties) {
            throw GradleException(
                "Release build requires android/key.properties with real " +
                "release signing credentials (see " +
                "android/key.properties.example) — refusing to silently " +
                "fall back to debug signing for a distribution build."
            )
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

// ffmpeg_kit_flutter_new bundles com.antonkarpenko:ffmpeg-kit-full-gpl by
// default — every codec/filter/x264/libass, none of which
// AudioConversionService uses (it only calls -acodec copy/aac/libmp3lame).
// Swap it for the "audio" variant of the exact same native release, which
// keeps libmp3lame + the built-in aac encoder + stream copy but drops
// libavfilter/libavdevice/libswscale and every video codec.
configurations.all {
    exclude(group = "com.antonkarpenko", module = "ffmpeg-kit-full-gpl")
}

dependencies {
    implementation("com.antonkarpenko:ffmpeg-kit-audio:2.2.1")
}
