import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme.dart';
import '../updater.dart';
import 'widgets.dart';

/// Checks for a newer phone build when the app opens or comes back to the
/// foreground (at most once an hour) and offers a one-tap update.
class UpdateGate extends StatefulWidget {
  const UpdateGate({super.key, required this.child});
  final Widget child;

  @override
  State<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends State<UpdateGate> with WidgetsBindingObserver {
  DateTime? _lastCheck;
  int _dismissed = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    if (!updatesSupported) return;
    final now = DateTime.now();
    if (_lastCheck != null && now.difference(_lastCheck!).inMinutes < 60) {
      return;
    }
    _lastCheck = now;
    final u = await checkForUpdate();
    if (u == null || u.build <= _dismissed || !mounted) return;
    final later = !await showUpdatePrompt(context, u);
    if (later) _dismissed = u.build;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// The update pop-up. Returns true if the player chose to update.
Future<bool> showUpdatePrompt(BuildContext context, UpdateInfo u) async {
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: NF.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      icon: const Icon(Icons.system_update_rounded, color: NF.blue, size: 34),
      title: Text(
        'A new version is ready',
        style: NF.sora(19, weight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Relivable ${u.version} (you have $appVersion).',
            style: NF.sora(14, color: NF.soft),
          ),
          if (u.notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(u.notes, style: NF.sora(14)),
          ],
          const SizedBox(height: 10),
          Text(
            u.sameKey
                ? 'Your life and settings are kept.'
                : 'This version was signed differently, so Android needs a '
                      'fresh install: uninstall Relivable, then open the '
                      'download. Your current life will not carry over.',
            style: NF.sora(13, color: u.sameKey ? NF.muted : NF.orange),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Later'),
        ),
        FilledButton(
          style: primaryButton(),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(u.sameKey ? 'Update now' : 'Download'),
        ),
      ],
    ),
  );
  if (go != true) return false;
  if (!u.sameKey) {
    await openInBrowser(u.apk);
    return true;
  }
  final status = await installUpdate(u);
  if (!context.mounted) return true;
  final msg = switch (status) {
    'started' => 'Downloading the update. Android will ask you to install it when it is ready.',
    'store' => 'Tap Update next to Relivable. Your life and settings are kept.',
    'browser' =>
      'Download Relivable.ipa and install it with AltStore, SideStore or '
          'Sideloadly. Your life and settings are kept.',
    'needs_permission' =>
      'Allow Relivable to install apps on the screen that just opened, then '
          'come back and tap Update now again.',
    _ => 'The update could not start. Check your connection and try again.',
  };
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: NF.surface,
      content: Text(msg, style: NF.sora(15)),
      actions: [
        FilledButton(
          style: primaryButton(),
          onPressed: () => Navigator.pop(ctx),
          child: const Text('OK'),
        ),
      ],
    ),
  );
  return status == 'started' || status == 'store';
}

/// Me tab card: version and a manual "Check for updates".
class VersionCard extends StatefulWidget {
  const VersionCard({super.key});

  @override
  State<VersionCard> createState() => _VersionCardState();
}

class _VersionCardState extends State<VersionCard> {
  bool _checking = false;
  String? _status;

  Future<void> _checkNow() async {
    setState(() {
      _checking = true;
      _status = null;
    });
    final u = await checkForUpdate();
    if (!mounted) return;
    setState(() {
      _checking = false;
      _status = u == null ? 'You have the latest version.' : null;
    });
    if (u != null) await showUpdatePrompt(context, u);
  }

  @override
  Widget build(BuildContext context) {
    final sub = kIsWeb
        ? 'Web version · always up to date'
        : updatesSupported
        ? (_status ??
              (defaultTargetPlatform == TargetPlatform.iOS
                  ? 'AltStore or SideStore keeps it updated'
                  : 'Updates arrive automatically when you open the game'))
        : 'Development build';
    return Material(
      color: NF.surface,
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        leading: const Icon(Icons.system_update_rounded, color: NF.blue),
        title: Text(
          'Relivable $appVersion',
          style: NF.sora(15, weight: FontWeight.w600),
        ),
        subtitle: Text(sub, style: NF.sora(12, color: NF.muted)),
        trailing: updatesSupported
            ? (_checking
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : TextButton(
                      onPressed: _checkNow,
                      child: const Text('Check'),
                    ))
            : null,
      ),
    );
  }
}
