import 'package:flutter/material.dart';

import '../../core/db/app_database.dart';

enum DeliveryState { pending, failed, sent, delivered, read }

/// Derives what to show for MY message from its status and the other members' receipt marks.
DeliveryState deliveryStateFor(MessageRow m, List<MemberRow> members, String myUserId) {
  if (m.status == 'failed') return DeliveryState.failed;
  final seq = m.seq;
  if (m.status != 'accepted' || seq == null) return DeliveryState.pending;
  final others = members.where((x) => x.userId != myUserId).toList();
  if (others.isEmpty) return DeliveryState.sent;
  if (others.every((x) => x.readSeq >= seq)) return DeliveryState.read;
  if (others.every((x) => x.deliveredSeq >= seq)) return DeliveryState.delivered;
  return DeliveryState.sent;
}

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.text,
    required this.time,
    required this.mine,
    this.senderName,
    this.state,
    this.onRetry,
  });

  final String text;
  final String time;
  final bool mine;

  /// Shown above the text of someone else's message in a GROUP chat (null in direct chats and for my own).
  final String? senderName;
  final DeliveryState? state;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = mine ? scheme.primaryContainer : scheme.surfaceContainerHighest;
    final fg = mine ? scheme.onPrimaryContainer : scheme.onSurface;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78 > 560 ? 560 : MediaQuery.sizeOf(context).width * 0.78),
        child: Semantics(
          label: '${mine ? "You" : (senderName ?? "Them")}: $text, $time${state == null ? "" : ", ${_label(state!)}"}',
          excludeSemantics: true,
          child: Card(
            color: bg,
            margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
              child: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
                if (senderName != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(senderName!,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600)),
                    ),
                  ),
                // SelectableText: desktop users expect to select and copy message text.
                Align(alignment: Alignment.centerLeft, child: SelectableText(text, style: TextStyle(color: fg))),
                const SizedBox(height: 2),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(time, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg.withValues(alpha: 0.7))),
                  if (state != null) ...[const SizedBox(width: 4), _icon(context, state!, fg)],
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  static String _label(DeliveryState s) => switch (s) {
        DeliveryState.pending => 'sending',
        DeliveryState.failed => 'failed to send',
        DeliveryState.sent => 'sent',
        DeliveryState.delivered => 'delivered',
        DeliveryState.read => 'read',
      };

  Widget _icon(BuildContext context, DeliveryState s, Color fg) {
    const size = 14.0;
    switch (s) {
      case DeliveryState.pending:
        return Icon(Icons.schedule, size: size, color: fg.withValues(alpha: 0.7));
      case DeliveryState.failed:
        return InkWell(
          onTap: onRetry,
          child: Tooltip(message: 'Tap to retry', child: Icon(Icons.error_outline, size: size + 4, color: Theme.of(context).colorScheme.error)),
        );
      case DeliveryState.sent:
        return Icon(Icons.check, size: size, color: fg.withValues(alpha: 0.7));
      case DeliveryState.delivered:
        return Icon(Icons.done_all, size: size, color: fg.withValues(alpha: 0.7));
      case DeliveryState.read:
        return Icon(Icons.done_all, size: size, color: Theme.of(context).colorScheme.primary);
    }
  }
}
