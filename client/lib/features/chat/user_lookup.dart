import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/networking/api_client.dart';
import '../../providers.dart';

/// Asks for a username, resolves it on the server and returns the user, or null when cancelled / not found.
/// Reports lookup failures itself (snackbar) so callers stay short.
Future<PublicUser?> promptForUser(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  required String actionLabel,
}) async {
  final username = await showDialog<String>(
    context: context,
    builder: (_) => _UsernameDialog(title: title, actionLabel: actionLabel),
  );
  if (username == null || username.isEmpty || !context.mounted) return null;
  final messenger = ScaffoldMessenger.of(context);
  try {
    return await ref.read(apiClientProvider).lookupUser(username);
  } on ApiException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.code == 'not_found' ? 'No user with that name' : e.message)));
  } catch (_) {
    messenger.showSnackBar(const SnackBar(content: Text("Couldn't look that up. Are you online?")));
  }
  return null;
}

/// Owns its TextEditingController, so it is disposed together with the dialog (after the close animation),
/// not while the field is still on screen.
class _UsernameDialog extends StatefulWidget {
  const _UsernameDialog({required this.title, required this.actionLabel});
  final String title;
  final String actionLabel;

  @override
  State<_UsernameDialog> createState() => _UsernameDialogState();
}

class _UsernameDialogState extends State<_UsernameDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.pop(context, _controller.text.trim());

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.title),
        content: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          autocorrect: false,
          decoration: const InputDecoration(labelText: 'Their username'),
          onSubmitted: (_) => _submit(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: _submit, child: Text(widget.actionLabel)),
        ],
      );
}
