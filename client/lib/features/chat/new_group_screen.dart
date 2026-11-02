import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/networking/api_client.dart';
import '../../core/responsive/breakpoints.dart';
import '../../providers.dart';
import '../auth/auth_controller.dart';
import 'error_text.dart';
import 'user_lookup.dart';

/// Create a group: a title plus at least one other person (found by username). The creator becomes the owner.
class NewGroupScreen extends ConsumerStatefulWidget {
  const NewGroupScreen({super.key});

  @override
  ConsumerState<NewGroupScreen> createState() => _NewGroupScreenState();
}

class _NewGroupScreenState extends ConsumerState<NewGroupScreen> {
  final _title = TextEditingController();
  final _members = <PublicUser>[];
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  bool get _canCreate => !_busy && _title.text.trim().isNotEmpty && _members.isNotEmpty;

  Future<void> _addPerson() async {
    final me = ref.read(authControllerProvider).session?.userId;
    final user = await promptForUser(context, ref, title: 'Add a person', actionLabel: 'Add');
    if (user == null || !mounted) return;
    if (user.id == me) {
      _toast("You're already in the group.");
    } else if (_members.any((m) => m.id == user.id)) {
      _toast('${user.displayName} is already added.');
    } else {
      setState(() => _members.add(user));
    }
  }

  void _toast(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _create() async {
    setState(() => _busy = true);
    final router = GoRouter.of(context);
    try {
      final id = await ref.read(chatSyncProvider)!.createGroup(_title.text.trim(), [for (final m in _members) m.id]);
      router.go('/chats/c/$id');
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        _toast(describeError(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: IconButton(tooltip: 'Back', icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/chats')),
          title: const Text('New group'),
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Breakpoints.maxFormWidth * 1.4),
            child: ListView(padding: const EdgeInsets.all(Gap.m), children: [
              TextField(
                controller: _title,
                autofocus: true,
                maxLength: 100,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Group name'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: Gap.s),
              Text('People (${_members.length})', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: Gap.s),
              Wrap(spacing: Gap.s, runSpacing: Gap.s, children: [
                for (final m in _members)
                  InputChip(
                    label: Text(m.displayName),
                    tooltip: '@${m.username}',
                    deleteButtonTooltipMessage: 'Remove ${m.displayName}',
                    onDeleted: _busy ? null : () => setState(() => _members.remove(m)),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.person_add_alt_1, size: 18),
                  label: const Text('Add person'),
                  onPressed: _busy ? null : _addPerson,
                ),
              ]),
              if (_members.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: Gap.s),
                  child: Text('Add at least one other person. You can add more later.', style: Theme.of(context).textTheme.bodySmall),
                ),
              const SizedBox(height: Gap.l),
              FilledButton.icon(
                onPressed: _canCreate ? _create : null,
                icon: _busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check),
                label: const Text('Create group'),
              ),
            ]),
          ),
        ),
      );
}
