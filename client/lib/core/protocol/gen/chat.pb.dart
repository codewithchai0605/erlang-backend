// This is a generated file - do not edit.
//
// Generated from chat.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'chat.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'chat.pbenum.dart';

enum ClientEnvelope_Body {
  hello,
  sendMessage,
  typing,
  markRead,
  syncRequest,
  ackDelivered,
  createDirect,
  listConversations,
  historyRequest,
  notSet
}

class ClientEnvelope extends $pb.GeneratedMessage {
  factory ClientEnvelope({
    $core.String? requestId,
    Hello? hello,
    SendMessage? sendMessage,
    TypingEvent? typing,
    MarkRead? markRead,
    SyncRequest? syncRequest,
    DeliveryAck? ackDelivered,
    CreateDirectConversation? createDirect,
    ListConversations? listConversations,
    HistoryRequest? historyRequest,
  }) {
    final result = ClientEnvelope._();
    if (requestId != null) result.requestId = requestId;
    if (hello != null) result.hello = hello;
    if (sendMessage != null) result.sendMessage = sendMessage;
    if (typing != null) result.typing = typing;
    if (markRead != null) result.markRead = markRead;
    if (syncRequest != null) result.syncRequest = syncRequest;
    if (ackDelivered != null) result.ackDelivered = ackDelivered;
    if (createDirect != null) result.createDirect = createDirect;
    if (listConversations != null) result.listConversations = listConversations;
    if (historyRequest != null) result.historyRequest = historyRequest;
    return result;
  }

  ClientEnvelope._();

