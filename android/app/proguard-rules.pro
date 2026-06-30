# ─── Flutter core ────────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# ─── Flutter / Google Play Core (classes optionnelles — évite les erreurs R8) ─
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# ─── Flutter Secure Storage ──────────────────────────────────────────────────
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# ─── Firebase Crashlytics ────────────────────────────────────────────────────
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
-keep class com.google.firebase.crashlytics.** { *; }
-dontwarn com.google.firebase.crashlytics.**

# ─── Firebase Core ───────────────────────────────────────────────────────────
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# ─── Keep annotations ────────────────────────────────────────────────────────
-keepattributes *Annotation*
-renamesourcefileattribute SourceFile

# ─── Dio / OkHttp ────────────────────────────────────────────────────────────
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }

# ─── Keep enums ──────────────────────────────────────────────────────────────
-keepclassmembers enum * { *; }

# ─── Kotlin ──────────────────────────────────────────────────────────────────
-dontwarn kotlin.**
-keep class kotlin.** { *; }
-keepclassmembers class **$WhenMappings {
    <fields>;
}

# ─── connectivity_plus ───────────────────────────────────────────────────────
-keep class dev.fluttercommunity.plus.connectivity.** { *; }
-dontwarn dev.fluttercommunity.plus.connectivity.**

# ─── permission_handler ──────────────────────────────────────────────────────
-keep class com.baseflow.permissionhandler.** { *; }
-dontwarn com.baseflow.permissionhandler.**

# ─── image_picker ────────────────────────────────────────────────────────────
-keep class io.flutter.plugins.imagepicker.** { *; }
-dontwarn io.flutter.plugins.imagepicker.**

# ─── intl_phone_field / libphonenumber ───────────────────────────────────────
-keep class com.googlecode.libphonenumber.** { *; }
-dontwarn com.googlecode.libphonenumber.**

# ─── path_provider ───────────────────────────────────────────────────────────
-keep class io.flutter.plugins.pathprovider.** { *; }
-dontwarn io.flutter.plugins.pathprovider.**

# ─── shared_preferences ──────────────────────────────────────────────────────
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-dontwarn io.flutter.plugins.sharedpreferences.**

# ─── url_launcher ────────────────────────────────────────────────────────────
-keep class io.flutter.plugins.urllauncher.** { *; }
-dontwarn io.flutter.plugins.urllauncher.**
