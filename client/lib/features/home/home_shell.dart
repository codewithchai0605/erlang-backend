import 'package:flutter/material.dart';

import '../../core/responsive/breakpoints.dart';
import '../chat/chat_screen.dart';
import '../chat/conversations_screen.dart';

/// Responsive container: one pane on phones, list + open chat side by side on wide windows.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, this.selectedId});
  final String? selectedId;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
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
