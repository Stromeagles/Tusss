/// Stub implementation for non-web platforms.
/// All functions are no-ops so the app compiles on iOS/Android.

bool isFullscreen() => false;

void requestFullscreen() {}

void exitFullscreen() {}

void onFullscreenChange(void Function() callback) {}
