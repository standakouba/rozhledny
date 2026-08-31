import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Podpisový klíč pro release. Soubor je v .gitignore a odkazuje na keystore
// mimo repozitář — do gitu se tedy nedostane ani heslo, ani samotný klíč.
//
// Ztráta keystoru je nevratná: Play by aktualizaci podepsanou jiným klíčem
// odmítl a aplikace by musela vzniknout znovu pod jiným názvem balíčku.
val keystoreProperties: Properties? =
    rootProject.file("key.properties").takeIf { it.exists() }?.let { file ->
        Properties().apply { file.inputStream().use { load(it) } }
    }

android {
    namespace = "cz.standakouba.rozhledny"
    // Flutter 3.47 hlásí compileSdk 36, ale některý z pluginů je přeložený
    // proti 37 a Gradle pak build odmítne. Nainstalovaná platforma je stejně
    // android-37, takže je to jen srovnání s realitou.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Název balíčku je po nahrání do Google Play neměnný.
        applicationId = "cz.standakouba.rozhledny"
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
        create("release") {
            val props = keystoreProperties ?: throw GradleException(
                "Chybí android/key.properties — bez něj nejde postavit release. " +
                    "Obnov ho ze zálohy klíče (viz CTI-ME.txt u keystoru).",
            )
            keyAlias = props.getProperty("keyAlias")
            keyPassword = props.getProperty("keyPassword")
            storeFile = file(props.getProperty("storeFile"))
            storePassword = props.getProperty("storePassword")
        }
    }

    buildTypes {
        release {
            // Bez klíče se release nepodepisuje ladicím klíčem, ale build
            // rovnou spadne. Tiché podepsání ladicím klíčem vyrobí balíček,
            // který vypadá hotově, Play ho odmítne až při nahrávání a na
            // telefonu se neprojeví jinak než záhadným
            // INSTALL_FAILED_UPDATE_INCOMPATIBLE.
            signingConfig = signingConfigs.getByName("release")
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
