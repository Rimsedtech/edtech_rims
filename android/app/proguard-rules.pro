## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

## Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

## JsonSerializable / Serialization
## Note: Dart-level serialization is not affected by R8. 
## These rules are for any native Java/Kotlin models if they exist.
-keepclassmembers class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

## Keep line numbers for Crashlytics
-keepattributes SourceFile,LineNumberTable
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
