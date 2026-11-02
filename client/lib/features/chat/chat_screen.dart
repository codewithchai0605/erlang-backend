import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../core/db/app_database.dart';
import '../../providers.dart';
import '../auth/auth_controller.dart';
import 'chat_avatar.dart';
import 'connection_banner.dart';
import 'conversations_screen.dart' show presenceText;
import 'message_bubble.dart';
import 'typing_label.dart';

bool get _isDesktop =>
    defaultTargetPlatform == TargetPlatform.windows ||
    defaultTargetPlatform == TargetPlatform.linux ||
    defaultTargetPlatform == TargetPlatform.macOS;

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

  void _back() => context.go('/chats');

  @override
  Widget build(BuildContext context) {
    final id = widget.conversationId;
    final me = ref.watch(authControllerProvider).session?.userId ?? '';
    final messagesAsync = ref.watch(messagesProvider(id));
    final messages = messagesAsync.value ?? const <MessageRow>[];
    final members = ref.watch(membersProvider(id)).value ?? const <MemberRow>[];
    final conversation = ref.watch(conversationProvider(id));
    ref.listen(messagesProvider(id), (_, _) => _markRead());

    // The conversation row is deleted when we are removed from a group (or leave it elsewhere).
    if (conversation.hasValue && conversation.value == null) {
      return _GoneView(onBack: _back);
    }
    final isGroup = conversation.value?.kind == 'group';
    final nameOf = {for (final m in members) m.userId: m.displayName};

    final newestFirst = messages.reversed.toList();
    return Scaffold(
      appBar: AppBar(
        leading: widget.showBack ? IconButton(tooltip: 'Back', icon: const Icon(Icons.arrow_back), onPressed: _back) : null,
        automaticallyImplyLeading: false,
        titleSpacing: widget.showBack ? 0 : null,
        title: _ChatHeader(conversationId: id),
        actions: [
          IconButton(
            tooltip: isGroup ? 'Group info' : 'Contact info',
            icon: const Icon(Icons.info_outline),
            onPressed: () => context.go('/chats/c/$id/info'),
          ),
        ],
      ),
      body: Column(children: [
        const ConnectionBanner(),
        Expanded(
          child: Stack(children: [
            if (messagesAsync.isLoading && !messagesAsync.hasValue)
              const Center(child: CircularProgressIndicator())
            else if (messagesAsync.hasError && !messagesAsync.hasValue)
              const Center(child: Text('Could not load messages'))
            else if (newestFirst.isEmpty)
              const Center(child: Text('No messages yet. Say hello!'))
            else
              ListView.builder(
                controller: _scroll,
                reverse: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: newestFirst.length,
                itemBuilder: (context, i) {
                  final m = newestFirst[i];
                  final older = i + 1 < newestFirst.length ? newestFirst[i + 1] : null;
                  final mine = m.senderId == me;
                  final t = DateTime.fromMillisecondsSinceEpoch(m.createdAtMs);
                  final newDay = older == null || !_sameDay(t, DateTime.fromMillisecondsSinceEpoch(older.createdAtMs));
                  // In a group, name the sender at the start of each run of their messages.
                  final showName = isGroup && !mine && (newDay || older.senderId != m.senderId);
                  return Column(children: [
                    if (newDay)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(DateFormat.yMMMd().format(t), style: Theme.of(context).textTheme.labelMedium),
                      ),
                    MessageBubble(
                      text: m.body,
                      time: DateFormat.Hm().format(t),
                      mine: mine,
                      senderName: showName ? (nameOf[m.senderId] ?? 'Former member') : null,
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
        _TypingStrip(conversationId: id),
        _Composer(
          onSend: (text) => ref.read(chatSyncProvider)?.sendText(id, text),
          onTyping: (typing) => ref.read(chatSyncProvider)?.setTyping(id, typing),
        ),
      ]),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

/// App-bar title: avatar, name, and a live subtitle ("typing...", "online", "last seen ...", or the members).
class _ChatHeader extends ConsumerWidget {
  const _ChatHeader({required this.conversationId});
  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authControllerProvider).session?.userId ?? '';
    final summary = ref.watch(conversationSummariesProvider).value?.where((s) => s.id == conversationId).firstOrNull;
    final members = ref.watch(membersProvider(conversationId)).value ?? const <MemberRow>[];
    final typingIds = ref.watch(typingUsersProvider(conversationId));
    final isGroup = summary?.isGroup ?? false;
    final presence = isGroup || summary?.peerUserId == null ? null : ref.watch(peerPresenceProvider(summary!.peerUserId!));

    final title = summary?.title ?? 'Chat';
    String subtitle;
    var highlight = false;
    if (typingIds.isNotEmpty) {
      subtitle = isGroup ? typingLabel(typingIds, (id) => members.where((m) => m.userId == id).firstOrNull?.displayName) : 'typing…';
      highlight = true;
    } else if (isGroup) {
      final others = members.where((m) => m.userId != me).map((m) => m.displayName).toList();
      final shown = others.take(3).join(', ');
      subtitle = others.length > 3 ? '$shown +${others.length - 3}, You' : (others.isEmpty ? 'You' : '$shown, You');
    } else {
      subtitle = presenceText(presence);
    }

    final scheme = Theme.of(context).colorScheme;
    final subStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: highlight || presence?.online == true ? ChatColors.of(context).typing : scheme.onSurfaceVariant,
        );
    return Semantics(
      button: true,
      label: 'Conversation details for $title${subtitle.isEmpty ? '' : ', $subtitle'}',
      excludeSemantics: true,
      onTap: () => context.go('/chats/c/$conversationId/info'),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.go('/chats/c/$conversationId/info'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Row(children: [
            ChatAvatar(name: title, isGroup: isGroup, online: presence?.online, radius: 18),
            const SizedBox(width: Gap.s + 4),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
                if (subtitle.isNotEmpty) Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: subStyle),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// "Alice is typing..." line right above the composer. A live region, so screen readers announce it politely.
class _TypingStrip extends ConsumerWidget {
  const _TypingStrip({required this.conversationId});
  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typingIds = ref.watch(typingUsersProvider(conversationId));
    var text = '';
    if (typingIds.isNotEmpty) {
      final members = ref.watch(membersProvider(conversationId)).value ?? const <MemberRow>[];
      text = typingLabel(typingIds, (id) => members.where((m) => m.userId == id).firstOrNull?.displayName);
    }
    return AnimatedSize(
      duration: const Duration(milliseconds: 150),
      alignment: Alignment.topLeft,
      child: text.isEmpty
          ? const SizedBox(width: double.infinity)
          : Semantics(
              liveRegion: true,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Gap.m, 2, Gap.m, 2),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(text,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: ChatColors.of(context).typing, fontStyle: FontStyle.italic)),
                ),
              ),
            ),
    );
  }
}

class _GoneView extends StatelessWidget {
  const _GoneView({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(leading: IconButton(tooltip: 'Back', icon: const Icon(Icons.arrow_back), onPressed: onBack)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(Gap.l),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.block, size: 48),
              const SizedBox(height: Gap.m),
              const Text("You're no longer part of this conversation.", textAlign: TextAlign.center),
              const SizedBox(height: Gap.m),
              FilledButton(onPressed: onBack, child: const Text('Back to chats')),
            ]),
          ),
        ),
      );
}

class _Composer extends StatefulWidget {
  const _Composer({required this.onSend, required this.onTyping});
  final void Function(String text) onSend;
  final void Function(bool isTyping) onTyping;
  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    try {
      widget.onTyping(false); // leaving the chat ends "typing"
    } catch (_) {
      // the app is shutting down: the peer's indicator expires by itself
    }
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
                  autofocus: _isDesktop, // keyboard users can start typing at once; on phones this would pop the keyboard
                  minLines: 1,
                  maxLines: 5,
                  maxLength: 4000,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(hintText: 'Message', counterText: ''),
                  onChanged: (v) => widget.onTyping(v.trim().isNotEmpty),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(tooltip: 'Send (Enter)', icon: const Icon(Icons.send), onPressed: _send),
          ]),
        ),
      );
}
