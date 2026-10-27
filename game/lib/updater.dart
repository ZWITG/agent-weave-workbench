import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

/// Phone auto-update. CI stamps each Android build with its run number and
/// signing-key fingerprint, and publishes Relivable.apk + version.json to the
/// rolling "relivable-latest" GitHub release. On launch the app reads
/// version.json; if a newer build exists it offers a one-tap update that
/// downloads the APK and opens Android's installer.

const appBuild = int.fromEnvironment('RELIVABLE_BUILD');
const appCert = String.fromEnvironment('RELIVABLE_CERT');
const appVersion = appBuild > 0 ? '0.1.$appBuild' : 'dev';

const _feed =
    'https://github.com/ZWITG/agent-weave-workbench/releases/download/'
    'relivable-latest/version.json';

const _channel = MethodChannel('relivable/updater');

/// Only release APKs built by CI can update themselves. The web version is
/// always the latest already.
bool get updatesSupported =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android && appBuild > 0;

class UpdateInfo {
  UpdateInfo({
    required this.build,
    required this.version,
    required this.apk,
    required this.notes,
    required this.sameKey,
  });

  final int build;
  final String version;
  final String apk;
  final String notes;

  /// False when the new build is signed with a different key, so Android
  /// will refuse to install it over this one.
  final bool sameKey;
}

/// Returns the newer build, or null when up to date, offline or unsupported.
Future<UpdateInfo?> checkForUpdate() async {
  if (!updatesSupported) return null;
  try {
    final r = await http
        .get(Uri.parse(_feed))
        .timeout(const Duration(seconds: 10));
    if (r.statusCode != 200) return null;
    final j = jsonDecode(r.body) as Map<String, dynamic>;
    final build = j['build'] as int;
    if (build <= appBuild) return null;
    final cert = j['cert'] as String? ?? '';
    return UpdateInfo(
      build: build,
      version: j['version'] as String? ?? '0.1.$build',
      apk: j['apk'] as String,
      notes: j['notes'] as String? ?? '',
      sameKey: appCert.isEmpty || cert.isEmpty || cert == appCert,
    );
  } catch (_) {
    return null; // Offline or the feed is unreachable: try next launch.
  }
}

/// 'started', 'needs_permission' (Android settings were opened so the
/// player can allow installs from Relivable) or 'error'.
Future<String> installUpdate(UpdateInfo u) async {
  try {
    return await _channel.invokeMethod<String>('downloadAndInstall', {
          'url': u.apk,
          'version': u.version,
        }) ??
        'error';
  } catch (_) {
    return 'error';
  }
}

Future<void> openInBrowser(String url) async {
  try {
    await _channel.invokeMethod('openUrl', {'url': url});
  } catch (_) {}
}
