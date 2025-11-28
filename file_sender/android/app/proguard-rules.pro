# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# TensorFlow Lite rules
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-keep class org.tensorflow.lite.gpu.GpuDelegateFactory$Options { *; }
-keep class org.tensorflow.lite.gpu.GpuDelegate { *; }
-keep class org.tensorflow.lite.gpu.GpuDelegateFactory { *; }

# Keep all TensorFlow Lite native methods
-keepclasseswithmembernames class org.tensorflow.lite.** {
    native <methods>;
}

# Keep TensorFlow Lite interpreter
-keep class org.tensorflow.lite.Interpreter { *; }
-keep class org.tensorflow.lite.Interpreter$Options { *; }

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep TensorFlow Lite model classes
-keep class * extends org.tensorflow.lite.support.model.BaseModel { *; }
-keep class * extends org.tensorflow.lite.Interpreter { *; }

# Keep camera related classes
-keep class androidx.camera.** { *; }
-keep class androidx.camera.core.** { *; }
-keep class androidx.camera.lifecycle.** { *; }
-keep class androidx.camera.view.** { *; }

# Keep ML Kit classes
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_common.** { *; }

# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep Flutter related classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep face detection classes
-keep class com.google.mlkit.vision.face.** { *; }
-keep class com.google.android.gms.vision.** { *; }

# Keep image processing classes
-keep class androidx.camera.core.ImageProxy { *; }
-keep class androidx.camera.core.ImageInfo { *; }

# Keep all classes with @Keep annotation
-keep @androidx.annotation.Keep class * { *; }
-keepclassmembers class * {
    @androidx.annotation.Keep *;
}

# Keep all classes in the app package
-keep class com.example.file_sender.** { *; }

# Disable R8 for TensorFlow Lite GPU delegate
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options
-keep class org.tensorflow.lite.gpu.GpuDelegateFactory$Options { *; }

# Additional TensorFlow Lite GPU rules
-keep class org.tensorflow.lite.gpu.GpuDelegateFactory { *; }
-keep class org.tensorflow.lite.gpu.GpuDelegateFactory$Options { *; }
-keep class org.tensorflow.lite.gpu.GpuDelegate { *; }