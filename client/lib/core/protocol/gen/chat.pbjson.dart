// This is a generated file - do not edit.
//
// Generated from chat.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use errorCodeDescriptor instead')
const ErrorCode$json = {
  '1': 'ErrorCode',
  '2': [
    {'1': 'ERROR_CODE_UNSPECIFIED', '2': 0},
    {'1': 'ERROR_CODE_UNSUPPORTED_VERSION', '2': 1},
    {'1': 'ERROR_CODE_UNAUTHENTICATED', '2': 2},
    {'1': 'ERROR_CODE_INVALID_ARGUMENT', '2': 3},
    {'1': 'ERROR_CODE_PERMISSION_DENIED', '2': 4},
    {'1': 'ERROR_CODE_NOT_FOUND', '2': 5},
    {'1': 'ERROR_CODE_RATE_LIMITED', '2': 6},
    {'1': 'ERROR_CODE_UNSUPPORTED_EVENT', '2': 7},
    {'1': 'ERROR_CODE_INTERNAL', '2': 8},
    {'1': 'ERROR_CODE_MESSAGE_TOO_LARGE', '2': 9},
  ],
};

/// Descriptor for `ErrorCode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List errorCodeDescriptor = $convert.base64Decode(
    'CglFcnJvckNvZGUSGgoWRVJST1JfQ09ERV9VTlNQRUNJRklFRBAAEiIKHkVSUk9SX0NPREVfVU'
    '5TVVBQT1JURURfVkVSU0lPThABEh4KGkVSUk9SX0NPREVfVU5BVVRIRU5USUNBVEVEEAISHwob'
    'RVJST1JfQ09ERV9JTlZBTElEX0FSR1VNRU5UEAMSIAocRVJST1JfQ09ERV9QRVJNSVNTSU9OX0'
    'RFTklFRBAEEhgKFEVSUk9SX0NPREVfTk9UX0ZPVU5EEAUSGwoXRVJST1JfQ09ERV9SQVRFX0xJ'
    'TUlURUQQBhIgChxFUlJPUl9DT0RFX1VOU1VQUE9SVEVEX0VWRU5UEAcSFwoTRVJST1JfQ09ERV'
    '9JTlRFUk5BTBAIEiAKHEVSUk9SX0NPREVfTUVTU0FHRV9UT09fTEFSR0UQCQ==');

@$core.Deprecated('Use memberRoleDescriptor instead')
const MemberRole$json = {
  '1': 'MemberRole',
  '2': [
    {'1': 'MEMBER_ROLE_UNSPECIFIED', '2': 0},
    {'1': 'MEMBER_ROLE_MEMBER', '2': 1},
    {'1': 'MEMBER_ROLE_ADMIN', '2': 2},
    {'1': 'MEMBER_ROLE_OWNER', '2': 3},
  ],
};

/// Descriptor for `MemberRole`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List memberRoleDescriptor = $convert.base64Decode(
    'CgpNZW1iZXJSb2xlEhsKF01FTUJFUl9ST0xFX1VOU1BFQ0lGSUVEEAASFgoSTUVNQkVSX1JPTE'
    'VfTUVNQkVSEAESFQoRTUVNQkVSX1JPTEVfQURNSU4QAhIVChFNRU1CRVJfUk9MRV9PV05FUhAD');

@$core.Deprecated('Use conversationKindDescriptor instead')
const ConversationKind$json = {
  '1': 'ConversationKind',
  '2': [
    {'1': 'CONVERSATION_KIND_UNSPECIFIED', '2': 0},
    {'1': 'CONVERSATION_KIND_DIRECT', '2': 1},
    {'1': 'CONVERSATION_KIND_GROUP', '2': 2},
  ],
};

/// Descriptor for `ConversationKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List conversationKindDescriptor = $convert.base64Decode(
    'ChBDb252ZXJzYXRpb25LaW5kEiEKHUNPTlZFUlNBVElPTl9LSU5EX1VOU1BFQ0lGSUVEEAASHA'
    'oYQ09OVkVSU0FUSU9OX0tJTkRfRElSRUNUEAESGwoXQ09OVkVSU0FUSU9OX0tJTkRfR1JPVVAQ'
    'Ag==');

