import 'package:client/core/db/app_database.dart';
import 'package:client/features/chat/message_bubble.dart';
import 'package:flutter_test/flutter_test.dart';

MessageRow _msg({String status = 'accepted', int? seq = 5}) => MessageRow(
      clientMessageId: 'm',
      conversationId: 'c',
      senderId: 'me',
      seq: seq,
      body: 'hi',
      createdAtMs: 1,
      status: status,
    );

MemberRow _member(String id, {int delivered = 0, int read = 0}) => MemberRow(
      conversationId: 'c',
      userId: id,
      username: id,
      displayName: id,
      deliveredSeq: delivered,
      readSeq: read,
      role: 'member',
    );

void main() {
  test('outbox states come from the message status', () {
    expect(deliveryStateFor(_msg(status: 'failed'), [], 'me'), DeliveryState.failed);
    expect(deliveryStateFor(_msg(status: 'pending', seq: null), [], 'me'), DeliveryState.pending);
    expect(deliveryStateFor(_msg(status: 'sending', seq: null), [], 'me'), DeliveryState.pending);
  });

  test('direct chat: sent -> delivered -> read follows the peer marks', () {
    expect(deliveryStateFor(_msg(), [_member('me'), _member('bob')], 'me'), DeliveryState.sent);
    expect(deliveryStateFor(_msg(), [_member('me'), _member('bob', delivered: 5)], 'me'), DeliveryState.delivered);
    expect(deliveryStateFor(_msg(), [_member('me'), _member('bob', delivered: 5, read: 5)], 'me'), DeliveryState.read);
  });

  test('group: delivered/read only when EVERY other member has it (weakest link wins)', () {
    final members = [_member('me'), _member('bob', delivered: 5, read: 5), _member('cleo', delivered: 5)];
    expect(deliveryStateFor(_msg(), members, 'me'), DeliveryState.delivered); // Cleo has not read it
    final lagging = [_member('me'), _member('bob', delivered: 5, read: 5), _member('cleo', delivered: 4)];
    expect(deliveryStateFor(_msg(), lagging, 'me'), DeliveryState.sent); // Cleo has not even received it
  });

  test('a member who just left no longer holds the message back', () {
    // Bob left the group; only Cleo remains and she has read it
    expect(deliveryStateFor(_msg(), [_member('me'), _member('cleo', delivered: 5, read: 5)], 'me'), DeliveryState.read);
  });
}
