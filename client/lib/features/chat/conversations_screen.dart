import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../core/db/app_database.dart';
import '../../providers.dart';
import '../presence/presence.dart';
import 'chat_avatar.dart';
import 'connection_banner.dart';
import 'error_text.dart';
import 'typing_label.dart';
import 'user_lookup.dart';

String formatListTime(int ms, {DateTime? now}) {
  if (ms <= 0) return '';
  final t = DateTime.fromMillisecondsSinceEpoch(ms);
  final n = now ?? DateTime.now();
  final sameDay = t.year == n.year && t.month == n.month && t.day == n.day;
  return sameDay ? DateFormat.Hm().format(t) : DateFormat.MMMd().format(t);
}

/// Ask for a username and open (or create) the direct chat with that person. Shared by the button and Ctrl+N.
Future<void> startNewChat(BuildContext context, WidgetRef ref) async {
  final user = await promptForUser(context, ref, title: 'New chat', actionLabel: 'Start');
  if (user == null || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  final router = GoRouter.of(context);
  try {
    final id = await ref.read(chatSyncProvider)!.createDirect(user.id);
    router.go('/chats/c/$id');
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(describeError(e))));
  }
}

class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key, this.selectedId});
  final String? selectedId;

  @override
  ConsumerState<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<ConversationSummary> _filter(List<ConversationSummary> all) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((s) => s.title.toLowerCase().contains(q) || (s.peerUsername ?? '').toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final summaries = ref.watch(conversationSummariesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            tooltip: 'New group (Ctrl+Shift+N)',
            icon: const Icon(Icons.group_add_outlined),
            onPressed: () => context.go('/chats/new-group'),
          ),
          IconButton(
            tooltip: 'Settings (Ctrl+,)',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: Column(children: [
        const ConnectionBanner(),
        Expanded(
          child: summaries.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Could not load conversations'),
                const SizedBox(height: Gap.s),
                FilledButton.tonal(
                  onPressed: () => ref.invalidate(conversationSummariesProvider),
                  child: const Text('Try again'),
                ),
              ]),
            ),
            data: (all) {
              if (all.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(Gap.l),
                    child: Text('No conversations yet.\nStart one with "New chat", or create a group.', textAlign: TextAlign.center),
                  ),
                );
              }
              final list = _filter(all);
              return Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(Gap.m, Gap.s, Gap.m, Gap.xs),
                  child: TextField(
                    controller: _search,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search chats',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              icon: const Icon(Icons.close),
                              onPressed: () => setState(() {
                                _search.clear();
                                _query = '';
                              }),
                            ),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                Expanded(
                  child: list.isEmpty
                      ? const Center(child: Text('No chats match your search.'))
                      : ListView.builder(
                          itemCount: list.length,
                          itemBuilder: (context, i) => _ConversationTile(summary: list[i], selected: list[i].id == widget.selectedId),
                        ),
                ),
              ]);
            },
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        tooltip: 'New chat (Ctrl+N)',
        onPressed: () => startNewChat(context, ref),
        icon: const Icon(Icons.add_comment),
        label: const Text('New chat'),
      ),
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  const _ConversationTile({required this.summary, required this.selected});
  final ConversationSummary summary;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = summary;
    final typingIds = ref.watch(typingUsersProvider(s.id));
    final presence = s.isGroup || s.peerUserId == null ? null : ref.watch(peerPresenceProvider(s.peerUserId!));

    // Names are only needed while somebody is typing, so only then do we subscribe to the member list.
    String typing = '';
    if (typingIds.isNotEmpty) {
      final members = ref.watch(membersProvider(s.id)).value ?? const <MemberRow>[];
      typing = s.isGroup
          ? typingLabel(typingIds, (id) => members.where((m) => m.userId == id).firstOrNull?.displayName)
          : 'typing…';
    }

    final scheme = Theme.of(context).colorScheme;
    final subtitleText = typing.isNotEmpty ? typing : (s.lastBody ?? '');
    final subtitleStyle = typing.isNotEmpty ? TextStyle(color: ChatColors.of(context).typing, fontStyle: FontStyle.italic) : null;

    final spoken = [
      s.title,
      if (s.isGroup) 'group, ${s.memberCount} members',
      if (presence?.online == true) 'online',
      if (s.unread > 0) '${s.unread} unread',
      if (subtitleText.isNotEmpty) subtitleText,
    ].join(', ');

    return Semantics(
      label: spoken,
      button: true,
      selected: selected,
      excludeSemantics: true,
      onTap: () => context.go('/chats/c/${s.id}'),
      child: ListTile(
        selected: selected,
        selectedTileColor: scheme.secondaryContainer.withValues(alpha: 0.5),
        leading: ChatAvatar(name: s.title, isGroup: s.isGroup, online: presence?.online),
        title: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(subtitleText, maxLines: 1, overflow: TextOverflow.ellipsis, style: subtitleStyle),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(formatListTime(s.lastActivityMs), style: Theme.of(context).textTheme.labelSmall),
            if (s.unread > 0) Badge(label: Text('${s.unread}')),
          ],
        ),
        onTap: () => context.go('/chats/c/${s.id}'),
      ),
    );
  }
}

/// Convenience used by the header and the info screen.
String presenceText(PresenceInfo? p, {DateTime? now}) => p == null ? '' : lastSeenLabel(p, now: now ?? DateTime.now());
