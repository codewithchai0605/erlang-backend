import 'package:client/core/db/app_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers.dart';
import '../auth/auth_controller.dart';
import 'connection_banner.dart';
import 'message_bubble.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.conversationId, required this.showBack});
  final String conversationId;
  final bool showBack;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> with WidgetsBindingObserver {
  final _scroll = ScrollController();
  bool _showJump = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _markRead();
  }

  void _onScroll() {
    final p = _scroll.position;
    final jump = p.pixels > 400;
    if (jump != _showJump) setState(() => _showJump = jump);
    // list is reversed: maxScrollExtent is the OLDEST end
    if (p.pixels >= p.maxScrollExtent - 200) ref.read(chatSyncProvider)?.loadOlder(widget.conversationId);
  }

  void _markRead() {
    if (!mounted) return;
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused) return; // not actually looking at it
    ref.read(chatSyncProvider)?.markRead(widget.conversationId);
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.conversationId;
    final me = ref.watch(authControllerProvider).session?.userId ?? '';
    final messages = ref.watch(messagesProvider(id)).value ?? const <MessageRow>[];
    final members = ref.watch(membersProvider(id)).value ?? const <MemberRow>[];
    final summary = ref.watch(conversationSummariesProvider).value?.where((s) => s.id == id).firstOrNull;
    ref.listen(messagesProvider(id), (_, _) => _markRead());

    final newestFirst = messages.reversed.toList();
    return Scaffold(
      appBar: AppBar(
        leading: widget.showBack ? IconButton(tooltip: 'Back', icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/chats')) : null,
        automaticallyImplyLeading: false,
        title: Text(summary?.title ?? 'Chat'),
      ),
      body: Column(children: [
        const ConnectionBanner(),
        Expanded(
          child: Stack(children: [
            newestFirst.isEmpty
                ? const Center(child: Text('No messages yet. Say hello!'))
                : ListView.builder(
                    controller: _scroll,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: newestFirst.length,
                    itemBuilder: (context, i) {
                      final m = newestFirst[i];
                      final older = i + 1 < newestFirst.length ? newestFirst[i + 1] : null;
                      final mine = m.senderId == me;
                      final t = DateTime.fromMillisecondsSinceEpoch(m.createdAtMs);
                      return Column(children: [
                        if (older == null || !_sameDay(t, DateTime.fromMillisecondsSinceEpoch(older.createdAtMs)))
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(DateFormat.yMMMd().format(t), style: Theme.of(context).textTheme.labelMedium),
                          ),
                        MessageBubble(
                          text: m.body,
                          time: DateFormat.Hm().format(t),
                          mine: mine,
                          state: mine ? deliveryStateFor(m, members, me) : null,
                          onRetry: () => ref.read(chatSyncProvider)?.retry(m.clientMessageId),
                        ),
                      ]);
                    },
                  ),
            if (_showJump)
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton.small(
                  tooltip: 'Jump to latest',
                  onPressed: () => _scroll.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut),
                  child: const Icon(Icons.arrow_downward),
                ),
              ),
          ]),
        ),
        _Composer(onSend: (text) => ref.read(chatSyncProvider)?.sendText(id, text)),
      ]),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

class _Composer extends StatefulWidget {
  const _Composer({required this.onSend});
  final void Function(String text) onSend;
  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final t = _controller.text;
    if (t.trim().isEmpty) return;
    widget.onSend(t);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              // Enter sends on desktop keyboards; Shift+Enter inserts a newline.
              child: CallbackShortcuts(
                bindings: {const SingleActivator(LogicalKeyboardKey.enter): _send},
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 5,
                  maxLength: 4000,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(hintText: 'Message', counterText: ''),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(tooltip: 'Send', icon: const Icon(Icons.send), onPressed: _send),
          ]),
        ),
      );
}
