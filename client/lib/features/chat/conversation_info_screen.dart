import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/db/app_database.dart';
import '../../core/responsive/breakpoints.dart';
import '../../providers.dart';
import '../auth/auth_controller.dart';
import '../presence/presence.dart';
import 'chat_avatar.dart';
import 'error_text.dart';
import 'user_lookup.dart';

/// Details of one conversation. A direct chat shows the other person; a group shows its name and members
/// (with presence) and, depending on the caller's role, the management actions. The SERVER enforces who may
/// do what; hiding buttons here is only a courtesy.
class ConversationInfoScreen extends ConsumerWidget {
  const ConversationInfoScreen({super.key, required this.conversationId});
  final String conversationId;

  void _back(BuildContext context) =>
      context.canPop() ? context.pop() : context.go('/chats/c/$conversationId');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authControllerProvider).session?.userId ?? '';
    final conversation = ref.watch(conversationProvider(conversationId));
    final members = ref.watch(membersProvider(conversationId)).value ?? const <MemberRow>[];
    final row = conversation.value;

    if (conversation.hasValue && row == null) {
      // removed or left while this screen was open
      return Scaffold(
        appBar: AppBar(leading: IconButton(tooltip: 'Back', icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/chats'))),
        body: const Center(child: Text("You're no longer part of this conversation.")),
      );
    }

    final isGroup = row?.kind == 'group';
    final iAmOwner = members.any((m) => m.userId == me && m.role == 'owner');
    final sorted = [...members]..sort((a, b) {
        if (a.role == 'owner' && b.role != 'owner') return -1;
        if (b.role == 'owner' && a.role != 'owner') return 1;
        return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
      });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(tooltip: 'Back', icon: const Icon(Icons.arrow_back), onPressed: () => _back(context)),
        title: Text(isGroup ? 'Group info' : 'Contact info'),
      ),
      body: conversation.isLoading && !conversation.hasValue
          ? const Center(child: CircularProgressIndicator())
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: Breakpoints.maxFormWidth * 1.4),
                child: ListView(padding: const EdgeInsets.symmetric(vertical: Gap.m), children: [
                  if (isGroup)
                    _GroupHeader(conversationId: conversationId, title: row?.title ?? '', memberCount: members.length, canRename: iAmOwner)
                  else
                    _ContactHeader(members: members, me: me),
                  const Divider(height: Gap.xl),
                  if (isGroup) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Gap.m),
                      child: Text('${members.length} members', style: Theme.of(context).textTheme.titleSmall),
                    ),
                    if (iAmOwner)
                      ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person_add_alt_1)),
                        title: const Text('Add people'),
                        onTap: () => _addPeople(context, ref),
                      ),
                    for (final m in sorted)
                      _MemberTile(
                        member: m,
                        isMe: m.userId == me,
                        canRemove: iAmOwner && m.userId != me,
                        onRemove: () => _confirmRemove(context, ref, m),
                      ),
                    const Divider(height: Gap.xl),
                    ListTile(
                      leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                      title: Text('Leave group', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      onTap: () => _confirmLeave(context, ref, iAmOwner),
                    ),
                  ],
                ]),
              ),
            ),
    );
  }

  Future<void> _addPeople(BuildContext context, WidgetRef ref) async {
    final user = await promptForUser(context, ref, title: 'Add to group', actionLabel: 'Add');
    if (user == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(chatSyncProvider)!.addMembers(conversationId, [user.id]);
      messenger.showSnackBar(SnackBar(content: Text('${user.displayName} was added.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(describeError(e))));
    }
  }

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref, MemberRow m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove ${m.displayName}?'),
        content: const Text('They will lose access to this group and its messages.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(chatSyncProvider)!.removeMember(conversationId, m.userId);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(describeError(e))));
    }
  }

  Future<void> _confirmLeave(BuildContext context, WidgetRef ref, bool iAmOwner) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave this group?'),
        content: Text(iAmOwner
            ? 'You are the owner. Ownership passes to the member who has been in the group the longest. You will lose access to the messages.'
            : 'You will lose access to the messages.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error, foregroundColor: Theme.of(ctx).colorScheme.onError),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await ref.read(chatSyncProvider)!.leaveConversation(conversationId);
      router.go('/chats');
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(describeError(e))));
    }
  }
}

class _GroupHeader extends ConsumerWidget {
  const _GroupHeader({required this.conversationId, required this.title, required this.memberCount, required this.canRename});
  final String conversationId;
  final String title;
  final int memberCount;
  final bool canRename;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(children: [
        ChatAvatar(name: title, isGroup: true, radius: 40),
        const SizedBox(height: Gap.m),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Flexible(child: Text(title, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center)),
          if (canRename)
            IconButton(tooltip: 'Rename group', icon: const Icon(Icons.edit_outlined), onPressed: () => _rename(context, ref)),
        ]),
        Text('Group · $memberCount members', style: Theme.of(context).textTheme.bodyMedium),
      ]);

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final next = await showDialog<String>(context: context, builder: (_) => _RenameDialog(initial: title));
    if (next == null || next.isEmpty || next == title || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(chatSyncProvider)!.renameGroup(conversationId, next);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(describeError(e))));
    }
  }
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initial});
  final String initial;
  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Rename group'),
        content: TextField(
          controller: _controller,
          autofocus: true,
          maxLength: 100,
          decoration: const InputDecoration(labelText: 'Group name'),
          onSubmitted: (v) => Navigator.pop(context, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, _controller.text.trim()), child: const Text('Save')),
        ],
      );
}

class _ContactHeader extends ConsumerWidget {
  const _ContactHeader({required this.members, required this.me});
  final List<MemberRow> members;
  final String me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peer = members.where((m) => m.userId != me).firstOrNull;
    if (peer == null) return const SizedBox.shrink();
    final presence = ref.watch(peerPresenceProvider(peer.userId));
    return Column(children: [
      ChatAvatar(name: peer.displayName, online: presence?.online, radius: 40),
      const SizedBox(height: Gap.m),
      Text(peer.displayName, style: Theme.of(context).textTheme.headlineSmall),
      Text('@${peer.username}', style: Theme.of(context).textTheme.bodyMedium),
      if (presence != null)
        Padding(
          padding: const EdgeInsets.only(top: Gap.xs),
          child: Text(lastSeenLabel(presence, now: DateTime.now()), style: Theme.of(context).textTheme.bodySmall),
        ),
    ]);
  }
}

class _MemberTile extends ConsumerWidget {
  const _MemberTile({required this.member, required this.isMe, required this.canRemove, required this.onRemove});
  final MemberRow member;
  final bool isMe;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presence = isMe ? null : ref.watch(peerPresenceProvider(member.userId));
    final status = isMe ? 'You' : (presence == null ? '@${member.username}' : lastSeenLabel(presence, now: DateTime.now()));
    final owner = member.role == 'owner';
    // No Semantics override on purpose: ListTile already speaks title + subtitle, and an override that
    // excluded children would hide the "Remove" button from screen readers.
    return ListTile(
      leading: ChatAvatar(name: member.displayName, online: presence?.online),
      title: Text(isMe ? '${member.displayName} (you)' : member.displayName),
      subtitle: Text(status),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (owner)
          Chip(
            label: const Text('Owner'),
            visualDensity: VisualDensity.compact,
            side: BorderSide.none,
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          ),
        if (canRemove)
          IconButton(tooltip: 'Remove ${member.displayName}', icon: const Icon(Icons.person_remove_outlined), onPressed: onRemove),
      ]),
    );
  }
}
