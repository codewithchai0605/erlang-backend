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

import 'package:protobuf/protobuf.dart' as $pb;

class ErrorCode extends $pb.ProtobufEnum {
  static const ErrorCode ERROR_CODE_UNSPECIFIED =
      ErrorCode._(0, _omitEnumNames ? '' : 'ERROR_CODE_UNSPECIFIED');
  static const ErrorCode ERROR_CODE_UNSUPPORTED_VERSION =
      ErrorCode._(1, _omitEnumNames ? '' : 'ERROR_CODE_UNSUPPORTED_VERSION');
  static const ErrorCode ERROR_CODE_UNAUTHENTICATED =
      ErrorCode._(2, _omitEnumNames ? '' : 'ERROR_CODE_UNAUTHENTICATED');
  static const ErrorCode ERROR_CODE_INVALID_ARGUMENT =
      ErrorCode._(3, _omitEnumNames ? '' : 'ERROR_CODE_INVALID_ARGUMENT');
  static const ErrorCode ERROR_CODE_PERMISSION_DENIED =
      ErrorCode._(4, _omitEnumNames ? '' : 'ERROR_CODE_PERMISSION_DENIED');
  static const ErrorCode ERROR_CODE_NOT_FOUND =
      ErrorCode._(5, _omitEnumNames ? '' : 'ERROR_CODE_NOT_FOUND');
  static const ErrorCode ERROR_CODE_RATE_LIMITED =
      ErrorCode._(6, _omitEnumNames ? '' : 'ERROR_CODE_RATE_LIMITED');
  static const ErrorCode ERROR_CODE_UNSUPPORTED_EVENT =
      ErrorCode._(7, _omitEnumNames ? '' : 'ERROR_CODE_UNSUPPORTED_EVENT');
  static const ErrorCode ERROR_CODE_INTERNAL =
      ErrorCode._(8, _omitEnumNames ? '' : 'ERROR_CODE_INTERNAL');
  static const ErrorCode ERROR_CODE_MESSAGE_TOO_LARGE =
      ErrorCode._(9, _omitEnumNames ? '' : 'ERROR_CODE_MESSAGE_TOO_LARGE');

  static const $core.List<ErrorCode> values = <ErrorCode>[
    ERROR_CODE_UNSPECIFIED,
    ERROR_CODE_UNSUPPORTED_VERSION,
    ERROR_CODE_UNAUTHENTICATED,
    ERROR_CODE_INVALID_ARGUMENT,
    ERROR_CODE_PERMISSION_DENIED,
    ERROR_CODE_NOT_FOUND,
    ERROR_CODE_RATE_LIMITED,
    ERROR_CODE_UNSUPPORTED_EVENT,
    ERROR_CODE_INTERNAL,
    ERROR_CODE_MESSAGE_TOO_LARGE,
  ];

  static final $core.List<ErrorCode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 9);
  static ErrorCode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ErrorCode._(super.value, super.name);
}

class MemberRole extends $pb.ProtobufEnum {
  static const MemberRole MEMBER_ROLE_UNSPECIFIED =
      MemberRole._(0, _omitEnumNames ? '' : 'MEMBER_ROLE_UNSPECIFIED');
  static const MemberRole MEMBER_ROLE_MEMBER =
      MemberRole._(1, _omitEnumNames ? '' : 'MEMBER_ROLE_MEMBER');
  static const MemberRole MEMBER_ROLE_ADMIN =
      MemberRole._(2, _omitEnumNames ? '' : 'MEMBER_ROLE_ADMIN');
  static const MemberRole MEMBER_ROLE_OWNER =
      MemberRole._(3, _omitEnumNames ? '' : 'MEMBER_ROLE_OWNER');

  static const $core.List<MemberRole> values = <MemberRole>[
    MEMBER_ROLE_UNSPECIFIED,
    MEMBER_ROLE_MEMBER,
    MEMBER_ROLE_ADMIN,
    MEMBER_ROLE_OWNER,
  ];

  static final $core.List<MemberRole?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static MemberRole? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const MemberRole._(super.value, super.name);
}

class ConversationKind extends $pb.ProtobufEnum {
  static const ConversationKind CONVERSATION_KIND_UNSPECIFIED =
      ConversationKind._(
          0, _omitEnumNames ? '' : 'CONVERSATION_KIND_UNSPECIFIED');
  static const ConversationKind CONVERSATION_KIND_DIRECT =
      ConversationKind._(1, _omitEnumNames ? '' : 'CONVERSATION_KIND_DIRECT');
  static const ConversationKind CONVERSATION_KIND_GROUP =
      ConversationKind._(2, _omitEnumNames ? '' : 'CONVERSATION_KIND_GROUP');

  static const $core.List<ConversationKind> values = <ConversationKind>[
    CONVERSATION_KIND_UNSPECIFIED,
    CONVERSATION_KIND_DIRECT,
    CONVERSATION_KIND_GROUP,
  ];

  static final $core.List<ConversationKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static ConversationKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ConversationKind._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
