import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/config/app_config.dart';
import '../../core/networking/api_client.dart';
import '../../core/networking/ws_service.dart';
import '../../core/responsive/breakpoints.dart';
import '../../providers.dart';
import '../auth/auth_controller.dart';
import '../chat/chat_avatar.dart';
import '../chat/error_text.dart';
import 'theme_mode.dart';

/// Profile, appearance, connection status and sign-out.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).session;
    final mode = ref.watch(themeModeProvider);
    final status = ref.watch(connectionStatusProvider).value ?? ConnectionStatus.disconnected;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(tooltip: 'Back', icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/chats')),
        title: const Text('Settings'),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Breakpoints.maxFormWidth * 1.4),
          child: ListView(padding: const EdgeInsets.symmetric(vertical: Gap.m), children: [
            if (session != null)
              ListTile(
                leading: ChatAvatar(name: session.displayName, radius: 28),
                title: Text(session.displayName, style: text.titleLarge),
                subtitle: Text('@${session.username}'),
                trailing: IconButton(
                  tooltip: 'Edit display name',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _editName(context, ref, session.displayName),
                ),
              ),
            const Divider(height: Gap.xl),
            _Section('Appearance'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gap.m, vertical: Gap.s),
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto), label: Text('System')),
                  ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_outlined), label: Text('Light')),
                  ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_outlined), label: Text('Dark')),
                ],
                selected: {mode},
                onSelectionChanged: (s) => ref.read(themeModeProvider.notifier).select(s.first),
              ),
            ),
            const Divider(height: Gap.xl),
            _Section('Connection'),
            ListTile(
              leading: Icon(switch (status) {
                ConnectionStatus.connected => Icons.cloud_done_outlined,
                ConnectionStatus.connecting => Icons.cloud_sync_outlined,
                ConnectionStatus.disconnected => Icons.cloud_off_outlined,
              }),
              title: Text(switch (status) {
                ConnectionStatus.connected => 'Connected',
                ConnectionStatus.connecting => 'Connecting…',
                ConnectionStatus.disconnected => 'Offline, retrying automatically',
              }),
              subtitle: Text(AppConfig.baseUrl),
            ),
            const Divider(height: Gap.xl),
            _Section('Account'),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign out'),
              subtitle: const Text('Removes the local message cache from this device.'),
              onTap: () => ref.read(authControllerProvider.notifier).logout(),
            ),
            ListTile(
              leading: Icon(Icons.devices_other, color: Theme.of(context).colorScheme.error),
              title: Text('Sign out everywhere', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              subtitle: const Text('Ends your session on every device. Use this if you lost a device.'),
              onTap: () => _signOutEverywhere(context, ref),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _editName(BuildContext context, WidgetRef ref, String current) async {
    final next = await showDialog<String>(context: context, builder: (_) => _NameDialog(initial: current));
    if (next == null || next == current || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(authControllerProvider.notifier).updateDisplayName(next);
      messenger.showSnackBar(const SnackBar(content: Text('Display name updated.')));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(describeError(e))));
    }
  }

  Future<void> _signOutEverywhere(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out everywhere?'),
        content: const Text('Every device signed in to your account, including this one, will be signed out.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign out everywhere')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(authControllerProvider.notifier).logoutAllDevices();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(describeError(e))));
    }
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(Gap.m, 0, Gap.m, Gap.xs),
        child: Semantics(
          header: true,
          child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
        ),
      );
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initial});
  final String initial;
  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final v = _controller.text.trim();
    if (v.isNotEmpty) Navigator.pop(context, v);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Display name'),
        content: TextField(
          controller: _controller,
          autofocus: true,
          maxLength: 50,
          decoration: const InputDecoration(labelText: 'How others see you'),
          onSubmitted: (_) => _save(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: _save, child: const Text('Save')),
        ],
      );
}
