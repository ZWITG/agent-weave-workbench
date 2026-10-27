import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

/// Phone auto-update. CI stamps each Android build with its run number and
/// signing-key fingerprint, and publishes Relivable.apk + version.json to the
/// rolling "relivable-latest" GitHub release. On launch the app reads
/// version.json; if a newer build exists it offers a one-tap update that
/// downloads the APK and opens Android's installer.
///
/// iPhones read version-ios.json instead. iOS only lets the App Store,
/// TestFlight or a sideloading store replace an app, so the IPA is listed
/// in an AltStore/SideStore source (altstore.json) that checks for updates
/// by itself, and "Update now" opens that store on the new version.

const appBuild = int.fromEnvironment('RELIVABLE_BUILD');
const appCert = String.fromEnvironment('RELIVABLE_CERT');
const appVersion = appBuild > 0 ? '0.1.$appBuild' : 'dev';

const _release =
    'https://github.com/ZWITG/agent-weave-workbench/releases/download/'
    'relivable-latest';
const releasePage =
    'https://github.com/ZWITG/agent-weave-workbench/releases/tag/'
    'relivable-latest';
const altSource = '$_release/altstore.json';

bool get _isIos => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

const _channel = MethodChannel('relivable/updater');

/// Only release APKs built by CI can update themselves. The web version is
/// always the latest already.
bool get updatesSupported =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android || _isIos) &&
    appBuild > 0;

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
        .get(Uri.parse('$_release/${_isIos ? 'version-ios' : 'version'}.json'))
        .timeout(const Duration(seconds: 10));
    if (r.statusCode != 200) return null;
    final j = jsonDecode(r.body) as Map<String, dynamic>;
    final build = j['build'] as int;
    if (build <= appBuild) return null;
    final cert = j['cert'] as String? ?? '';
    return UpdateInfo(
      build: build,
      version: j['version'] as String? ?? '0.1.$build',
      apk: (j['apk'] ?? j['ipa']) as String,
      notes: j['notes'] as String? ?? '',
      sameKey: _isIos || appCert.isEmpty || cert.isEmpty || cert == appCert,
    );
  } catch (_) {
    return null; // Offline or the feed is unreachable: try next launch.
  }
}

/// 'started', 'needs_permission' (Android settings were opened so the
/// player can allow installs from Relivable), 'store' (AltStore or
/// SideStore opened on iPhone), 'browser' or 'error'.
Future<String> installUpdate(UpdateInfo u) async {
  if (_isIos) {
    final src = Uri.encodeComponent(altSource);
    for (final store in ['altstore', 'sidestore']) {
      if (await _open('$store://source?url=$src') == 'opened') return 'store';
    }
    return await _open(releasePage) == 'opened' ? 'browser' : 'error';
  }
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

Future<void> openInBrowser(String url) => _open(url);

Future<String> _open(String url) async {
  try {
    return await _channel.invokeMethod<String>('openUrl', {'url': url}) ??
        'opened';
  } catch (_) {
    return 'error';
  }
}
