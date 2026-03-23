import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Check if browser is currently in fullscreen mode.
bool isFullscreen() {
  return web.document.fullscreenElement != null;
}

/// Request the browser to enter fullscreen mode.
void requestFullscreen() {
  web.document.documentElement?.requestFullscreen();
}

/// Exit fullscreen mode.
void exitFullscreen() {
  if (web.document.fullscreenElement != null) {
    web.document.exitFullscreen();
  }
}

/// Listen for fullscreen state changes (user pressing Esc, etc.).
void onFullscreenChange(void Function() callback) {
  web.document.addEventListener(
    'fullscreenchange',
    ((web.Event e) { callback(); }).toJS,
  );
}
