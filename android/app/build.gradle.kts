plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.ind.score2new.stream"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.ind.score2new.stream"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Chỉ dùng khi chạy trên máy ảo:
        //
        //     flutter run -Pemu=true
        //     flutter build apk --debug -Pemu=true
        //
        // `abiFilters.clear()` là bắt buộc — plugin Flutter đã điền sẵn cả ba
        // ABI vào đó, chỉ `+=` thì chúng vẫn còn nguyên và lọc thành vô nghĩa.
        //
        // Vì sao cần: các SDK quảng cáo (Vungle `libnms.so`, Pangle
        // `libtt_ugen_layout.so`, `libapminsight*`, `libpglarmor.so`…) **không
        // có bản x86_64** — chỉ arm64-v8a và armeabi-v7a. Nên APK gộp có 10 thư
        // viện cho arm64 nhưng chỉ 4 cho x86_64.
        //
        // PackageManager chọn ABI theo số thư viện khớp được nhiều nhất, nên
        // LDPlayer (hỗ trợ cả x86_64 lẫn arm64 qua lớp dịch) chọn **arm64** rồi
        // chạy toàn bộ tiến trình dưới lớp dịch ARM. Ở đó `libdartjni.so` không
        // `dlopen` được → Cronet chết → Sofascore trả 403 vì request rơi xuống
        // `dart:io`, và `path_provider` cũng hỏng kéo theo mất ảnh.
        //
        // `--target-platform android-x64` không cứu được vì nó chỉ giới hạn
        // engine Flutter, thư viện của SDK quảng cáo vẫn còn nguyên. Phải lọc ở
        // tầng NDK thì mới bỏ hẳn nhánh arm.
        if (project.hasProperty("emu")) {
            ndk {
                abiFilters.clear()
                abiFilters += "x86_64"
            }
        }
    }

    // Từ AGP 3.6 mặc định là `false`: file .so nằm nguyên trong APK, không giải
    // nén ra `/data/app/.../lib/arm64`. Java `System.loadLibrary` đọc được kiểu
    // đó, nhưng `DynamicLibrary.open("libdartjni.so")` của Dart FFI thì không —
    // nó gọi `dlopen` và `dlopen` chỉ tìm trong thư mục lib đã giải nén.
    //
    // Hệ quả khi để mặc định: gói `jni` (đi kèm cronet qua native_dio_adapter)
    // không nạp được, và MỌI request HTTP chết với
    // "Failed to load dynamic library at path: libdartjni.so".
    //
    // Bật lại kiểu đóng gói cũ để .so được giải nén lúc cài. Đổi lại APK to hơn
    // một chút, nhưng đó là cái giá để mạng chạy.
    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
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
    // flutter_local_notifications cần desugar cho java.time khi minSdk < 34.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // ---- Mediation ----
    // Đúng 10 mạng của bản Kotlin (`libs.versions.toml`). Phiên bản lấy bản mới
    // nhất trên Google Maven vì `google_mobile_ads` 9.1.0 kéo
    // play-services-ads 25.4.0 — ghép adapter cũ với SDK mới rủi ro hơn.
    // Adapter chỉ là cầu nối: mỗi mạng vẫn phải bật trong AdMob Console
    // (Mediation group → Ad sources) thì mới thật sự có request.
    implementation("com.google.ads.mediation:applovin:13.6.4.1")
    implementation("com.google.ads.mediation:ironsource:9.6.0.0")
    implementation("com.google.ads.mediation:vungle:7.7.8.0")
    implementation("com.google.ads.mediation:facebook:6.22.0.1")
    implementation("com.google.ads.mediation:mintegral:17.1.81.0")
    implementation("com.google.ads.mediation:pangle:8.3.0.3.0")
    implementation("com.google.ads.mediation:unity:4.20.0.2")
    implementation("com.google.ads.mediation:moloco:4.12.0.0")
    implementation("com.google.ads.mediation:fyber:8.4.7.0")
    implementation("com.google.ads.mediation:bigo:6.0.0.0")
}
