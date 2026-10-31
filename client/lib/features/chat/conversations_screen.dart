import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/db/app_database.dart';
import '../../core/networking/api_client.dart';
import '../../core/networking/ws_service.dart';
import '../../providers.dart';
import '../auth/auth_controller.dart';
import 'connection_banner.dart';

String formatListTime(int ms, {DateTime? now}) {
  if (ms <= 0) return '';
  final t = DateTime.fromMillisecondsSinceEpoch(ms);
  final n = now ?? DateTime.now();
  final sameDay = t.year == n.year && t.month == n.month && t.day == n.day;
  return sameDay ? DateFormat.Hm().format(t) : DateFormat.MMMd().format(t);
}

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key, this.selectedId});
  final String? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaries = ref.watch(conversationSummariesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: Column(children: [
        const ConnectionBanner(),
        Expanded(
          child: summaries.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => const Center(child: Text('Could not load conversations')),
            data: (list) => list.isEmpty
                ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No conversations yet. Start one with "New chat".', textAlign: TextAlign.center)))
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, i) => _ConversationTile(summary: list[i], selected: list[i].id == selectedId),
                  ),
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newChat(context, ref),
        icon: const Icon(Icons.add_comment),
        label: const Text('New chat'),
      ),
    );
  }

  Future<void> _newChat(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final username = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New chat'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: "Their username"),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Start')),
        ],
      ),
    );
    controller.dispose();
    if (username == null || username.isEmpty || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      final user = await ref.read(apiClientProvider).lookupUser(username);
      final id = await ref.read(chatSyncProvider)!.createDirect(user.id);
      router.go('/chats/c/$id');
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.code == 'not_found' ? 'No user with that name' : e.message)));
    } on ProtocolFailure catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text("Couldn't start the chat. Are you online?")));
    }
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.summary, required this.selected});
  final ConversationSummary summary;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final initial = s.title.isEmpty ? '?' : s.title.characters.first.toUpperCase();
    return ListTile(
      selected: selected,
      leading: CircleAvatar(child: Text(initial)),
      title: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(s.lastBody ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(formatListTime(s.lastActivityMs), style: Theme.of(context).textTheme.labelSmall),
          if (s.unread > 0)
            Semantics(
              label: '${s.unread} unread',
              child: Badge(label: Text('${s.unread}')),
            ),
        ],
      ),
      onTap: () => context.go('/chats/c/${s.id}'),
    );
  }
}