@$core.Deprecated('Use clientEnvelopeDescriptor instead')
const ClientEnvelope$json = {
  '1': 'ClientEnvelope',
  '2': [
    {'1': 'request_id', '3': 1, '4': 1, '5': 9, '10': 'requestId'},
    {
      '1': 'hello',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.chat.v1.Hello',
      '9': 0,
      '10': 'hello'
    },
    {
      '1': 'send_message',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.chat.v1.SendMessage',
      '9': 0,
      '10': 'sendMessage'
    },
    {
      '1': 'typing',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.chat.v1.TypingEvent',
      '9': 0,
      '10': 'typing'
    },
    {
      '1': 'mark_read',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.chat.v1.MarkRead',
      '9': 0,
      '10': 'markRead'
    },
    {
      '1': 'sync_request',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.chat.v1.SyncRequest',
      '9': 0,
      '10': 'syncRequest'
    },
    {
      '1': 'ack_delivered',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.chat.v1.DeliveryAck',
      '9': 0,
      '10': 'ackDelivered'
    },
    {
      '1': 'create_direct',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.chat.v1.CreateDirectConversation',
      '9': 0,
      '10': 'createDirect'
    },
    {
      '1': 'list_conversations',
      '3': 16,
      '4': 1,
      '5': 11,
      '6': '.chat.v1.ListConversations',
      '9': 0,
      '10': 'listConversations'
    },
    {
      '1': 'history_request',
      '3': 17,
      '4': 1,
      '5': 11,
      '6': '.chat.v1.HistoryRequest',
      '9': 0,
      '10': 'historyRequest'
    },
    {
      '1': 'create_group',
      '3': 18,
      '4': 1,
      '5': 11,
      '6': '.chat.v1.CreateGroup',
      '9': 0,
      '10': 'createGroup'
    },
    {
      '1': 'add_members',
      '3': 19,
      '4': 1,
      '5': 11,
      '6': '.chat.v1.AddMembers',
      '9': 0,
      '10': 'addMembers'
    },
    {
      '1': 'remove_member',
      '3': 20,
      '4': 1,
      '5': 11,
      '6': '.chat.v1.RemoveMember',
      '9': 0,
      '10': 'removeMember'
    },
    {
      '1': 'leave_conversation',
      '3': 21,
      '4': 1,
      '5': 11,
      '6': '.chat.v1.LeaveConversation',
      '9': 0,
      '10': 'leaveConversation'
    },
    {
      '1': 'rename_group',
      '3': 22,
      '4': 1,
      '5': 11,
      '6': '.chat.v1.RenameGroup',
      '9': 0,
      '10': 'renameGroup'
    },
    {
      '1': 'get_presence',
      '3': 23,
      '4': 1,
      '5': 11,
      '6': '.chat.v1.GetPresence',
      '9': 0,
      '10': 'getPresence'
    },
  ],
  '8': [
    {'1': 'body'},
  ],
};

/// Descriptor for `ClientEnvelope`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List clientEnvelopeDescriptor = $convert.base64Decode(
    'Cg5DbGllbnRFbnZlbG9wZRIdCgpyZXF1ZXN0X2lkGAEgASgJUglyZXF1ZXN0SWQSJgoFaGVsbG'
    '8YCSABKAsyDi5jaGF0LnYxLkhlbGxvSABSBWhlbGxvEjkKDHNlbmRfbWVzc2FnZRgKIAEoCzIU'
    'LmNoYXQudjEuU2VuZE1lc3NhZ2VIAFILc2VuZE1lc3NhZ2USLgoGdHlwaW5nGAsgASgLMhQuY2'
    'hhdC52MS5UeXBpbmdFdmVudEgAUgZ0eXBpbmcSMAoJbWFya19yZWFkGAwgASgLMhEuY2hhdC52'
    'MS5NYXJrUmVhZEgAUghtYXJrUmVhZBI5CgxzeW5jX3JlcXVlc3QYDSABKAsyFC5jaGF0LnYxLl'
    'N5bmNSZXF1ZXN0SABSC3N5bmNSZXF1ZXN0EjsKDWFja19kZWxpdmVyZWQYDiABKAsyFC5jaGF0'
    'LnYxLkRlbGl2ZXJ5QWNrSABSDGFja0RlbGl2ZXJlZBJICg1jcmVhdGVfZGlyZWN0GA8gASgLMi'
    'EuY2hhdC52MS5DcmVhdGVEaXJlY3RDb252ZXJzYXRpb25IAFIMY3JlYXRlRGlyZWN0EksKEmxp'
    'c3RfY29udmVyc2F0aW9ucxgQIAEoCzIaLmNoYXQudjEuTGlzdENvbnZlcnNhdGlvbnNIAFIRbG'
    'lzdENvbnZlcnNhdGlvbnMSQgoPaGlzdG9yeV9yZXF1ZXN0GBEgASgLMhcuY2hhdC52MS5IaXN0'
    'b3J5UmVxdWVzdEgAUg5oaXN0b3J5UmVxdWVzdBI5CgxjcmVhdGVfZ3JvdXAYEiABKAsyFC5jaG'
    'F0LnYxLkNyZWF0ZUdyb3VwSABSC2NyZWF0ZUdyb3VwEjYKC2FkZF9tZW1iZXJzGBMgASgLMhMu'
    'Y2hhdC52MS5BZGRNZW1iZXJzSABSCmFkZE1lbWJlcnMSPAoNcmVtb3ZlX21lbWJlchgUIAEoCz'
    'IVLmNoYXQudjEuUmVtb3ZlTWVtYmVySABSDHJlbW92ZU1lbWJlchJLChJsZWF2ZV9jb252ZXJz'
    'YXRpb24YFSABKAsyGi5jaGF0LnYxLkxlYXZlQ29udmVyc2F0aW9uSABSEWxlYXZlQ29udmVyc2'
    'F0aW9uEjkKDHJlbmFtZV9ncm91cBgWIAEoCzIULmNoYXQudjEuUmVuYW1lR3JvdXBIAFILcmVu'
    'YW1lR3JvdXASOQoMZ2V0X3ByZXNlbmNlGBcgASgLMhQuY2hhdC52MS5HZXRQcmVzZW5jZUgAUg'
    'tnZXRQcmVzZW5jZUIGCgRib2R5');

