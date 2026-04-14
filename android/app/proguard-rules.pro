# ============================================================
# ProGuard / R8 — Noogo Android Release
# Chemin attendu : android/app/proguard-rules.pro
# Référencé depuis build.gradle.kts via :
#   proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
# ============================================================

# ── Flutter ──────────────────────────────────────────────────
# Le moteur Flutter gérant sa propre reflection, on conserve tout
# le code natif Java/Kotlin wrappé par le framework.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# ── Firebase / FCM ───────────────────────────────────────────
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ── Sentry ───────────────────────────────────────────────────
-keep class io.sentry.** { *; }
-dontwarn io.sentry.**

# ── Pusher ───────────────────────────────────────────────────
-keep class com.pusher.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn com.pusher.**

# ── Mobile Scanner (ZXing / camera) ─────────────────────────
-keep class com.google.zxing.** { *; }
-keep class com.journeyapps.barcodescanner.** { *; }
-dontwarn com.journeyapps.barcodescanner.**

# ── Geolocator ───────────────────────────────────────────────
-keep class com.baseflow.geolocator.** { *; }
-dontwarn com.baseflow.geolocator.**

# ── OkHttp (http package) ────────────────────────────────────
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# ── Serialization (Dart→JSON) ────────────────────────────────
# Conserver toutes les classes annotées @JsonSerializable si utilisées
-keepattributes SourceFile,LineNumberTable
-keepattributes RuntimeVisibleAnnotations

# ── Supprime les logs en release ─────────────────────────────
-assumenosideeffects class android.util.Log {
    public static int v(...);
    public static int d(...);
    public static int i(...);
}
