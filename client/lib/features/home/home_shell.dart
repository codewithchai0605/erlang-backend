import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/breakpoints.dart';
import '../chat/chat_screen.dart';
import '../chat/conversations_screen.dart';

/// Responsive container: one pane on phones, list + open chat side by side on wide windows.
/// Also hosts the desktop keyboard shortcuts:
///   Ctrl+N new chat | Ctrl+Shift+N new group | Ctrl+, settings | Esc close the open chat
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, this.selectedId});
  final String? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyN, control: true): () => startNewChat(context, ref),
          const SingleActivator(LogicalKeyboardKey.keyN, control: true, shift: true): () => context.go('/chats/new-group'),
          const SingleActivator(LogicalKeyboardKey.comma, control: true): () => context.go('/settings'),
          const SingleActivator(LogicalKeyboardKey.escape): () {
            if (selectedId != null) context.go('/chats');
          },
        },
        // Focus: lets the shortcuts work even before the user has clicked anything.
        child: Focus(autofocus: true, child: _layout()),
      );

  Widget _layout() => LayoutBuilder(builder: (context, constraints) {
        final id = selectedId;
        if (Breakpoints.isTwoPane(constraints.maxWidth)) {
          return Scaffold(
            body: Row(children: [
              SizedBox(width: Breakpoints.listPaneWidth, child: ConversationsScreen(selectedId: id)),
              const VerticalDivider(width: 1),
              Expanded(
                child: id == null
                    ? const Center(child: Text('Select a conversation'))
                    : ChatScreen(key: ValueKey(id), conversationId: id, showBack: false),
              ),
            ]),
          );
        }
        return id == null
            ? const ConversationsScreen()
            : ChatScreen(key: ValueKey(id), conversationId: id, showBack: true);
      });
}