@$core.Deprecated('Use helloDescriptor instead')
const Hello$json = {
  '1': 'Hello',
  '2': [
    {'1': 'protocol_version', '3': 1, '4': 1, '5': 13, '10': 'protocolVersion'},
    {'1': 'capabilities', '3': 2, '4': 3, '5': 9, '10': 'capabilities'},
    {'1': 'access_token', '3': 3, '4': 1, '5': 9, '10': 'accessToken'},
  ],
};

/// Descriptor for `Hello`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List helloDescriptor = $convert.base64Decode(
    'CgVIZWxsbxIpChBwcm90b2NvbF92ZXJzaW9uGAEgASgNUg9wcm90b2NvbFZlcnNpb24SIgoMY2'
    'FwYWJpbGl0aWVzGAIgAygJUgxjYXBhYmlsaXRpZXMSIQoMYWNjZXNzX3Rva2VuGAMgASgJUgth'
    'Y2Nlc3NUb2tlbg==');

@$core.Deprecated('Use sendMessageDescriptor instead')
const SendMessage$json = {
  '1': 'SendMessage',
  '2': [
    {'1': 'conversation_id', '3': 1, '4': 1, '5': 9, '10': 'conversationId'},
    {'1': 'client_message_id', '3': 2, '4': 1, '5': 9, '10': 'clientMessageId'},
    {'1': 'text', '3': 3, '4': 1, '5': 9, '10': 'text'},
  ],
};

/// Descriptor for `SendMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sendMessageDescriptor = $convert.base64Decode(
    'CgtTZW5kTWVzc2FnZRInCg9jb252ZXJzYXRpb25faWQYASABKAlSDmNvbnZlcnNhdGlvbklkEi'
    'oKEWNsaWVudF9tZXNzYWdlX2lkGAIgASgJUg9jbGllbnRNZXNzYWdlSWQSEgoEdGV4dBgDIAEo'
    'CVIEdGV4dA==');

@$core.Deprecated('Use typingEventDescriptor instead')
const TypingEvent$json = {
  '1': 'TypingEvent',
  '2': [
    {'1': 'conversation_id', '3': 1, '4': 1, '5': 9, '10': 'conversationId'},
    {'1': 'is_typing', '3': 2, '4': 1, '5': 8, '10': 'isTyping'},
  ],
};

/// Descriptor for `TypingEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List typingEventDescriptor = $convert.base64Decode(
    'CgtUeXBpbmdFdmVudBInCg9jb252ZXJzYXRpb25faWQYASABKAlSDmNvbnZlcnNhdGlvbklkEh'
    'sKCWlzX3R5cGluZxgCIAEoCFIIaXNUeXBpbmc=');

@$core.Deprecated('Use markReadDescriptor instead')
const MarkRead$json = {
  '1': 'MarkRead',
  '2': [
    {'1': 'conversation_id', '3': 1, '4': 1, '5': 9, '10': 'conversationId'},
    {'1': 'read_up_to_seq', '3': 2, '4': 1, '5': 3, '10': 'readUpToSeq'},
  ],
};

/// Descriptor for `MarkRead`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List markReadDescriptor = $convert.base64Decode(
    'CghNYXJrUmVhZBInCg9jb252ZXJzYXRpb25faWQYASABKAlSDmNvbnZlcnNhdGlvbklkEiMKDn'
    'JlYWRfdXBfdG9fc2VxGAIgASgDUgtyZWFkVXBUb1NlcQ==');

@$core.Deprecated('Use deliveryAckDescriptor instead')
const DeliveryAck$json = {
  '1': 'DeliveryAck',
  '2': [
    {'1': 'conversation_id', '3': 1, '4': 1, '5': 9, '10': 'conversationId'},
    {
      '1': 'delivered_up_to_seq',
      '3': 2,
      '4': 1,
      '5': 3,
      '10': 'deliveredUpToSeq'
    },
  ],
};

/// Descriptor for `DeliveryAck`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deliveryAckDescriptor = $convert.base64Decode(
    'CgtEZWxpdmVyeUFjaxInCg9jb252ZXJzYXRpb25faWQYASABKAlSDmNvbnZlcnNhdGlvbklkEi'
    '0KE2RlbGl2ZXJlZF91cF90b19zZXEYAiABKANSEGRlbGl2ZXJlZFVwVG9TZXE=');

@$core.Deprecated('Use syncRequestDescriptor instead')
const SyncRequest$json = {
  '1': 'SyncRequest',
  '2': [
    {'1': 'conversation_id', '3': 1, '4': 1, '5': 9, '10': 'conversationId'},
    {'1': 'after_seq', '3': 2, '4': 1, '5': 3, '10': 'afterSeq'},
    {'1': 'limit', '3': 3, '4': 1, '5': 13, '10': 'limit'},
  ],
};

/// Descriptor for `SyncRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List syncRequestDescriptor = $convert.base64Decode(
    'CgtTeW5jUmVxdWVzdBInCg9jb252ZXJzYXRpb25faWQYASABKAlSDmNvbnZlcnNhdGlvbklkEh'
    'sKCWFmdGVyX3NlcRgCIAEoA1IIYWZ0ZXJTZXESFAoFbGltaXQYAyABKA1SBWxpbWl0');

