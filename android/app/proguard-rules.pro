# Add project specific ProGuard rules here.
# By default, the flags in this file are appended to flags specified
# in flutter.gradle (android/app/build.gradle)

# Flutter wrapper rules (already included in flutter.gradle)
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**    { *; }
-keep class io.flutter.view.**    { *; }
-keep class io.flutter.**         { *; }
-keep class io.flutter.plugins.** { *; }

# Your own rules if needed (e.g. for Firebase, Google Maps, etc.)
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**