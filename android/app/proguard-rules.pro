# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# PostgreSQL Driver
-keep class org.postgresql.** { *; }
-dontwarn org.postgresql.**

# HTTP Client
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# Dart VM Service Protocol
-keep class io.flutter.plugin.common.** { *; }

# Image Picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# Connectivity Plus
-keep class dev.fluttercommunity.plus.connectivity.** { *; }

# Android 15 - Edge-to-Edge Display Support
-keep class androidx.core.** { *; }
-keep class androidx.activity.** { *; }
-dontwarn androidx.core.**
-dontwarn androidx.activity.**

# General
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**