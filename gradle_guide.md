# Flutter Plugin — Android Gradle Configuration Guide

> **Last updated:** August 2026  
> **Stack:** AGP 9.0.1 · KGP 2.2.20 · Gradle 9.x · Java 17 · Flutter (latest stable)

---

## جدول محتوا

1. [ماتریس سازگاری نسخه‌ها](#1-ماتریس-سازگاری-نسخه‌ها)
2. [ساختار فایل‌های Gradle در یک Flutter Plugin](#2-ساختار-فایل‌های-gradle)
3. [الگوی صحیح: plugin library — `android/build.gradle.kts`](#3-plugin-library--androidbuildgradlekts)
4. [الگوی صحیح: example app — `example/android/settings.gradle.kts`](#4-example-app--exampleandroidsettingsgradlekts)
5. [الگوی صحیح: example app — `example/android/app/build.gradle.kts`](#5-example-app--exampleandroidappbuildgradlekts)
6. [چرا KGP در settings هست ولی در app نیست؟](#6-چرا-kgp-در-settings-هست-ولی-در-app-نیست)
7. [خطاهای رایج و راه‌حل آن‌ها](#7-خطاهای-رایج-و-راه‌حل-آن‌ها)
8. [نکات مهم برای کاربران پلاگین](#8-نکات-مهم-برای-کاربران-پلاگین)

---

## 1. ماتریس سازگاری نسخه‌ها

### KGP ↔ AGP ↔ Gradle

| KGP               | Gradle (min–max) | AGP (min–max)   |
|-------------------|------------------|-----------------|
| 2.4.0–2.4.10      | 7.6.3–**9.5.0**  | 8.5.2–**9.1.0** |
| **2.3.20–2.3.21**     | 7.6.3–**9.3.0**  | 8.2.2–**9.0.0** |
| 2.2.20–2.2.21         | 7.6.3–8.14       | 7.3.1–8.11.1    |
| **2.2.20–2.2.21** | 7.6.3–8.14       | 7.3.1–8.11.1    |
| 2.2.0–2.2.10      | 7.6.3–8.14       | 7.3.1–8.10.0    |

> ⚠️ **نکته مهم:** Flutter حداقل نسخه KGP را **2.3.20** تعریف کرده (از Flutter نسخه‌های اخیر).  
> نسخه `2.2.20` هنوز کار می‌کند اما warning می‌دهد و زود deprecated می‌شود.

### Java ↔ Gradle

| Java | حداقل Gradle |
|------|--------------|
| 17   | 7.3          |
| 21   | 8.5          |
| 25   | 9.1.0        |
| 26   | 9.4.0        |

> سیستم فعلی این پروژه: **Java 25.0.2** → نیاز به **Gradle 9.1.0+**

### AGP 9.0 — Built-in Kotlin

از AGP 9.0 به بعد، Kotlin به صورت **built-in** در AGP وجود دارد. این یعنی:

- دیگر نیازی به `apply plugin: 'org.jetbrains.kotlin.android'` در ماژول‌ها **نیست**
- اگر این پلاگین همچنان apply شود، خطای زیر رخ می‌دهد:
  ```
  Cannot add extension with name 'kotlin', as there is an extension already registered
  ```

---

## 2. ساختار فایل‌های Gradle

```
flutter_plugin/
├── android/
│   └── build.gradle.kts          ← تنظیمات ماژول plugin library
│
└── example/
    └── android/
        ├── settings.gradle.kts   ← تعریف نسخه‌ها (KGP, AGP)
        ├── build.gradle.kts      ← تنظیمات root پروژه
        └── app/
            └── build.gradle.kts  ← تنظیمات app ماژول
```

---

## 3. Plugin Library — `android/build.gradle.kts`

این فایل مربوط به ماژول **خود پلاگین** است که توسط Pub منتشر می‌شود.

```kotlin
group = "com.example.flutter_saver"
version = "1.0-SNAPSHOT"

plugins {
    // فقط AGP library — بدون KGP
    // AGP 9.0+ built-in Kotlin را خودش مدیریت می‌کند
    id("com.android.library")
}

android {
    namespace = "com.example.flutter_saver"
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    sourceSets {
        getByName("main") { java.srcDirs("src/main/kotlin") }
        getByName("test") { java.srcDirs("src/test/kotlin") }
    }

    defaultConfig {
        minSdk = 24
    }

    testOptions {
        unitTests {
            isIncludeAndroidResources = true
            all {
                it.useJUnitPlatform()
                it.outputs.upToDateWhen { false }
                it.testLogging {
                    events("passed", "skipped", "failed", "standardOut", "standardError")
                    showStandardStreams = true
                }
            }
        }
    }
}

// ⚠️ ضروری — بدون این، AGP built-in Kotlin از JDK سیستم default می‌گیرد
// مثال: JDK 25 → jvmTarget=24 vs javac target=17 → خطای Inconsistent JVM Target
kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    testImplementation("org.jetbrains.kotlin:kotlin-test")
    testImplementation("org.mockito:mockito-core:5.0.0")
}
```

**چرا KGP اینجا نیست؟**

وقتی کاربر پلاگین را نصب می‌کند، Gradle این فایل را در context پروژه **کاربر** evaluate می‌کند. اگر `buildscript` یا `kotlin-android` اینجا باشد، با AGP 9.0 پروژه کاربر conflict ایجاد می‌کند. AGP 9.0 خودش Kotlin را برای همه library ماژول‌ها فعال می‌کند.

---

## 4. Example App — `example/android/settings.gradle.kts`

```kotlin
pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.0.1" apply false

    // KGP اینجا فقط برای pin کردن نسخه تعریف می‌شود.
    // Flutter Gradle Plugin این نسخه را validation می‌کند.
    // apply false = در هیچ ماژولی به صورت خودکار apply نمی‌شود.
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
}

include(":app")
```

**قانون کلیدی:**
- KGP باید اینجا **declare** شود تا Flutter نسخه را بخواند
- `apply false` اجباری است — AGP 9.0 خودش compilation را مدیریت می‌کند
- حذف این خط → AGP نسخه built-in خودش را load می‌کند (ممکن است زیر حداقل Flutter باشد)

---

## 5. Example App — `example/android/app/build.gradle.kts`

```kotlin
plugins {
    id("com.android.application")
    // ❌ id("org.jetbrains.kotlin.android")  ← این را اضافه نکنید
    // AGP 9.0 built-in Kotlin این کار را انجام می‌دهد
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.flutter_saver_example"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.example.flutter_saver_example"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// این بلاک با built-in Kotlin کاملاً سازگار است
kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
```

---

## 6. چرا KGP در settings هست ولی در app نیست؟

این سوال مهمی است. جواب در نحوه کار AGP 9.0 built-in Kotlin نهفته است:

```
┌─────────────────────────────────────────────────────────────────┐
│                    AGP 9.0 Built-in Kotlin                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  settings.gradle.kts                                           │
│  └── KGP version "2.2.20" apply false                         │
│       │                                                         │
│       ├── Flutter validation ← نسخه را از اینجا می‌خواند      │
│       │                                                         │
│       └── AGP ← نسخه KGP را برای built-in Kotlin استفاده می‌کند│
│                                                                 │
│  app/build.gradle.kts                                          │
│  └── id("com.android.application")  ← AGP apply می‌شود        │
│       └── AGP به صورت خودکار Kotlin support فعال می‌کند       │
│            بدون نیاز به id("org.jetbrains.kotlin.android")     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**خلاصه:** `apply false` یعنی "نسخه را می‌دانم ولی الان apply نکن." AGP خودش در مرحله‌ای دیگر از همین نسخه استفاده می‌کند.

---

## 7. خطاهای رایج و راه‌حل آن‌ها

### خطا ۱ — نسخه Kotlin زیر حداقل Flutter

```
Error: Your project's Kotlin version (X.X.X) is lower than Flutter's minimum supported version of 2.2.20
```

**علت:** KGP در `settings.gradle.kts` تعریف نشده یا نسخه‌اش پایین است.  
**راه‌حل:** اضافه کردن یا آپدیت خط زیر در `settings.gradle.kts`:
```kotlin
id("org.jetbrains.kotlin.android") version "2.2.20" apply false
```

---

### خطا ۲ — Extension تکراری

```
Cannot add extension with name 'kotlin', as there is an extension already registered with that name
```

**علت:** `id("org.jetbrains.kotlin.android")` بدون `apply false` در settings **و** همچنین در `app/build.gradle.kts` apply شده.  
**راه‌حل:** حذف `id("org.jetbrains.kotlin.android")` از `app/build.gradle.kts`.

---

### خطا ۳ — ClassCastException در saveFile

```
java.lang.ClassCastException: java.util.ArrayList cannot be cast to byte[]
```

**علت:** Flutter از طریق MethodChannel، `Uint8List` را به صورت `ArrayList<Int>` می‌فرستد.  
**راه‌حل:**
```kotlin
val rawBytes = call.argument<Any>("bytes")
val bytes: ByteArray? = when (rawBytes) {
    is ByteArray -> rawBytes
    is List<*>   -> ByteArray(rawBytes.size) { i -> (rawBytes[i] as Number).toByte() }
    else         -> null
}
```

---

### خطا ۴ — Skipped frames / main thread

```
I/Choreographer: Skipped 43 frames! The application may be doing too much work on its main thread.
```

**علت:** عملیات I/O روی main thread اجرا می‌شود.  
**راه‌حل:** استفاده از `ExecutorService` برای background thread:
```kotlin
private val ioExecutor = Executors.newSingleThreadExecutor()
private val mainHandler = Handler(Looper.getMainLooper())

ioExecutor.execute {
    val result = doHeavyWork()
    mainHandler.post { flutterResult.success(result) }
}
```

---

### خطا ۵ — Inconsistent JVM Target

```
Inconsistent JVM-target compatibility detected for tasks
'compileDebugJavaWithJavac' (17) and 'compileDebugKotlin' (24).
```

**علت:** وقتی از AGP 9.0 built-in Kotlin بدون تنظیم صریح `jvmTarget` استفاده می‌شود، Kotlin compiler از نسخه JDK در حال اجرا default می‌گیرد. روی JDK 25، این مقدار 24 می‌شود — در حالی که `compileOptions` جاوا روی 17 تنظیم شده.  
**راه‌حل:** اضافه کردن بلاک `kotlin` به `build.gradle.kts` ماژول پلاگین:
```kotlin
kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}
```

---

### خطا ۶ — Incompatible Gradle/Java versions

```
Incompatible Java/Gradle versions. Java Version: 25.0.2, Gradle Version: null
```

**علت:** `flutter analyze --suggestions` نمی‌تواند نسخه Gradle را بخواند (معمولاً مشکل wrapper است).  
**بررسی:** فایل `gradle/wrapper/gradle-wrapper.properties` را چک کنید:
```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-9.1.0-bin.zip
```
Java 25 نیاز به **Gradle 9.1.0** یا بالاتر دارد.

---

## 8. نکات مهم برای کاربران پلاگین

اگر این پلاگین را نصب کرده‌اید، **نیازی به تغییر در Gradle پروژه‌تان ندارید** — به شرطی که:

| شرط | مقدار مورد نیاز |
|-----|----------------|
| AGP | 9.0.0 یا بالاتر |
| KGP | 2.2.20 یا بالاتر |
| Gradle | 9.1.0 یا بالاتر (اگر Java 25 دارید) |
| minSdk | 24 یا بالاتر |

اگر AGP پایین‌تر از 9.0 دارید، پلاگین روی API قدیمی‌تر هم کار می‌کند — چون کد native از `Build.VERSION.SDK_INT` برای انتخاب بین MediaStore و File API استفاده می‌کند.

### پرمیشن‌های لازم

پلاگین پرمیشن‌های زیر را در `AndroidManifest.xml` خودش تعریف کرده:

```xml
<!-- فقط برای Android 9 (API 28) و پایین‌تر -->
<uses-permission
    android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="28" />

<!-- فقط برای Android 12 (API 32) و پایین‌تر -->
<uses-permission
    android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32" />
```

روی **Android 10+ (API 29+)** هیچ پرمیشنی لازم نیست — پلاگین از MediaStore استفاده می‌کند.

---

*Content was rephrased for compliance with licensing restrictions.*  
*Sources: [Android Gradle plugin release notes](https://developer.android.com/build/releases/agp-9-0-0-release-notes) · [Gradle compatibility matrix](https://docs.gradle.org/current/userguide/compatibility.html) · [Kotlin Gradle plugin docs](https://kotlinlang.org/docs/gradle-configure-project.html)*
