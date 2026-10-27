// Saving or sharing a Life Recap card image: the web version downloads a
// PNG, Windows and desktop save it to Downloads, Android saves it to the
// gallery and opens the share sheet.
export 'share_io.dart' if (dart.library.js_interop) 'share_web.dart';