@$core.Deprecated('Use historyRequestDescriptor instead')
const HistoryRequest$json = {
  '1': 'HistoryRequest',
  '2': [
    {'1': 'conversation_id', '3': 1, '4': 1, '5': 9, '10': 'conversationId'},
    {'1': 'before_seq', '3': 2, '4': 1, '5': 3, '10': 'beforeSeq'},
    {'1': 'limit', '3': 3, '4': 1, '5': 13, '10': 'limit'},
  ],
};

/// Descriptor for `HistoryRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List historyRequestDescriptor = $convert.base64Decode(
    'Cg5IaXN0b3J5UmVxdWVzdBInCg9jb252ZXJzYXRpb25faWQYASABKAlSDmNvbnZlcnNhdGlvbk'
    'lkEh0KCmJlZm9yZV9zZXEYAiABKANSCWJlZm9yZVNlcRIUCgVsaW1pdBgDIAEoDVIFbGltaXQ=');

@$core.Deprecated('Use createDirectConversationDescriptor instead')
const CreateDirectConversation$json = {
  '1': 'CreateDirectConversation',
  '2': [
    {'1': 'peer_user_id', '3': 1, '4': 1, '5': 9, '10': 'peerUserId'},
  ],
};

/// Descriptor for `CreateDirectConversation`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createDirectConversationDescriptor =
    $convert.base64Decode(
        'ChhDcmVhdGVEaXJlY3RDb252ZXJzYXRpb24SIAoMcGVlcl91c2VyX2lkGAEgASgJUgpwZWVyVX'
        'Nlcklk');

@$core.Deprecated('Use listConversationsDescriptor instead')
const ListConversations$json = {
  '1': 'ListConversations',
};

/// Descriptor for `ListConversations`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listConversationsDescriptor =
    $convert.base64Decode('ChFMaXN0Q29udmVyc2F0aW9ucw==');

@$core.Deprecated('Use createGroupDescriptor instead')
const CreateGroup$json = {
  '1': 'CreateGroup',
  '2': [
    {'1': 'title', '3': 1, '4': 1, '5': 9, '10': 'title'},
    {'1': 'member_user_ids', '3': 2, '4': 3, '5': 9, '10': 'memberUserIds'},
  ],
};

/// Descriptor for `CreateGroup`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createGroupDescriptor = $convert.base64Decode(
    'CgtDcmVhdGVHcm91cBIUCgV0aXRsZRgBIAEoCVIFdGl0bGUSJgoPbWVtYmVyX3VzZXJfaWRzGA'
    'IgAygJUg1tZW1iZXJVc2VySWRz');

@$core.Deprecated('Use addMembersDescriptor instead')
const AddMembers$json = {
  '1': 'AddMembers',
  '2': [
    {'1': 'conversation_id', '3': 1, '4': 1, '5': 9, '10': 'conversationId'},
    {'1': 'user_ids', '3': 2, '4': 3, '5': 9, '10': 'userIds'},
  ],
};

/// Descriptor for `AddMembers`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addMembersDescriptor = $convert.base64Decode(
    'CgpBZGRNZW1iZXJzEicKD2NvbnZlcnNhdGlvbl9pZBgBIAEoCVIOY29udmVyc2F0aW9uSWQSGQ'
    'oIdXNlcl9pZHMYAiADKAlSB3VzZXJJZHM=');

@$core.Deprecated('Use removeMemberDescriptor instead')
const RemoveMember$json = {
  '1': 'RemoveMember',
  '2': [
    {'1': 'conversation_id', '3': 1, '4': 1, '5': 9, '10': 'conversationId'},
    {'1': 'user_id', '3': 2, '4': 1, '5': 9, '10': 'userId'},
  ],
};

/// Descriptor for `RemoveMember`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List removeMemberDescriptor = $convert.base64Decode(
    'CgxSZW1vdmVNZW1iZXISJwoPY29udmVyc2F0aW9uX2lkGAEgASgJUg5jb252ZXJzYXRpb25JZB'
    'IXCgd1c2VyX2lkGAIgASgJUgZ1c2VySWQ=');

@$core.Deprecated('Use leaveConversationDescriptor instead')
const LeaveConversation$json = {
  '1': 'LeaveConversation',
  '2': [
    {'1': 'conversation_id', '3': 1, '4': 1, '5': 9, '10': 'conversationId'},
  ],
};

/// Descriptor for `LeaveConversation`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List leaveConversationDescriptor = $convert.base64Decode(
    'ChFMZWF2ZUNvbnZlcnNhdGlvbhInCg9jb252ZXJzYXRpb25faWQYASABKAlSDmNvbnZlcnNhdG'
    'lvbklk');

@$core.Deprecated('Use renameGroupDescriptor instead')
const RenameGroup$json = {
  '1': 'RenameGroup',
  '2': [
    {'1': 'conversation_id', '3': 1, '4': 1, '5': 9, '10': 'conversationId'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
  ],
};

/// Descriptor for `RenameGroup`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List renameGroupDescriptor = $convert.base64Decode(
    'CgtSZW5hbWVHcm91cBInCg9jb252ZXJzYXRpb25faWQYASABKAlSDmNvbnZlcnNhdGlvbklkEh'
    'QKBXRpdGxlGAIgASgJUgV0aXRsZQ==');

