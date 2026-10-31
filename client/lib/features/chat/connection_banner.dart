import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/networking/ws_service.dart';
import '../../providers.dart';

/// Shows connection state so users know why messages are "pending". Hidden while connected.
class ConnectionBanner extends ConsumerWidget {
  const ConnectionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectionStatusProvider).value ?? ConnectionStatus.disconnected;
    if (status == ConnectionStatus.connected) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final text = status == ConnectionStatus.connecting ? 'Connecting...' : 'Offline. Messages will send when you reconnect.';
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        color: scheme.secondaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(text, style: TextStyle(color: scheme.onSecondaryContainer)),
      ),
    );
  }
}
