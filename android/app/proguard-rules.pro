# =============================================================================
# FlaCore ProGuard / R8 Rules for Release APK
# Prevents R8 from stripping audio_service and AndroidX media classes
# that are required for Media Notification / Lock Screen Controls.
# =============================================================================

# Keep audio_service native Android classes (MediaBrowserService, AudioService)
-keep class com.ryanheise.audioservice.** { *; }

# Keep AndroidX media compat classes used by audio_service
-keep class androidx.media.** { *; }

# Keep the app's own MainActivity (extends AudioServiceActivity)
-keep class com.flacore.flacore.MainActivity { *; }
