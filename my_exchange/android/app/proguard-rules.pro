# Flutter specific ProGuard rules
# Keep Flutter engine classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep JSON serialization (json_annotation, json_serializable)
-keep class * implements java.io.Serializable { *; }
-keep class **.g.** { *; }
-keep class *.**.g.** { *; }
-keep class *.**.model.** { *; }
-keep class *.**.models.** { *; }

# Keep Retrofit/Dio
-keepattributes Signature
-keepattributes *Annotation*
-keep class retrofit2.** { *; }
-keepclasseswithmembers class * {
    @retrofit2.http.* <methods>;
}
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# Keep Gson / Jackson serialization
-keepattributes *Annotation*, InnerClasses
-keep class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep Kotlin coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}

# Prevent R8 from leaving Data object members always null
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep custom entity and model classes
-keep class dev.sm1le.myexchange.** { *; }

# Flutter Play Store deferred components
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
-keep class com.google.android.play.core.** { *; }

# Keep getters and setters for serialization
-keepclassmembers class * {
    *** get*();
    void set*(***);
}