@$core.Deprecated('Use getPresenceDescriptor instead')
const GetPresence$json = {
  '1': 'GetPresence',
  '2': [
    {'1': 'user_ids', '3': 1, '4': 3, '5': 9, '10': 'userIds'},
  ],
};

/// Descriptor for `GetPresence`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getPresenceDescriptor = $convert
    .base64Decode('CgtHZXRQcmVzZW5jZRIZCgh1c2VyX2lkcxgBIAMoCVIHdXNlcklkcw==');

@$core.Deprecated('Use serverEnvelopeDescriptor instead')
const ServerEnvelope$json = {
  '1': 'ServerEnvelope',
  '2': [
    {'1': 'request_id', '3': 1, '4': 1, '5': 9, '10': 'requestId'},
    {
      '1': 'hello_ack',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.chat.v1.HelloAck',
      '9': 0,
      '10': 'helloAck'
    },
    {
      '1': 'accepted',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.chat.v1.MessageAccepted',
      '9': 0,
      '10': 'accepted'
    },
    {
      '1': 'new_message',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.chat.v1.ChatMessage',
      '9': 0,
      '10': 'newMessage'
    },
    {
      '1': 'error',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.chat.v1.ProtocolError',
      '9': 0,
      '10': 'error'
    },
    {
      '1': 'conversation_list',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.chat.v1.ConversationList',
      '9': 0,
      '10': 'conversationList'
    },
    {
      '1': 'conversation',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.chat.v1.ConversationInfo',
      '9': 0,
      '10': 'conversation'
    },
    {
      '1': 'batch',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.chat.v1.MessageBatch',
      '9': 0,
      '10': 'batch'
    },
    {
      '1': 'receipt',
      '3': 16,
      '4': 1,
      '5': 11,
      '6': '.chat.v1.ReceiptUpdate',
      '9': 0,
      '10': 'receipt'
    },
    {
      '1': 'typing',
      '3': 17,
      '4': 1,
      '5': 11,
      '6': '.chat.v1.TypingUpdate',
      '9': 0,
      '10': 'typing'
    },
    {
      '1': 'presence',
      '3': 18,
      '4': 1,
      '5': 11,
      '6': '.chat.v1.PresenceUpdate',
      '9': 0,
      '10': 'presence'
    },
    {
      '1': 'presence_snapshot',
      '3': 19,
      '4': 1,
      '5': 11,
      '6': '.chat.v1.PresenceSnapshot',
      '9': 0,
      '10': 'presenceSnapshot'
    },
    {
      '1': 'conversation_removed',
      '3': 20,
      '4': 1,
      '5': 11,
      '6': '.chat.v1.ConversationRemoved',
      '9': 0,
      '10': 'conversationRemoved'
    },
  ],
  '8': [
    {'1': 'body'},
  ],
};

/// Descriptor for `ServerEnvelope`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List serverEnvelopeDescriptor = $convert.base64Decode(
    'Cg5TZXJ2ZXJFbnZlbG9wZRIdCgpyZXF1ZXN0X2lkGAEgASgJUglyZXF1ZXN0SWQSMAoJaGVsbG'
    '9fYWNrGAkgASgLMhEuY2hhdC52MS5IZWxsb0Fja0gAUghoZWxsb0FjaxI2CghhY2NlcHRlZBgK'
    'IAEoCzIYLmNoYXQudjEuTWVzc2FnZUFjY2VwdGVkSABSCGFjY2VwdGVkEjcKC25ld19tZXNzYW'
    'dlGAsgASgLMhQuY2hhdC52MS5DaGF0TWVzc2FnZUgAUgpuZXdNZXNzYWdlEi4KBWVycm9yGAwg'
    'ASgLMhYuY2hhdC52MS5Qcm90b2NvbEVycm9ySABSBWVycm9yEkgKEWNvbnZlcnNhdGlvbl9saX'
    'N0GA0gASgLMhkuY2hhdC52MS5Db252ZXJzYXRpb25MaXN0SABSEGNvbnZlcnNhdGlvbkxpc3QS'
    'PwoMY29udmVyc2F0aW9uGA4gASgLMhkuY2hhdC52MS5Db252ZXJzYXRpb25JbmZvSABSDGNvbn'
    'ZlcnNhdGlvbhItCgViYXRjaBgPIAEoCzIVLmNoYXQudjEuTWVzc2FnZUJhdGNoSABSBWJhdGNo'
    'EjIKB3JlY2VpcHQYECABKAsyFi5jaGF0LnYxLlJlY2VpcHRVcGRhdGVIAFIHcmVjZWlwdBIvCg'
    'Z0eXBpbmcYESABKAsyFS5jaGF0LnYxLlR5cGluZ1VwZGF0ZUgAUgZ0eXBpbmcSNQoIcHJlc2Vu'
    'Y2UYEiABKAsyFy5jaGF0LnYxLlByZXNlbmNlVXBkYXRlSABSCHByZXNlbmNlEkgKEXByZXNlbm'
    'NlX3NuYXBzaG90GBMgASgLMhkuY2hhdC52MS5QcmVzZW5jZVNuYXBzaG90SABSEHByZXNlbmNl'
    'U25hcHNob3QSUQoUY29udmVyc2F0aW9uX3JlbW92ZWQYFCABKAsyHC5jaGF0LnYxLkNvbnZlcn'
    'NhdGlvblJlbW92ZWRIAFITY29udmVyc2F0aW9uUmVtb3ZlZEIGCgRib2R5');

