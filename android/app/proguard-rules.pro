# ML Kit Text Recognition - keep language models
-keep class com.google.mlkit.vision.text.** { *; }

# Keep all ML Kit internal classes
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**