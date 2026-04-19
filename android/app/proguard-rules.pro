# Regras de Blindagem Proguard SOMAX

# Flutter Core
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# Audio Service & Media
-keep class com.ryanheise.audioservice.** { *; }
-keep class com.ryanheise.audioservice.AudioService { *; }
-keep class com.ryanheise.audioservice.AudioServiceActivity { *; }
-dontwarn com.ryanheise.audioservice.**

# Video Player & ExoPlayer (Garantir que os codecs e o buffering fiquem)
-keep class com.google.android.exoplayer2.** { *; }
-keep interface com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**
-keep class androidx.media3.** { *; }
-dontwarn androidx.media3.**

# Keep para interfaces de hardware e vídeo do Flutter
-keep class io.flutter.embedding.engine.renderer.** { *; }
-keep class io.flutter.view.** { *; }

# Cached Network Image & OkHttp
-keep class com.baseflow.cachednetworkimage.** { *; }
-keep class okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn com.baseflow.cachednetworkimage.**

# Firebase & Play Core
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
-dontwarn com.google.firebase.**
-dontwarn com.google.android.play.core.**

# Tratar erros de classes faltantes comuns no Flutter
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Atributos vitais para reflexão
-keepattributes Signature, *Annotation*, EnclosingMethod, InnerClasses, SourceFile, LineNumberTable

# OTA Update Plugin (Blindagem contra crash em Release)
-keep class sk.fourq.otaupdate.** { *; }
-dontwarn sk.fourq.otaupdate.**
