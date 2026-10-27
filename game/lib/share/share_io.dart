import 'dart:io';

import 'package:flutter/services.dart';

const _channel = MethodChannel('relivable/updater');

/// Returns a short message for the player, or null when nothing happened.
Future<String?> shareImage(Uint8List png, String name, String text) async {
  if (Platform.isAndroid || Platform.isIOS) {
    try {
      final r = await _channel.invokeMethod<String>('shareImage', {
        'bytes': png,
        'name': name,
        'text': text,
      });
      return switch (r) {
        'shared' => null,
        'error' => 'Could not open the share sheet. Copy it as text instead.',
        _ => 'Saved to your gallery.',
      };
    } on PlatformException {
      return 'Sharing is not available on this phone.';
    } on MissingPluginException {
      return 'Sharing needs the latest version of the app.';
    }
  }
  final home =
      Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
  if (home == null) return 'Could not find your Downloads folder.';
  final dir = Directory('$home${Platform.pathSeparator}Downloads');
  if (!dir.existsSync()) dir.createSync(recursive: true);
  final file = File('${dir.path}${Platform.pathSeparator}$name');
  await file.writeAsBytes(png);
  return 'Saved to Downloads as $name.';
}
