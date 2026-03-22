# ── Flutter ────────────────────────────────────────────────────────────────────
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ── Firebase ───────────────────────────────────────────────────────────────────
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# ── Google Sign-In ─────────────────────────────────────────────────────────────
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# ── Kotlin Serialization ──────────────────────────────────────────────────────
-keepattributes *Annotation*
-keepattributes InnerClasses

# ── Google Play Core (Flutter deferred components) ────────────────────────────
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# ── Crashlytics (ilerde eklenirse) ────────────────────────────────────────────
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