@$core.Deprecated('Use helloAckDescriptor instead')
const HelloAck$json = {
  '1': 'HelloAck',
  '2': [
    {'1': 'protocol_version', '3': 1, '4': 1, '5': 13, '10': 'protocolVersion'},
    {'1': 'capabilities', '3': 2, '4': 3, '5': 9, '10': 'capabilities'},
    {'1': 'user_id', '3': 3, '4': 1, '5': 9, '10': 'userId'},
    {
      '1': 'server_time_unix_ms',
      '3': 4,
      '4': 1,
      '5': 3,
      '10': 'serverTimeUnixMs'
    },
    {
      '1': 'max_message_bytes',
      '3': 5,
      '4': 1,
      '5': 13,
      '10': 'maxMessageBytes'
    },
    {'1': 'max_text_chars', '3': 6, '4': 1, '5': 13, '10': 'maxTextChars'},
  ],
};

/// Descriptor for `HelloAck`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List helloAckDescriptor = $convert.base64Decode(
    'CghIZWxsb0FjaxIpChBwcm90b2NvbF92ZXJzaW9uGAEgASgNUg9wcm90b2NvbFZlcnNpb24SIg'
    'oMY2FwYWJpbGl0aWVzGAIgAygJUgxjYXBhYmlsaXRpZXMSFwoHdXNlcl9pZBgDIAEoCVIGdXNl'
    'cklkEi0KE3NlcnZlcl90aW1lX3VuaXhfbXMYBCABKANSEHNlcnZlclRpbWVVbml4TXMSKgoRbW'
    'F4X21lc3NhZ2VfYnl0ZXMYBSABKA1SD21heE1lc3NhZ2VCeXRlcxIkCg5tYXhfdGV4dF9jaGFy'
    'cxgGIAEoDVIMbWF4VGV4dENoYXJz');

@$core.Deprecated('Use messageAcceptedDescriptor instead')
const MessageAccepted$json = {
  '1': 'MessageAccepted',
  '2': [
    {'1': 'message_id', '3': 1, '4': 1, '5': 9, '10': 'messageId'},
    {'1': 'client_message_id', '3': 2, '4': 1, '5': 9, '10': 'clientMessageId'},
    {'1': 'seq', '3': 3, '4': 1, '5': 3, '10': 'seq'},
    {
      '1': 'created_at_unix_ms',
      '3': 4,
      '4': 1,
      '5': 3,
      '10': 'createdAtUnixMs'
    },
    {'1': 'duplicate', '3': 5, '4': 1, '5': 8, '10': 'duplicate'},
    {'1': 'conversation_id', '3': 6, '4': 1, '5': 9, '10': 'conversationId'},
  ],
};

/// Descriptor for `MessageAccepted`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List messageAcceptedDescriptor = $convert.base64Decode(
    'Cg9NZXNzYWdlQWNjZXB0ZWQSHQoKbWVzc2FnZV9pZBgBIAEoCVIJbWVzc2FnZUlkEioKEWNsaW'
    'VudF9tZXNzYWdlX2lkGAIgASgJUg9jbGllbnRNZXNzYWdlSWQSEAoDc2VxGAMgASgDUgNzZXES'
    'KwoSY3JlYXRlZF9hdF91bml4X21zGAQgASgDUg9jcmVhdGVkQXRVbml4TXMSHAoJZHVwbGljYX'
    'RlGAUgASgIUglkdXBsaWNhdGUSJwoPY29udmVyc2F0aW9uX2lkGAYgASgJUg5jb252ZXJzYXRp'
    'b25JZA==');

@$core.Deprecated('Use chatMessageDescriptor instead')
const ChatMessage$json = {
  '1': 'ChatMessage',
  '2': [
    {'1': 'message_id', '3': 1, '4': 1, '5': 9, '10': 'messageId'},
    {'1': 'conversation_id', '3': 2, '4': 1, '5': 9, '10': 'conversationId'},
    {'1': 'sender_id', '3': 3, '4': 1, '5': 9, '10': 'senderId'},
    {'1': 'client_message_id', '3': 4, '4': 1, '5': 9, '10': 'clientMessageId'},
    {'1': 'text', '3': 5, '4': 1, '5': 9, '10': 'text'},
    {
      '1': 'created_at_unix_ms',
      '3': 6,
      '4': 1,
      '5': 3,
      '10': 'createdAtUnixMs'
    },
    {'1': 'seq', '3': 7, '4': 1, '5': 3, '10': 'seq'},
  ],
};

