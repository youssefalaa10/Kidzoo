# Flutter Wrapper ProGuard rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Flutter deferred components / Play Core (not used, suppress R8 warnings)
-dontwarn com.google.android.play.core.**

# flutter_local_notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# flutter_tts
-keep class com.eyedeadevelopment.fluttertts.** { *; }
-keep class com.tundralabs.fluttertts.** { *; }

# audioplayers
-keep class xyz.luan.audioplayers.** { *; }

# Drift & SQLite3
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod
-dontwarn androidx.room.paging.**
-keep class * extends androidx.room.RoomDatabase

# General keep for desugaring and reflection
-dontwarn java.time.**
-dontwarn java.util.concurrent.**
