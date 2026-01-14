# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Gson (used by flutter_local_notifications)
-keep class com.google.gson.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }

# AndroidX & Support Library
-keep class androidx.lifecycle.** { *; }
-keep class androidx.core.app.** { *; }

# Prevent ProGuard from stripping standard Java types used in reflection
-keep class java.lang.** { *; }
-keep class java.util.** { *; }

# Ignore Play Store warnings
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
