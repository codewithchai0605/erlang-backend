import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/protocol/protocol.dart' as pb;
import '../auth/auth_controller.dart';

/// What we know about one user's availability. Ephemeral: lives in memory only and is re-requested from
/// the server after every (re)connect, because presence pushes are best-effort and never replayed.
class PresenceInfo {
  const PresenceInfo({required this.userId, required this.online, required this.lastSeenMs});

  factory PresenceInfo.fromPb(pb.PresenceUpdate u) =>
      PresenceInfo(userId: u.userId, online: u.online, lastSeenMs: u.lastSeenUnixMs.toInt());

  final String userId;
  final bool online;

  /// Epoch milliseconds of the last time the user was seen online; 0 = unknown / never.
  final int lastSeenMs;
}

/// "online", "last seen today at 14:05", "last seen yesterday at 09:30", "last seen Mar 3", or "offline".
/// Pure function of its inputs (no clock, no locale state), so it is trivial to unit-test.
String lastSeenLabel(PresenceInfo p, {required DateTime now}) {
  if (p.online) return 'online';
  if (p.lastSeenMs <= 0) return 'offline';
  final t = DateTime.fromMillisecondsSinceEpoch(p.lastSeenMs);
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(t.year, t.month, t.day);
  final daysAgo = today.difference(day).inDays;
  final time = DateFormat.Hm().format(t);
  if (daysAgo <= 0) return 'last seen today at $time';
  if (daysAgo == 1) return 'last seen yesterday at $time';
  return 'last seen ${DateFormat.MMMd().format(t)}';
}

/// userId -> latest known presence. Pushed updates replace single entries; a snapshot refreshes many.
class PresenceNotifier extends Notifier<Map<String, PresenceInfo>> {
  @override
  Map<String, PresenceInfo> build() {
    ref.watch(authControllerProvider.select((a) => a.session?.userId)); // new account => start empty
    return const {};
  }

  void apply(PresenceInfo info) => state = {...state, info.userId: info};

  void applyAll(Iterable<PresenceInfo> infos) => state = {...state, for (final i in infos) i.userId: i};

  void clear() => state = const {};
}

final presenceProvider = NotifierProvider<PresenceNotifier, Map<String, PresenceInfo>>(PresenceNotifier.new);