/// Descriptor for `ChatMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chatMessageDescriptor = $convert.base64Decode(
    'CgtDaGF0TWVzc2FnZRIdCgptZXNzYWdlX2lkGAEgASgJUgltZXNzYWdlSWQSJwoPY29udmVyc2'
    'F0aW9uX2lkGAIgASgJUg5jb252ZXJzYXRpb25JZBIbCglzZW5kZXJfaWQYAyABKAlSCHNlbmRl'
    'cklkEioKEWNsaWVudF9tZXNzYWdlX2lkGAQgASgJUg9jbGllbnRNZXNzYWdlSWQSEgoEdGV4dB'
    'gFIAEoCVIEdGV4dBIrChJjcmVhdGVkX2F0X3VuaXhfbXMYBiABKANSD2NyZWF0ZWRBdFVuaXhN'
    'cxIQCgNzZXEYByABKANSA3NlcQ==');

@$core.Deprecated('Use messageBatchDescriptor instead')
const MessageBatch$json = {
  '1': 'MessageBatch',
  '2': [
    {'1': 'conversation_id', '3': 1, '4': 1, '5': 9, '10': 'conversationId'},
    {
      '1': 'messages',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.chat.v1.ChatMessage',
      '10': 'messages'
    },
    {'1': 'has_more', '3': 3, '4': 1, '5': 8, '10': 'hasMore'},
  ],
};

/// Descriptor for `MessageBatch`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List messageBatchDescriptor = $convert.base64Decode(
    'CgxNZXNzYWdlQmF0Y2gSJwoPY29udmVyc2F0aW9uX2lkGAEgASgJUg5jb252ZXJzYXRpb25JZB'
    'IwCghtZXNzYWdlcxgCIAMoCzIULmNoYXQudjEuQ2hhdE1lc3NhZ2VSCG1lc3NhZ2VzEhkKCGhh'
    'c19tb3JlGAMgASgIUgdoYXNNb3Jl');

@$core.Deprecated('Use memberDescriptor instead')
const Member$json = {
  '1': 'Member',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'username', '3': 2, '4': 1, '5': 9, '10': 'username'},
    {'1': 'display_name', '3': 3, '4': 1, '5': 9, '10': 'displayName'},
    {
      '1': 'delivered_up_to_seq',
      '3': 4,
      '4': 1,
      '5': 3,
      '10': 'deliveredUpToSeq'
    },
    {'1': 'read_up_to_seq', '3': 5, '4': 1, '5': 3, '10': 'readUpToSeq'},
    {
      '1': 'role',
      '3': 6,
      '4': 1,
      '5': 14,
      '6': '.chat.v1.MemberRole',
      '10': 'role'
    },
  ],
};

/// Descriptor for `Member`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List memberDescriptor = $convert.base64Decode(
    'CgZNZW1iZXISFwoHdXNlcl9pZBgBIAEoCVIGdXNlcklkEhoKCHVzZXJuYW1lGAIgASgJUgh1c2'
    'VybmFtZRIhCgxkaXNwbGF5X25hbWUYAyABKAlSC2Rpc3BsYXlOYW1lEi0KE2RlbGl2ZXJlZF91'
    'cF90b19zZXEYBCABKANSEGRlbGl2ZXJlZFVwVG9TZXESIwoOcmVhZF91cF90b19zZXEYBSABKA'
    'NSC3JlYWRVcFRvU2VxEicKBHJvbGUYBiABKA4yEy5jaGF0LnYxLk1lbWJlclJvbGVSBHJvbGU=');

@$core.Deprecated('Use conversationInfoDescriptor instead')
const ConversationInfo$json = {
  '1': 'ConversationInfo',
  '2': [
    {'1': 'conversation_id', '3': 1, '4': 1, '5': 9, '10': 'conversationId'},
    {
      '1': 'kind',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.chat.v1.ConversationKind',
      '10': 'kind'
    },
    {'1': 'title', '3': 3, '4': 1, '5': 9, '10': 'title'},
    {
      '1': 'members',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.chat.v1.Member',
      '10': 'members'
    },
    {'1': 'last_seq', '3': 5, '4': 1, '5': 3, '10': 'lastSeq'},
    {
      '1': 'last_activity_unix_ms',
      '3': 6,
      '4': 1,
      '5': 3,
      '10': 'lastActivityUnixMs'
    },
  ],
};

/// Descriptor for `ConversationInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List conversationInfoDescriptor = $convert.base64Decode(
    'ChBDb252ZXJzYXRpb25JbmZvEicKD2NvbnZlcnNhdGlvbl9pZBgBIAEoCVIOY29udmVyc2F0aW'
    '9uSWQSLQoEa2luZBgCIAEoDjIZLmNoYXQudjEuQ29udmVyc2F0aW9uS2luZFIEa2luZBIUCgV0'
    'aXRsZRgDIAEoCVIFdGl0bGUSKQoHbWVtYmVycxgEIAMoCzIPLmNoYXQudjEuTWVtYmVyUgdtZW'
    '1iZXJzEhkKCGxhc3Rfc2VxGAUgASgDUgdsYXN0U2VxEjEKFWxhc3RfYWN0aXZpdHlfdW5peF9t'
    'cxgGIAEoA1ISbGFzdEFjdGl2aXR5VW5peE1z');

@$core.Deprecated('Use conversationListDescriptor instead')
const ConversationList$json = {
  '1': 'ConversationList',
  '2': [
    {
      '1': 'conversations',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.chat.v1.ConversationInfo',
      '10': 'conversations'
    },
  ],
};