  factory ClientEnvelope.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ClientEnvelope()..mergeFromBuffer(data, registry);
  factory ClientEnvelope.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ClientEnvelope()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ClientEnvelope_Body>
      _ClientEnvelope_BodyByTag = {
    9: ClientEnvelope_Body.hello,
    10: ClientEnvelope_Body.sendMessage,
    11: ClientEnvelope_Body.typing,
    12: ClientEnvelope_Body.markRead,
    13: ClientEnvelope_Body.syncRequest,
    14: ClientEnvelope_Body.ackDelivered,
    15: ClientEnvelope_Body.createDirect,
    16: ClientEnvelope_Body.listConversations,
    17: ClientEnvelope_Body.historyRequest,
    0: ClientEnvelope_Body.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClientEnvelope',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: ClientEnvelope.$_createMessage)
    ..oo(0, [9, 10, 11, 12, 13, 14, 15, 16, 17])
    ..aOS(1, _omitFieldNames ? '' : 'requestId')
    ..aOM<Hello>(9, _omitFieldNames ? '' : 'hello',
        subBuilder: Hello.$_createMessage)
    ..aOM<SendMessage>(10, _omitFieldNames ? '' : 'sendMessage',
        subBuilder: SendMessage.$_createMessage)
    ..aOM<TypingEvent>(11, _omitFieldNames ? '' : 'typing',
        subBuilder: TypingEvent.$_createMessage)
    ..aOM<MarkRead>(12, _omitFieldNames ? '' : 'markRead',
        subBuilder: MarkRead.$_createMessage)
    ..aOM<SyncRequest>(13, _omitFieldNames ? '' : 'syncRequest',
        subBuilder: SyncRequest.$_createMessage)
    ..aOM<DeliveryAck>(14, _omitFieldNames ? '' : 'ackDelivered',
        subBuilder: DeliveryAck.$_createMessage)
    ..aOM<CreateDirectConversation>(15, _omitFieldNames ? '' : 'createDirect',
        subBuilder: CreateDirectConversation.$_createMessage)
    ..aOM<ListConversations>(16, _omitFieldNames ? '' : 'listConversations',
        subBuilder: ListConversations.$_createMessage)
    ..aOM<HistoryRequest>(17, _omitFieldNames ? '' : 'historyRequest',
        subBuilder: HistoryRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClientEnvelope clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClientEnvelope copyWith(void Function(ClientEnvelope) updates) =>
      super.copyWith((message) => updates(message as ClientEnvelope))
          as ClientEnvelope;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ClientEnvelope() / ClientEnvelope.new instead')
  static ClientEnvelope create() => ClientEnvelope._();
  static $pb.GeneratedMessage $_createMessage() => ClientEnvelope._();
  @$core.override
  ClientEnvelope createEmptyInstance() => ClientEnvelope._();
  @$core.pragma('dart2js:noInline')
  static ClientEnvelope getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ClientEnvelope>(
          ClientEnvelope.$_createMessage);
  static ClientEnvelope? _defaultInstance;

  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  @$pb.TagNumber(14)
  @$pb.TagNumber(15)
  @$pb.TagNumber(16)
  @$pb.TagNumber(17)
  ClientEnvelope_Body whichBody() =>
      _ClientEnvelope_BodyByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  @$pb.TagNumber(14)
  @$pb.TagNumber(15)
  @$pb.TagNumber(16)
  @$pb.TagNumber(17)
  void clearBody() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get requestId => $_getSZ(0);
  @$pb.TagNumber(1)
  set requestId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRequestId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRequestId() => $_clearField(1);

  @$pb.TagNumber(9)
  Hello get hello => $_getN(1);
  @$pb.TagNumber(9)
  set hello(Hello value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasHello() => $_has(1);
  @$pb.TagNumber(9)
  void clearHello() => $_clearField(9);
  @$pb.TagNumber(9)
  Hello ensureHello() => $_ensure(1);

  @$pb.TagNumber(10)
  SendMessage get sendMessage => $_getN(2);
  @$pb.TagNumber(10)
  set sendMessage(SendMessage value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasSendMessage() => $_has(2);
  @$pb.TagNumber(10)
  void clearSendMessage() => $_clearField(10);
  @$pb.TagNumber(10)
  SendMessage ensureSendMessage() => $_ensure(2);

  @$pb.TagNumber(11)
  TypingEvent get typing => $_getN(3);
  @$pb.TagNumber(11)
  set typing(TypingEvent value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasTyping() => $_has(3);
  @$pb.TagNumber(11)
  void clearTyping() => $_clearField(11);
  @$pb.TagNumber(11)
  TypingEvent ensureTyping() => $_ensure(3);

  @$pb.TagNumber(12)
  MarkRead get markRead => $_getN(4);
  @$pb.TagNumber(12)
  set markRead(MarkRead value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasMarkRead() => $_has(4);
  @$pb.TagNumber(12)
  void clearMarkRead() => $_clearField(12);
  @$pb.TagNumber(12)
  MarkRead ensureMarkRead() => $_ensure(4);

  @$pb.TagNumber(13)
  SyncRequest get syncRequest => $_getN(5);
  @$pb.TagNumber(13)
  set syncRequest(SyncRequest value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasSyncRequest() => $_has(5);
  @$pb.TagNumber(13)
  void clearSyncRequest() => $_clearField(13);
  @$pb.TagNumber(13)
  SyncRequest ensureSyncRequest() => $_ensure(5);

  @$pb.TagNumber(14)
  DeliveryAck get ackDelivered => $_getN(6);
  @$pb.TagNumber(14)
  set ackDelivered(DeliveryAck value) => $_setField(14, value);
  @$pb.TagNumber(14)
  $core.bool hasAckDelivered() => $_has(6);
  @$pb.TagNumber(14)
  void clearAckDelivered() => $_clearField(14);
  @$pb.TagNumber(14)
  DeliveryAck ensureAckDelivered() => $_ensure(6);

  @$pb.TagNumber(15)
  CreateDirectConversation get createDirect => $_getN(7);
  @$pb.TagNumber(15)
  set createDirect(CreateDirectConversation value) => $_setField(15, value);
  @$pb.TagNumber(15)
  $core.bool hasCreateDirect() => $_has(7);
  @$pb.TagNumber(15)
  void clearCreateDirect() => $_clearField(15);
  @$pb.TagNumber(15)
  CreateDirectConversation ensureCreateDirect() => $_ensure(7);

  @$pb.TagNumber(16)
  ListConversations get listConversations => $_getN(8);
  @$pb.TagNumber(16)
  set listConversations(ListConversations value) => $_setField(16, value);
  @$pb.TagNumber(16)
  $core.bool hasListConversations() => $_has(8);
  @$pb.TagNumber(16)
  void clearListConversations() => $_clearField(16);
  @$pb.TagNumber(16)
  ListConversations ensureListConversations() => $_ensure(8);

  @$pb.TagNumber(17)
  HistoryRequest get historyRequest => $_getN(9);
  @$pb.TagNumber(17)
  set historyRequest(HistoryRequest value) => $_setField(17, value);
  @$pb.TagNumber(17)
  $core.bool hasHistoryRequest() => $_has(9);
  @$pb.TagNumber(17)
  void clearHistoryRequest() => $_clearField(17);
  @$pb.TagNumber(17)
  HistoryRequest ensureHistoryRequest() => $_ensure(9);
}

class Hello extends $pb.GeneratedMessage {
  factory Hello({
    $core.int? protocolVersion,
    $core.Iterable<$core.String>? capabilities,
    $core.String? accessToken,
  }) {
    final result = Hello._();
    if (protocolVersion != null) result.protocolVersion = protocolVersion;
    if (capabilities != null) result.capabilities.addAll(capabilities);
    if (accessToken != null) result.accessToken = accessToken;
    return result;
  }

  Hello._();

  factory Hello.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Hello()..mergeFromBuffer(data, registry);
  factory Hello.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Hello()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Hello',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: Hello.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'protocolVersion',
        fieldType: $pb.PbFieldType.OU3)
    ..pPS(2, _omitFieldNames ? '' : 'capabilities')
    ..aOS(3, _omitFieldNames ? '' : 'accessToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Hello clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Hello copyWith(void Function(Hello) updates) =>
      super.copyWith((message) => updates(message as Hello)) as Hello;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Hello() / Hello.new instead')
  static Hello create() => Hello._();
  static $pb.GeneratedMessage $_createMessage() => Hello._();
  @$core.override
  Hello createEmptyInstance() => Hello._();
  @$core.pragma('dart2js:noInline')
  static Hello getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Hello>(Hello.$_createMessage);
  static Hello? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get protocolVersion => $_getIZ(0);
  @$pb.TagNumber(1)
  set protocolVersion($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProtocolVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearProtocolVersion() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get capabilities => $_getList(1);

  @$pb.TagNumber(3)
  $core.String get accessToken => $_getSZ(2);
  @$pb.TagNumber(3)
  set accessToken($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAccessToken() => $_has(2);
  @$pb.TagNumber(3)
  void clearAccessToken() => $_clearField(3);
}

class SendMessage extends $pb.GeneratedMessage {
  factory SendMessage({
    $core.String? conversationId,
    $core.String? clientMessageId,
    $core.String? text,
  }) {
    final result = SendMessage._();
    if (conversationId != null) result.conversationId = conversationId;
    if (clientMessageId != null) result.clientMessageId = clientMessageId;
    if (text != null) result.text = text;
    return result;
  }

  SendMessage._();

  factory SendMessage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SendMessage()..mergeFromBuffer(data, registry);
  factory SendMessage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SendMessage()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SendMessage',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: SendMessage.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'conversationId')
    ..aOS(2, _omitFieldNames ? '' : 'clientMessageId')
    ..aOS(3, _omitFieldNames ? '' : 'text')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendMessage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendMessage copyWith(void Function(SendMessage) updates) =>
      super.copyWith((message) => updates(message as SendMessage))
          as SendMessage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SendMessage() / SendMessage.new instead')
  static SendMessage create() => SendMessage._();
  static $pb.GeneratedMessage $_createMessage() => SendMessage._();
  @$core.override
  SendMessage createEmptyInstance() => SendMessage._();
  @$core.pragma('dart2js:noInline')
  static SendMessage getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SendMessage>(
          SendMessage.$_createMessage);
  static SendMessage? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get conversationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set conversationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConversationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearConversationId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get clientMessageId => $_getSZ(1);
  @$pb.TagNumber(2)
  set clientMessageId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasClientMessageId() => $_has(1);
  @$pb.TagNumber(2)
  void clearClientMessageId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get text => $_getSZ(2);
  @$pb.TagNumber(3)
  set text($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasText() => $_has(2);
  @$pb.TagNumber(3)
  void clearText() => $_clearField(3);
}

class TypingEvent extends $pb.GeneratedMessage {
  factory TypingEvent({
    $core.String? conversationId,
    $core.bool? isTyping,
  }) {
    final result = TypingEvent._();
    if (conversationId != null) result.conversationId = conversationId;
    if (isTyping != null) result.isTyping = isTyping;
    return result;
  }

  TypingEvent._();

  factory TypingEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TypingEvent()..mergeFromBuffer(data, registry);
  factory TypingEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TypingEvent()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TypingEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: TypingEvent.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'conversationId')
    ..aOB(2, _omitFieldNames ? '' : 'isTyping')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TypingEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TypingEvent copyWith(void Function(TypingEvent) updates) =>
      super.copyWith((message) => updates(message as TypingEvent))
          as TypingEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TypingEvent() / TypingEvent.new instead')
  static TypingEvent create() => TypingEvent._();
  static $pb.GeneratedMessage $_createMessage() => TypingEvent._();
  @$core.override
  TypingEvent createEmptyInstance() => TypingEvent._();
  @$core.pragma('dart2js:noInline')
  static TypingEvent getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TypingEvent>(
          TypingEvent.$_createMessage);
  static TypingEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get conversationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set conversationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConversationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearConversationId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get isTyping => $_getBF(1);
  @$pb.TagNumber(2)
  set isTyping($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIsTyping() => $_has(1);
  @$pb.TagNumber(2)
  void clearIsTyping() => $_clearField(2);
}

class MarkRead extends $pb.GeneratedMessage {
  factory MarkRead({
    $core.String? conversationId,
    $fixnum.Int64? readUpToSeq,
  }) {
    final result = MarkRead._();
    if (conversationId != null) result.conversationId = conversationId;
    if (readUpToSeq != null) result.readUpToSeq = readUpToSeq;
    return result;
  }

  MarkRead._();

  factory MarkRead.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MarkRead()..mergeFromBuffer(data, registry);
  factory MarkRead.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MarkRead()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MarkRead',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: MarkRead.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'conversationId')
    ..aInt64(2, _omitFieldNames ? '' : 'readUpToSeq')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MarkRead clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MarkRead copyWith(void Function(MarkRead) updates) =>
      super.copyWith((message) => updates(message as MarkRead)) as MarkRead;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MarkRead() / MarkRead.new instead')
  static MarkRead create() => MarkRead._();
  static $pb.GeneratedMessage $_createMessage() => MarkRead._();
  @$core.override
  MarkRead createEmptyInstance() => MarkRead._();
  @$core.pragma('dart2js:noInline')
  static MarkRead getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MarkRead>(MarkRead.$_createMessage);
  static MarkRead? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get conversationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set conversationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConversationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearConversationId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get readUpToSeq => $_getI64(1);
  @$pb.TagNumber(2)
  set readUpToSeq($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasReadUpToSeq() => $_has(1);
  @$pb.TagNumber(2)
  void clearReadUpToSeq() => $_clearField(2);
}

class DeliveryAck extends $pb.GeneratedMessage {
  factory DeliveryAck({
    $core.String? conversationId,
    $fixnum.Int64? deliveredUpToSeq,
  }) {
    final result = DeliveryAck._();
    if (conversationId != null) result.conversationId = conversationId;
    if (deliveredUpToSeq != null) result.deliveredUpToSeq = deliveredUpToSeq;
    return result;
  }

  DeliveryAck._();

  factory DeliveryAck.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeliveryAck()..mergeFromBuffer(data, registry);
  factory DeliveryAck.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeliveryAck()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeliveryAck',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: DeliveryAck.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'conversationId')
    ..aInt64(2, _omitFieldNames ? '' : 'deliveredUpToSeq')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeliveryAck clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeliveryAck copyWith(void Function(DeliveryAck) updates) =>
      super.copyWith((message) => updates(message as DeliveryAck))
          as DeliveryAck;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DeliveryAck() / DeliveryAck.new instead')
  static DeliveryAck create() => DeliveryAck._();
  static $pb.GeneratedMessage $_createMessage() => DeliveryAck._();
  @$core.override
  DeliveryAck createEmptyInstance() => DeliveryAck._();
  @$core.pragma('dart2js:noInline')
  static DeliveryAck getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DeliveryAck>(
          DeliveryAck.$_createMessage);
  static DeliveryAck? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get conversationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set conversationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConversationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearConversationId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get deliveredUpToSeq => $_getI64(1);
  @$pb.TagNumber(2)
  set deliveredUpToSeq($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDeliveredUpToSeq() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeliveredUpToSeq() => $_clearField(2);
}

class SyncRequest extends $pb.GeneratedMessage {
  factory SyncRequest({
    $core.String? conversationId,
    $fixnum.Int64? afterSeq,
    $core.int? limit,
  }) {
    final result = SyncRequest._();
    if (conversationId != null) result.conversationId = conversationId;
    if (afterSeq != null) result.afterSeq = afterSeq;
    if (limit != null) result.limit = limit;
    return result;
  }

  SyncRequest._();

  factory SyncRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SyncRequest()..mergeFromBuffer(data, registry);
  factory SyncRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SyncRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SyncRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: SyncRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'conversationId')
    ..aInt64(2, _omitFieldNames ? '' : 'afterSeq')
    ..aI(3, _omitFieldNames ? '' : 'limit', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncRequest copyWith(void Function(SyncRequest) updates) =>
      super.copyWith((message) => updates(message as SyncRequest))
          as SyncRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SyncRequest() / SyncRequest.new instead')
  static SyncRequest create() => SyncRequest._();
  static $pb.GeneratedMessage $_createMessage() => SyncRequest._();
  @$core.override
  SyncRequest createEmptyInstance() => SyncRequest._();
  @$core.pragma('dart2js:noInline')
  static SyncRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SyncRequest>(
          SyncRequest.$_createMessage);
  static SyncRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get conversationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set conversationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConversationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearConversationId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get afterSeq => $_getI64(1);
  @$pb.TagNumber(2)
  set afterSeq($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAfterSeq() => $_has(1);
  @$pb.TagNumber(2)
  void clearAfterSeq() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get limit => $_getIZ(2);
  @$pb.TagNumber(3)
  set limit($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLimit() => $_has(2);
  @$pb.TagNumber(3)
  void clearLimit() => $_clearField(3);
}

class HistoryRequest extends $pb.GeneratedMessage {
  factory HistoryRequest({
    $core.String? conversationId,
    $fixnum.Int64? beforeSeq,
    $core.int? limit,
  }) {
    final result = HistoryRequest._();
    if (conversationId != null) result.conversationId = conversationId;
    if (beforeSeq != null) result.beforeSeq = beforeSeq;
    if (limit != null) result.limit = limit;
    return result;
  }

  HistoryRequest._();

  factory HistoryRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      HistoryRequest()..mergeFromBuffer(data, registry);
  factory HistoryRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      HistoryRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HistoryRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: HistoryRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'conversationId')
    ..aInt64(2, _omitFieldNames ? '' : 'beforeSeq')
    ..aI(3, _omitFieldNames ? '' : 'limit', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HistoryRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HistoryRequest copyWith(void Function(HistoryRequest) updates) =>
      super.copyWith((message) => updates(message as HistoryRequest))
          as HistoryRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use HistoryRequest() / HistoryRequest.new instead')
  static HistoryRequest create() => HistoryRequest._();
  static $pb.GeneratedMessage $_createMessage() => HistoryRequest._();
  @$core.override
  HistoryRequest createEmptyInstance() => HistoryRequest._();
  @$core.pragma('dart2js:noInline')
  static HistoryRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<HistoryRequest>(
          HistoryRequest.$_createMessage);
  static HistoryRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get conversationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set conversationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConversationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearConversationId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get beforeSeq => $_getI64(1);
  @$pb.TagNumber(2)
  set beforeSeq($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBeforeSeq() => $_has(1);
  @$pb.TagNumber(2)
  void clearBeforeSeq() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get limit => $_getIZ(2);
  @$pb.TagNumber(3)
  set limit($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLimit() => $_has(2);
  @$pb.TagNumber(3)
  void clearLimit() => $_clearField(3);
}

class CreateDirectConversation extends $pb.GeneratedMessage {
  factory CreateDirectConversation({
    $core.String? peerUserId,
  }) {
    final result = CreateDirectConversation._();
    if (peerUserId != null) result.peerUserId = peerUserId;
    return result;
  }

  CreateDirectConversation._();

  factory CreateDirectConversation.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateDirectConversation()..mergeFromBuffer(data, registry);
  factory CreateDirectConversation.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateDirectConversation()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateDirectConversation',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: CreateDirectConversation.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'peerUserId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateDirectConversation clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateDirectConversation copyWith(
          void Function(CreateDirectConversation) updates) =>
      super.copyWith((message) => updates(message as CreateDirectConversation))
          as CreateDirectConversation;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use CreateDirectConversation() / CreateDirectConversation.new instead')
  static CreateDirectConversation create() => CreateDirectConversation._();
  static $pb.GeneratedMessage $_createMessage() => CreateDirectConversation._();
  @$core.override
  CreateDirectConversation createEmptyInstance() =>
      CreateDirectConversation._();
  @$core.pragma('dart2js:noInline')
  static CreateDirectConversation getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateDirectConversation>(
          CreateDirectConversation.$_createMessage);
  static CreateDirectConversation? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get peerUserId => $_getSZ(0);
  @$pb.TagNumber(1)
  set peerUserId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPeerUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPeerUserId() => $_clearField(1);
}

class ListConversations extends $pb.GeneratedMessage {
  factory ListConversations() => ListConversations._();

  ListConversations._();

  factory ListConversations.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListConversations()..mergeFromBuffer(data, registry);
  factory ListConversations.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListConversations()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListConversations',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: ListConversations.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListConversations clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListConversations copyWith(void Function(ListConversations) updates) =>
      super.copyWith((message) => updates(message as ListConversations))
          as ListConversations;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ListConversations() / ListConversations.new instead')
  static ListConversations create() => ListConversations._();
  static $pb.GeneratedMessage $_createMessage() => ListConversations._();
  @$core.override
  ListConversations createEmptyInstance() => ListConversations._();
  @$core.pragma('dart2js:noInline')
  static ListConversations getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ListConversations>(
          ListConversations.$_createMessage);
  static ListConversations? _defaultInstance;
}

enum ServerEnvelope_Body {
  helloAck,
  accepted,
  newMessage,
  error,
  conversationList,
  conversation,
  batch,
  receipt,
  notSet
}

class ServerEnvelope extends $pb.GeneratedMessage {
  factory ServerEnvelope({
    $core.String? requestId,
    HelloAck? helloAck,
    MessageAccepted? accepted,
    ChatMessage? newMessage,
    ProtocolError? error,
    ConversationList? conversationList,
    ConversationInfo? conversation,
    MessageBatch? batch,
    ReceiptUpdate? receipt,
  }) {
    final result = ServerEnvelope._();
    if (requestId != null) result.requestId = requestId;
    if (helloAck != null) result.helloAck = helloAck;
    if (accepted != null) result.accepted = accepted;
    if (newMessage != null) result.newMessage = newMessage;
    if (error != null) result.error = error;
    if (conversationList != null) result.conversationList = conversationList;
    if (conversation != null) result.conversation = conversation;
    if (batch != null) result.batch = batch;
    if (receipt != null) result.receipt = receipt;
    return result;
  }

  ServerEnvelope._();

  factory ServerEnvelope.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ServerEnvelope()..mergeFromBuffer(data, registry);
  factory ServerEnvelope.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ServerEnvelope()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ServerEnvelope_Body>
      _ServerEnvelope_BodyByTag = {
    9: ServerEnvelope_Body.helloAck,
    10: ServerEnvelope_Body.accepted,
    11: ServerEnvelope_Body.newMessage,
    12: ServerEnvelope_Body.error,
    13: ServerEnvelope_Body.conversationList,
    14: ServerEnvelope_Body.conversation,
    15: ServerEnvelope_Body.batch,
    16: ServerEnvelope_Body.receipt,
    0: ServerEnvelope_Body.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ServerEnvelope',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: ServerEnvelope.$_createMessage)
    ..oo(0, [9, 10, 11, 12, 13, 14, 15, 16])
    ..aOS(1, _omitFieldNames ? '' : 'requestId')
    ..aOM<HelloAck>(9, _omitFieldNames ? '' : 'helloAck',
        subBuilder: HelloAck.$_createMessage)
    ..aOM<MessageAccepted>(10, _omitFieldNames ? '' : 'accepted',
        subBuilder: MessageAccepted.$_createMessage)
    ..aOM<ChatMessage>(11, _omitFieldNames ? '' : 'newMessage',
        subBuilder: ChatMessage.$_createMessage)
    ..aOM<ProtocolError>(12, _omitFieldNames ? '' : 'error',
        subBuilder: ProtocolError.$_createMessage)
    ..aOM<ConversationList>(13, _omitFieldNames ? '' : 'conversationList',
        subBuilder: ConversationList.$_createMessage)
    ..aOM<ConversationInfo>(14, _omitFieldNames ? '' : 'conversation',
        subBuilder: ConversationInfo.$_createMessage)
    ..aOM<MessageBatch>(15, _omitFieldNames ? '' : 'batch',
        subBuilder: MessageBatch.$_createMessage)
    ..aOM<ReceiptUpdate>(16, _omitFieldNames ? '' : 'receipt',
        subBuilder: ReceiptUpdate.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServerEnvelope clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServerEnvelope copyWith(void Function(ServerEnvelope) updates) =>
      super.copyWith((message) => updates(message as ServerEnvelope))
          as ServerEnvelope;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ServerEnvelope() / ServerEnvelope.new instead')
  static ServerEnvelope create() => ServerEnvelope._();
  static $pb.GeneratedMessage $_createMessage() => ServerEnvelope._();
  @$core.override
  ServerEnvelope createEmptyInstance() => ServerEnvelope._();
  @$core.pragma('dart2js:noInline')
  static ServerEnvelope getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ServerEnvelope>(
          ServerEnvelope.$_createMessage);
  static ServerEnvelope? _defaultInstance;

  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  @$pb.TagNumber(14)
  @$pb.TagNumber(15)
  @$pb.TagNumber(16)
  ServerEnvelope_Body whichBody() =>
      _ServerEnvelope_BodyByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  @$pb.TagNumber(14)
  @$pb.TagNumber(15)
  @$pb.TagNumber(16)
  void clearBody() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get requestId => $_getSZ(0);
  @$pb.TagNumber(1)
  set requestId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRequestId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRequestId() => $_clearField(1);

  @$pb.TagNumber(9)
  HelloAck get helloAck => $_getN(1);
  @$pb.TagNumber(9)
  set helloAck(HelloAck value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasHelloAck() => $_has(1);
  @$pb.TagNumber(9)
  void clearHelloAck() => $_clearField(9);
  @$pb.TagNumber(9)
  HelloAck ensureHelloAck() => $_ensure(1);

  @$pb.TagNumber(10)
  MessageAccepted get accepted => $_getN(2);
  @$pb.TagNumber(10)
  set accepted(MessageAccepted value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasAccepted() => $_has(2);
  @$pb.TagNumber(10)
  void clearAccepted() => $_clearField(10);
  @$pb.TagNumber(10)
  MessageAccepted ensureAccepted() => $_ensure(2);

  @$pb.TagNumber(11)
  ChatMessage get newMessage => $_getN(3);
  @$pb.TagNumber(11)
  set newMessage(ChatMessage value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasNewMessage() => $_has(3);
  @$pb.TagNumber(11)
  void clearNewMessage() => $_clearField(11);
  @$pb.TagNumber(11)
  ChatMessage ensureNewMessage() => $_ensure(3);

  @$pb.TagNumber(12)
  ProtocolError get error => $_getN(4);
  @$pb.TagNumber(12)
  set error(ProtocolError value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasError() => $_has(4);
  @$pb.TagNumber(12)
  void clearError() => $_clearField(12);
  @$pb.TagNumber(12)
  ProtocolError ensureError() => $_ensure(4);

  @$pb.TagNumber(13)
  ConversationList get conversationList => $_getN(5);
  @$pb.TagNumber(13)
  set conversationList(ConversationList value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasConversationList() => $_has(5);
  @$pb.TagNumber(13)
  void clearConversationList() => $_clearField(13);
  @$pb.TagNumber(13)
  ConversationList ensureConversationList() => $_ensure(5);

  @$pb.TagNumber(14)
  ConversationInfo get conversation => $_getN(6);
  @$pb.TagNumber(14)
  set conversation(ConversationInfo value) => $_setField(14, value);
  @$pb.TagNumber(14)
  $core.bool hasConversation() => $_has(6);
  @$pb.TagNumber(14)
  void clearConversation() => $_clearField(14);
  @$pb.TagNumber(14)
  ConversationInfo ensureConversation() => $_ensure(6);

  @$pb.TagNumber(15)
  MessageBatch get batch => $_getN(7);
  @$pb.TagNumber(15)
  set batch(MessageBatch value) => $_setField(15, value);
  @$pb.TagNumber(15)
  $core.bool hasBatch() => $_has(7);
  @$pb.TagNumber(15)
  void clearBatch() => $_clearField(15);
  @$pb.TagNumber(15)
  MessageBatch ensureBatch() => $_ensure(7);

  @$pb.TagNumber(16)
  ReceiptUpdate get receipt => $_getN(8);
  @$pb.TagNumber(16)
  set receipt(ReceiptUpdate value) => $_setField(16, value);
  @$pb.TagNumber(16)
  $core.bool hasReceipt() => $_has(8);
  @$pb.TagNumber(16)
  void clearReceipt() => $_clearField(16);
  @$pb.TagNumber(16)
  ReceiptUpdate ensureReceipt() => $_ensure(8);
}

class HelloAck extends $pb.GeneratedMessage {
  factory HelloAck({
    $core.int? protocolVersion,
    $core.Iterable<$core.String>? capabilities,
    $core.String? userId,
    $fixnum.Int64? serverTimeUnixMs,
    $core.int? maxMessageBytes,
    $core.int? maxTextChars,
  }) {
    final result = HelloAck._();
    if (protocolVersion != null) result.protocolVersion = protocolVersion;
    if (capabilities != null) result.capabilities.addAll(capabilities);
    if (userId != null) result.userId = userId;
    if (serverTimeUnixMs != null) result.serverTimeUnixMs = serverTimeUnixMs;
    if (maxMessageBytes != null) result.maxMessageBytes = maxMessageBytes;
    if (maxTextChars != null) result.maxTextChars = maxTextChars;
    return result;
  }

  HelloAck._();

  factory HelloAck.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      HelloAck()..mergeFromBuffer(data, registry);
  factory HelloAck.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      HelloAck()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HelloAck',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: HelloAck.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'protocolVersion',
        fieldType: $pb.PbFieldType.OU3)
    ..pPS(2, _omitFieldNames ? '' : 'capabilities')
    ..aOS(3, _omitFieldNames ? '' : 'userId')
    ..aInt64(4, _omitFieldNames ? '' : 'serverTimeUnixMs')
    ..aI(5, _omitFieldNames ? '' : 'maxMessageBytes',
        fieldType: $pb.PbFieldType.OU3)
    ..aI(6, _omitFieldNames ? '' : 'maxTextChars',
        fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HelloAck clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HelloAck copyWith(void Function(HelloAck) updates) =>
      super.copyWith((message) => updates(message as HelloAck)) as HelloAck;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use HelloAck() / HelloAck.new instead')
  static HelloAck create() => HelloAck._();
  static $pb.GeneratedMessage $_createMessage() => HelloAck._();
  @$core.override
  HelloAck createEmptyInstance() => HelloAck._();
  @$core.pragma('dart2js:noInline')
  static HelloAck getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HelloAck>(HelloAck.$_createMessage);
  static HelloAck? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get protocolVersion => $_getIZ(0);
  @$pb.TagNumber(1)
  set protocolVersion($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProtocolVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearProtocolVersion() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get capabilities => $_getList(1);

  @$pb.TagNumber(3)
  $core.String get userId => $_getSZ(2);
  @$pb.TagNumber(3)
  set userId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUserId() => $_has(2);
  @$pb.TagNumber(3)
  void clearUserId() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get serverTimeUnixMs => $_getI64(3);
  @$pb.TagNumber(4)
  set serverTimeUnixMs($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasServerTimeUnixMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearServerTimeUnixMs() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get maxMessageBytes => $_getIZ(4);
  @$pb.TagNumber(5)
  set maxMessageBytes($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMaxMessageBytes() => $_has(4);
  @$pb.TagNumber(5)
  void clearMaxMessageBytes() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get maxTextChars => $_getIZ(5);
  @$pb.TagNumber(6)
  set maxTextChars($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasMaxTextChars() => $_has(5);
  @$pb.TagNumber(6)
  void clearMaxTextChars() => $_clearField(6);
}

class MessageAccepted extends $pb.GeneratedMessage {
  factory MessageAccepted({
    $core.String? messageId,
    $core.String? clientMessageId,
    $fixnum.Int64? seq,
    $fixnum.Int64? createdAtUnixMs,
    $core.bool? duplicate,
    $core.String? conversationId,
  }) {
    final result = MessageAccepted._();
    if (messageId != null) result.messageId = messageId;
    if (clientMessageId != null) result.clientMessageId = clientMessageId;
    if (seq != null) result.seq = seq;
    if (createdAtUnixMs != null) result.createdAtUnixMs = createdAtUnixMs;
    if (duplicate != null) result.duplicate = duplicate;
    if (conversationId != null) result.conversationId = conversationId;
    return result;
  }

  MessageAccepted._();

  factory MessageAccepted.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MessageAccepted()..mergeFromBuffer(data, registry);
  factory MessageAccepted.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MessageAccepted()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MessageAccepted',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: MessageAccepted.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'messageId')
    ..aOS(2, _omitFieldNames ? '' : 'clientMessageId')
    ..aInt64(3, _omitFieldNames ? '' : 'seq')
    ..aInt64(4, _omitFieldNames ? '' : 'createdAtUnixMs')
    ..aOB(5, _omitFieldNames ? '' : 'duplicate')
    ..aOS(6, _omitFieldNames ? '' : 'conversationId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessageAccepted clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessageAccepted copyWith(void Function(MessageAccepted) updates) =>
      super.copyWith((message) => updates(message as MessageAccepted))
          as MessageAccepted;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MessageAccepted() / MessageAccepted.new instead')
  static MessageAccepted create() => MessageAccepted._();
  static $pb.GeneratedMessage $_createMessage() => MessageAccepted._();
  @$core.override
  MessageAccepted createEmptyInstance() => MessageAccepted._();
  @$core.pragma('dart2js:noInline')
  static MessageAccepted getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MessageAccepted>(
          MessageAccepted.$_createMessage);
  static MessageAccepted? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get messageId => $_getSZ(0);
  @$pb.TagNumber(1)
  set messageId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessageId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessageId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get clientMessageId => $_getSZ(1);
  @$pb.TagNumber(2)
  set clientMessageId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasClientMessageId() => $_has(1);
  @$pb.TagNumber(2)
  void clearClientMessageId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get seq => $_getI64(2);
  @$pb.TagNumber(3)
  set seq($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSeq() => $_has(2);
  @$pb.TagNumber(3)
  void clearSeq() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get createdAtUnixMs => $_getI64(3);
  @$pb.TagNumber(4)
  set createdAtUnixMs($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCreatedAtUnixMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearCreatedAtUnixMs() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get duplicate => $_getBF(4);
  @$pb.TagNumber(5)
  set duplicate($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDuplicate() => $_has(4);
  @$pb.TagNumber(5)
  void clearDuplicate() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get conversationId => $_getSZ(5);
  @$pb.TagNumber(6)
  set conversationId($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasConversationId() => $_has(5);
  @$pb.TagNumber(6)
  void clearConversationId() => $_clearField(6);
}

class ChatMessage extends $pb.GeneratedMessage {
  factory ChatMessage({
    $core.String? messageId,
    $core.String? conversationId,
    $core.String? senderId,
    $core.String? clientMessageId,
    $core.String? text,
    $fixnum.Int64? createdAtUnixMs,
    $fixnum.Int64? seq,
  }) {
    final result = ChatMessage._();
    if (messageId != null) result.messageId = messageId;
    if (conversationId != null) result.conversationId = conversationId;
    if (senderId != null) result.senderId = senderId;
    if (clientMessageId != null) result.clientMessageId = clientMessageId;
    if (text != null) result.text = text;
    if (createdAtUnixMs != null) result.createdAtUnixMs = createdAtUnixMs;
    if (seq != null) result.seq = seq;
    return result;
  }

  ChatMessage._();

  factory ChatMessage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ChatMessage()..mergeFromBuffer(data, registry);
  factory ChatMessage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ChatMessage()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChatMessage',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: ChatMessage.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'messageId')
    ..aOS(2, _omitFieldNames ? '' : 'conversationId')
    ..aOS(3, _omitFieldNames ? '' : 'senderId')
    ..aOS(4, _omitFieldNames ? '' : 'clientMessageId')
    ..aOS(5, _omitFieldNames ? '' : 'text')
    ..aInt64(6, _omitFieldNames ? '' : 'createdAtUnixMs')
    ..aInt64(7, _omitFieldNames ? '' : 'seq')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChatMessage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChatMessage copyWith(void Function(ChatMessage) updates) =>
      super.copyWith((message) => updates(message as ChatMessage))
          as ChatMessage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ChatMessage() / ChatMessage.new instead')
  static ChatMessage create() => ChatMessage._();
  static $pb.GeneratedMessage $_createMessage() => ChatMessage._();
  @$core.override
  ChatMessage createEmptyInstance() => ChatMessage._();
  @$core.pragma('dart2js:noInline')
  static ChatMessage getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ChatMessage>(
          ChatMessage.$_createMessage);
  static ChatMessage? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get messageId => $_getSZ(0);
  @$pb.TagNumber(1)
  set messageId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessageId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessageId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get conversationId => $_getSZ(1);
  @$pb.TagNumber(2)
  set conversationId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasConversationId() => $_has(1);
  @$pb.TagNumber(2)
  void clearConversationId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get senderId => $_getSZ(2);
  @$pb.TagNumber(3)
  set senderId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSenderId() => $_has(2);
  @$pb.TagNumber(3)
  void clearSenderId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get clientMessageId => $_getSZ(3);
  @$pb.TagNumber(4)
  set clientMessageId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasClientMessageId() => $_has(3);
  @$pb.TagNumber(4)
  void clearClientMessageId() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get text => $_getSZ(4);
  @$pb.TagNumber(5)
  set text($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasText() => $_has(4);
  @$pb.TagNumber(5)
  void clearText() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get createdAtUnixMs => $_getI64(5);
  @$pb.TagNumber(6)
  set createdAtUnixMs($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasCreatedAtUnixMs() => $_has(5);
  @$pb.TagNumber(6)
  void clearCreatedAtUnixMs() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get seq => $_getI64(6);
  @$pb.TagNumber(7)
  set seq($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasSeq() => $_has(6);
  @$pb.TagNumber(7)
  void clearSeq() => $_clearField(7);
}

class MessageBatch extends $pb.GeneratedMessage {
  factory MessageBatch({
    $core.String? conversationId,
    $core.Iterable<ChatMessage>? messages,
    $core.bool? hasMore,
  }) {
    final result = MessageBatch._();
    if (conversationId != null) result.conversationId = conversationId;
    if (messages != null) result.messages.addAll(messages);
    if (hasMore != null) result.hasMore = hasMore;
    return result;
  }

  MessageBatch._();

  factory MessageBatch.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MessageBatch()..mergeFromBuffer(data, registry);
  factory MessageBatch.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MessageBatch()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MessageBatch',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: MessageBatch.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'conversationId')
    ..pPM<ChatMessage>(2, _omitFieldNames ? '' : 'messages',
        subBuilder: ChatMessage.$_createMessage)
    ..aOB(3, _omitFieldNames ? '' : 'hasMore')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessageBatch clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessageBatch copyWith(void Function(MessageBatch) updates) =>
      super.copyWith((message) => updates(message as MessageBatch))
          as MessageBatch;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MessageBatch() / MessageBatch.new instead')
  static MessageBatch create() => MessageBatch._();
  static $pb.GeneratedMessage $_createMessage() => MessageBatch._();
  @$core.override
  MessageBatch createEmptyInstance() => MessageBatch._();
  @$core.pragma('dart2js:noInline')
  static MessageBatch getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MessageBatch>(
          MessageBatch.$_createMessage);
  static MessageBatch? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get conversationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set conversationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConversationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearConversationId() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<ChatMessage> get messages => $_getList(1);

  @$pb.TagNumber(3)
  $core.bool get hasMore => $_getBF(2);
  @$pb.TagNumber(3)
  set hasMore($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHasMore() => $_has(2);
  @$pb.TagNumber(3)
  void clearHasMore() => $_clearField(3);
}

class Member extends $pb.GeneratedMessage {
  factory Member({
    $core.String? userId,
    $core.String? username,
    $core.String? displayName,
    $fixnum.Int64? deliveredUpToSeq,
    $fixnum.Int64? readUpToSeq,
  }) {
    final result = Member._();
    if (userId != null) result.userId = userId;
    if (username != null) result.username = username;
    if (displayName != null) result.displayName = displayName;
    if (deliveredUpToSeq != null) result.deliveredUpToSeq = deliveredUpToSeq;
    if (readUpToSeq != null) result.readUpToSeq = readUpToSeq;
    return result;
  }

  Member._();

  factory Member.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Member()..mergeFromBuffer(data, registry);
  factory Member.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Member()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Member',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: Member.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..aOS(2, _omitFieldNames ? '' : 'username')
    ..aOS(3, _omitFieldNames ? '' : 'displayName')
    ..aInt64(4, _omitFieldNames ? '' : 'deliveredUpToSeq')
    ..aInt64(5, _omitFieldNames ? '' : 'readUpToSeq')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Member clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Member copyWith(void Function(Member) updates) =>
      super.copyWith((message) => updates(message as Member)) as Member;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Member() / Member.new instead')
  static Member create() => Member._();
  static $pb.GeneratedMessage $_createMessage() => Member._();
  @$core.override
  Member createEmptyInstance() => Member._();
  @$core.pragma('dart2js:noInline')
  static Member getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Member>(Member.$_createMessage);
  static Member? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get username => $_getSZ(1);
  @$pb.TagNumber(2)
  set username($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUsername() => $_has(1);
  @$pb.TagNumber(2)
  void clearUsername() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get displayName => $_getSZ(2);
  @$pb.TagNumber(3)
  set displayName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDisplayName() => $_has(2);
  @$pb.TagNumber(3)
  void clearDisplayName() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get deliveredUpToSeq => $_getI64(3);
  @$pb.TagNumber(4)
  set deliveredUpToSeq($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDeliveredUpToSeq() => $_has(3);
  @$pb.TagNumber(4)
  void clearDeliveredUpToSeq() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get readUpToSeq => $_getI64(4);
  @$pb.TagNumber(5)
  set readUpToSeq($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasReadUpToSeq() => $_has(4);
  @$pb.TagNumber(5)
  void clearReadUpToSeq() => $_clearField(5);
}

class ConversationInfo extends $pb.GeneratedMessage {
  factory ConversationInfo({
    $core.String? conversationId,
    ConversationKind? kind,
    $core.String? title,
    $core.Iterable<Member>? members,
    $fixnum.Int64? lastSeq,
    $fixnum.Int64? lastActivityUnixMs,
  }) {
    final result = ConversationInfo._();
    if (conversationId != null) result.conversationId = conversationId;
    if (kind != null) result.kind = kind;
    if (title != null) result.title = title;
    if (members != null) result.members.addAll(members);
    if (lastSeq != null) result.lastSeq = lastSeq;
    if (lastActivityUnixMs != null)
      result.lastActivityUnixMs = lastActivityUnixMs;
    return result;
  }

  ConversationInfo._();

  factory ConversationInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConversationInfo()..mergeFromBuffer(data, registry);
  factory ConversationInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConversationInfo()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ConversationInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: ConversationInfo.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'conversationId')
    ..aE<ConversationKind>(2, _omitFieldNames ? '' : 'kind',
        enumValues: ConversationKind.values)
    ..aOS(3, _omitFieldNames ? '' : 'title')
    ..pPM<Member>(4, _omitFieldNames ? '' : 'members',
        subBuilder: Member.$_createMessage)
    ..aInt64(5, _omitFieldNames ? '' : 'lastSeq')
    ..aInt64(6, _omitFieldNames ? '' : 'lastActivityUnixMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConversationInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConversationInfo copyWith(void Function(ConversationInfo) updates) =>
      super.copyWith((message) => updates(message as ConversationInfo))
          as ConversationInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ConversationInfo() / ConversationInfo.new instead')
  static ConversationInfo create() => ConversationInfo._();
  static $pb.GeneratedMessage $_createMessage() => ConversationInfo._();
  @$core.override
  ConversationInfo createEmptyInstance() => ConversationInfo._();
  @$core.pragma('dart2js:noInline')
  static ConversationInfo getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ConversationInfo>(
          ConversationInfo.$_createMessage);
  static ConversationInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get conversationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set conversationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConversationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearConversationId() => $_clearField(1);

  @$pb.TagNumber(2)
  ConversationKind get kind => $_getN(1);
  @$pb.TagNumber(2)
  set kind(ConversationKind value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearKind() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get title => $_getSZ(2);
  @$pb.TagNumber(3)
  set title($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTitle() => $_has(2);
  @$pb.TagNumber(3)
  void clearTitle() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<Member> get members => $_getList(3);

  @$pb.TagNumber(5)
  $fixnum.Int64 get lastSeq => $_getI64(4);
  @$pb.TagNumber(5)
  set lastSeq($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasLastSeq() => $_has(4);
  @$pb.TagNumber(5)
  void clearLastSeq() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get lastActivityUnixMs => $_getI64(5);
  @$pb.TagNumber(6)
  set lastActivityUnixMs($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasLastActivityUnixMs() => $_has(5);
  @$pb.TagNumber(6)
  void clearLastActivityUnixMs() => $_clearField(6);
}

class ConversationList extends $pb.GeneratedMessage {
  factory ConversationList({
    $core.Iterable<ConversationInfo>? conversations,
  }) {
    final result = ConversationList._();
    if (conversations != null) result.conversations.addAll(conversations);
    return result;
  }

  ConversationList._();

  factory ConversationList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConversationList()..mergeFromBuffer(data, registry);
  factory ConversationList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConversationList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ConversationList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: ConversationList.$_createMessage)
    ..pPM<ConversationInfo>(1, _omitFieldNames ? '' : 'conversations',
        subBuilder: ConversationInfo.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConversationList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConversationList copyWith(void Function(ConversationList) updates) =>
      super.copyWith((message) => updates(message as ConversationList))
          as ConversationList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ConversationList() / ConversationList.new instead')
  static ConversationList create() => ConversationList._();
  static $pb.GeneratedMessage $_createMessage() => ConversationList._();
  @$core.override
  ConversationList createEmptyInstance() => ConversationList._();
  @$core.pragma('dart2js:noInline')
  static ConversationList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ConversationList>(
          ConversationList.$_createMessage);
  static ConversationList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ConversationInfo> get conversations => $_getList(0);
}

class ReceiptUpdate extends $pb.GeneratedMessage {
  factory ReceiptUpdate({
    $core.String? conversationId,
    $core.String? userId,
    $fixnum.Int64? deliveredUpToSeq,
    $fixnum.Int64? readUpToSeq,
  }) {
    final result = ReceiptUpdate._();
    if (conversationId != null) result.conversationId = conversationId;
    if (userId != null) result.userId = userId;
    if (deliveredUpToSeq != null) result.deliveredUpToSeq = deliveredUpToSeq;
    if (readUpToSeq != null) result.readUpToSeq = readUpToSeq;
    return result;
  }

  ReceiptUpdate._();

  factory ReceiptUpdate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReceiptUpdate()..mergeFromBuffer(data, registry);
  factory ReceiptUpdate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReceiptUpdate()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReceiptUpdate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: ReceiptUpdate.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'conversationId')
    ..aOS(2, _omitFieldNames ? '' : 'userId')
    ..aInt64(3, _omitFieldNames ? '' : 'deliveredUpToSeq')
    ..aInt64(4, _omitFieldNames ? '' : 'readUpToSeq')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReceiptUpdate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReceiptUpdate copyWith(void Function(ReceiptUpdate) updates) =>
      super.copyWith((message) => updates(message as ReceiptUpdate))
          as ReceiptUpdate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReceiptUpdate() / ReceiptUpdate.new instead')
  static ReceiptUpdate create() => ReceiptUpdate._();
  static $pb.GeneratedMessage $_createMessage() => ReceiptUpdate._();
  @$core.override
  ReceiptUpdate createEmptyInstance() => ReceiptUpdate._();
  @$core.pragma('dart2js:noInline')
  static ReceiptUpdate getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReceiptUpdate>(
          ReceiptUpdate.$_createMessage);
  static ReceiptUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get conversationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set conversationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConversationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearConversationId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get userId => $_getSZ(1);
  @$pb.TagNumber(2)
  set userId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearUserId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get deliveredUpToSeq => $_getI64(2);
  @$pb.TagNumber(3)
  set deliveredUpToSeq($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDeliveredUpToSeq() => $_has(2);
  @$pb.TagNumber(3)
  void clearDeliveredUpToSeq() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get readUpToSeq => $_getI64(3);
  @$pb.TagNumber(4)
  set readUpToSeq($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasReadUpToSeq() => $_has(3);
  @$pb.TagNumber(4)
  void clearReadUpToSeq() => $_clearField(4);
}

class ProtocolError extends $pb.GeneratedMessage {
  factory ProtocolError({
    ErrorCode? code,
    $core.String? message,
  }) {
    final result = ProtocolError._();
    if (code != null) result.code = code;
    if (message != null) result.message = message;
    return result;
  }

  ProtocolError._();

  factory ProtocolError.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ProtocolError()..mergeFromBuffer(data, registry);
  factory ProtocolError.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ProtocolError()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProtocolError',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: ProtocolError.$_createMessage)
    ..aE<ErrorCode>(1, _omitFieldNames ? '' : 'code',
        enumValues: ErrorCode.values)
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtocolError clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtocolError copyWith(void Function(ProtocolError) updates) =>
      super.copyWith((message) => updates(message as ProtocolError))
          as ProtocolError;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ProtocolError() / ProtocolError.new instead')
  static ProtocolError create() => ProtocolError._();
  static $pb.GeneratedMessage $_createMessage() => ProtocolError._();
  @$core.override
  ProtocolError createEmptyInstance() => ProtocolError._();
  @$core.pragma('dart2js:noInline')
  static ProtocolError getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ProtocolError>(
          ProtocolError.$_createMessage);
  static ProtocolError? _defaultInstance;

  @$pb.TagNumber(1)
  ErrorCode get code => $_getN(0);
  @$pb.TagNumber(1)
  set code(ErrorCode value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
