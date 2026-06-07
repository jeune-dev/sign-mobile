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