/// Descriptor for `ConversationList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List conversationListDescriptor = $convert.base64Decode(
    'ChBDb252ZXJzYXRpb25MaXN0Ej8KDWNvbnZlcnNhdGlvbnMYASADKAsyGS5jaGF0LnYxLkNvbn'
    'ZlcnNhdGlvbkluZm9SDWNvbnZlcnNhdGlvbnM=');

@$core.Deprecated('Use receiptUpdateDescriptor instead')
const ReceiptUpdate$json = {
  '1': 'ReceiptUpdate',
  '2': [
    {'1': 'conversation_id', '3': 1, '4': 1, '5': 9, '10': 'conversationId'},
    {'1': 'user_id', '3': 2, '4': 1, '5': 9, '10': 'userId'},
    {
      '1': 'delivered_up_to_seq',
      '3': 3,
      '4': 1,
      '5': 3,
      '10': 'deliveredUpToSeq'
    },
    {'1': 'read_up_to_seq', '3': 4, '4': 1, '5': 3, '10': 'readUpToSeq'},
  ],
};

/// Descriptor for `ReceiptUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List receiptUpdateDescriptor = $convert.base64Decode(
    'Cg1SZWNlaXB0VXBkYXRlEicKD2NvbnZlcnNhdGlvbl9pZBgBIAEoCVIOY29udmVyc2F0aW9uSW'
    'QSFwoHdXNlcl9pZBgCIAEoCVIGdXNlcklkEi0KE2RlbGl2ZXJlZF91cF90b19zZXEYAyABKANS'
    'EGRlbGl2ZXJlZFVwVG9TZXESIwoOcmVhZF91cF90b19zZXEYBCABKANSC3JlYWRVcFRvU2Vx');

@$core.Deprecated('Use protocolErrorDescriptor instead')
const ProtocolError$json = {
  '1': 'ProtocolError',
  '2': [
    {
      '1': 'code',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.chat.v1.ErrorCode',
      '10': 'code'
    },
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `ProtocolError`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List protocolErrorDescriptor = $convert.base64Decode(
    'Cg1Qcm90b2NvbEVycm9yEiYKBGNvZGUYASABKA4yEi5jaGF0LnYxLkVycm9yQ29kZVIEY29kZR'
    'IYCgdtZXNzYWdlGAIgASgJUgdtZXNzYWdl');

@$core.Deprecated('Use typingUpdateDescriptor instead')
const TypingUpdate$json = {
  '1': 'TypingUpdate',
  '2': [
    {'1': 'conversation_id', '3': 1, '4': 1, '5': 9, '10': 'conversationId'},
    {'1': 'user_id', '3': 2, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'is_typing', '3': 3, '4': 1, '5': 8, '10': 'isTyping'},
  ],
};

/// Descriptor for `TypingUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List typingUpdateDescriptor = $convert.base64Decode(
    'CgxUeXBpbmdVcGRhdGUSJwoPY29udmVyc2F0aW9uX2lkGAEgASgJUg5jb252ZXJzYXRpb25JZB'
    'IXCgd1c2VyX2lkGAIgASgJUgZ1c2VySWQSGwoJaXNfdHlwaW5nGAMgASgIUghpc1R5cGluZw==');

@$core.Deprecated('Use presenceUpdateDescriptor instead')
const PresenceUpdate$json = {
  '1': 'PresenceUpdate',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'online', '3': 2, '4': 1, '5': 8, '10': 'online'},
    {'1': 'last_seen_unix_ms', '3': 3, '4': 1, '5': 3, '10': 'lastSeenUnixMs'},
  ],
};

/// Descriptor for `PresenceUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List presenceUpdateDescriptor = $convert.base64Decode(
    'Cg5QcmVzZW5jZVVwZGF0ZRIXCgd1c2VyX2lkGAEgASgJUgZ1c2VySWQSFgoGb25saW5lGAIgAS'
    'gIUgZvbmxpbmUSKQoRbGFzdF9zZWVuX3VuaXhfbXMYAyABKANSDmxhc3RTZWVuVW5peE1z');

@$core.Deprecated('Use presenceSnapshotDescriptor instead')
const PresenceSnapshot$json = {
  '1': 'PresenceSnapshot',
  '2': [
    {
      '1': 'users',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.chat.v1.PresenceUpdate',
      '10': 'users'
    },
  ],
};

/// Descriptor for `PresenceSnapshot`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List presenceSnapshotDescriptor = $convert.base64Decode(
    'ChBQcmVzZW5jZVNuYXBzaG90Ei0KBXVzZXJzGAEgAygLMhcuY2hhdC52MS5QcmVzZW5jZVVwZG'
    'F0ZVIFdXNlcnM=');

@$core.Deprecated('Use conversationRemovedDescriptor instead')
const ConversationRemoved$json = {
  '1': 'ConversationRemoved',
  '2': [
    {'1': 'conversation_id', '3': 1, '4': 1, '5': 9, '10': 'conversationId'},
  ],
};

/// Descriptor for `ConversationRemoved`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List conversationRemovedDescriptor = $convert.base64Decode(
    'ChNDb252ZXJzYXRpb25SZW1vdmVkEicKD2NvbnZlcnNhdGlvbl9pZBgBIAEoCVIOY29udmVyc2'
    'F0aW9uSWQ=');
