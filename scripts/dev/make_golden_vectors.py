#!/usr/bin/env python3
"""Generates proto/testdata/golden_vectors.json.

Each vector is produced THREE independent ways and the script fails unless all agree:
  1. a ~10-line hand-written wire encoder below (read it: it is the Protobuf wire format in miniature),
  2. the official Python protobuf runtime running classes that `protoc` generated from the REAL
     proto/chat/v1/chat.proto (so a schema typo or a wrong field number is caught here),
  3. (at test time) the Erlang gpb encoder and the Dart protobuf encoder, which assert the same bytes.

Requires:  pip install grpcio-tools protobuf
Usage:     python3 scripts/dev/make_golden_vectors.py
"""
import importlib.util, json, pathlib, subprocess, sys, tempfile

ROOT = pathlib.Path(__file__).resolve().parents[2]


# --------------------------------------------------------------------------- 1. hand-written encoder
def varint(n):
    out = bytearray()
    while True:
        b = n & 0x7F
        n >>= 7
        if n:
            out.append(b | 0x80)
        else:
            out.append(b)
            return bytes(out)


def tag(num, wire_type):            # field number and wire type share one varint: (num << 3) | wire_type
    return varint((num << 3) | wire_type)


def s(num, v):                      # string / bytes: wire type 2, length-delimited
    b = v.encode()
    return tag(num, 2) + varint(len(b)) + b


def i(num, v):                      # integer / bool / enum: wire type 0 (varint); proto3 omits the default 0
    return tag(num, 0) + varint(v) if v else b""


def m(num, payload):                # embedded message: wire type 2 as well
    return tag(num, 2) + varint(len(payload)) + payload


MEMBER_U1 = s(1, "u1") + s(2, "alice") + s(3, "Alice") + i(4, 2) + i(5, 1) + i(6, 3)   # role = OWNER (3)
MEMBER_U2 = s(1, "u2") + s(2, "bob") + s(3, "Bob") + i(6, 1)                           # role = MEMBER (1)

vectors = {
    # ---- the original five (bytes are unchanged since Milestone 3: proof the schema evolved compatibly)
    "client_hello": ("ClientEnvelope", s(1, "r1") + m(9, i(1, 1) + s(2, "typing") + s(3, "tok"))),
    "client_send_message": ("ClientEnvelope", s(1, "r2") + m(10, s(1, "c1") + s(2, "m1") + s(3, "hi"))),
    "server_accepted": ("ServerEnvelope", s(1, "r2") + m(10, s(1, "x") + s(2, "m1") + i(3, 5) + i(4, 1700000000000) + s(6, "c1"))),
    "server_error": ("ServerEnvelope", s(1, "r3") + m(12, i(1, 3) + s(2, "bad"))),
    "server_new_message": ("ServerEnvelope", m(11, s(1, "x") + s(2, "c1") + s(3, "u1") + s(4, "m1") + s(5, "h\u00e9llo") + i(6, 1700000000000) + i(7, 6))),
    # ---- Milestone 5
    "client_typing": ("ClientEnvelope", m(11, s(1, "c1") + i(2, 1))),                      # request_id empty => omitted
    "client_create_group": ("ClientEnvelope", s(1, "r4") + m(18, s(1, "Team") + s(2, "u2") + s(2, "u3"))),
    "client_get_presence": ("ClientEnvelope", s(1, "r5") + m(23, b"")),
    "server_typing_update": ("ServerEnvelope", m(17, s(1, "c1") + s(2, "u2") + i(3, 1))),
    "server_presence_update": ("ServerEnvelope", m(18, s(1, "u2") + i(3, 1700000000000))),   # online=false is the default
    "server_presence_snapshot": ("ServerEnvelope", s(1, "r5") + m(19, m(1, s(1, "u2") + i(2, 1)) + m(1, s(1, "u3") + i(3, 1700000000000)))),
    "server_conversation_group": ("ServerEnvelope", s(1, "r4") + m(14, s(1, "c9") + i(2, 2) + s(3, "Team") + m(4, MEMBER_U1) + m(4, MEMBER_U2) + i(5, 3) + i(6, 1700000000000))),
    "server_conversation_removed": ("ServerEnvelope", m(20, s(1, "c9"))),
}


# --------------------------------------------------------------------------- 2. official runtime on the real schema
def load_pb2():
    tmp = tempfile.mkdtemp()
    subprocess.run([sys.executable, "-m", "grpc_tools.protoc", f"-I{ROOT / 'proto/chat/v1'}", f"--python_out={tmp}", "chat.proto"], check=True)
    spec = importlib.util.spec_from_file_location("chat_pb2", pathlib.Path(tmp) / "chat_pb2.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


pb = load_pb2()


def build():
    out = {}
    x = pb.ClientEnvelope(request_id="r1"); x.hello.protocol_version = 1; x.hello.capabilities.append("typing"); x.hello.access_token = "tok"
    out["client_hello"] = x
    x = pb.ClientEnvelope(request_id="r2"); x.send_message.conversation_id = "c1"; x.send_message.client_message_id = "m1"; x.send_message.text = "hi"
    out["client_send_message"] = x
    x = pb.ServerEnvelope(request_id="r2"); a = x.accepted; a.message_id = "x"; a.client_message_id = "m1"; a.seq = 5; a.created_at_unix_ms = 1700000000000; a.conversation_id = "c1"
    out["server_accepted"] = x
    x = pb.ServerEnvelope(request_id="r3"); x.error.code = pb.ERROR_CODE_INVALID_ARGUMENT; x.error.message = "bad"
    out["server_error"] = x
    x = pb.ServerEnvelope(); n = x.new_message; n.message_id = "x"; n.conversation_id = "c1"; n.sender_id = "u1"; n.client_message_id = "m1"; n.text = "h\u00e9llo"; n.created_at_unix_ms = 1700000000000; n.seq = 6
    out["server_new_message"] = x

    x = pb.ClientEnvelope(); x.typing.conversation_id = "c1"; x.typing.is_typing = True
    out["client_typing"] = x
    x = pb.ClientEnvelope(request_id="r4"); x.create_group.title = "Team"; x.create_group.member_user_ids.extend(["u2", "u3"])
    out["client_create_group"] = x
    x = pb.ClientEnvelope(request_id="r5"); x.get_presence.SetInParent()
    out["client_get_presence"] = x
    x = pb.ServerEnvelope(); t = x.typing; t.conversation_id = "c1"; t.user_id = "u2"; t.is_typing = True
    out["server_typing_update"] = x
    x = pb.ServerEnvelope(); p = x.presence; p.user_id = "u2"; p.online = False; p.last_seen_unix_ms = 1700000000000
    out["server_presence_update"] = x
    x = pb.ServerEnvelope(request_id="r5")
    u = x.presence_snapshot.users.add(); u.user_id = "u2"; u.online = True
    u = x.presence_snapshot.users.add(); u.user_id = "u3"; u.last_seen_unix_ms = 1700000000000
    out["server_presence_snapshot"] = x
    x = pb.ServerEnvelope(request_id="r4"); c = x.conversation
    c.conversation_id = "c9"; c.kind = pb.CONVERSATION_KIND_GROUP; c.title = "Team"; c.last_seq = 3; c.last_activity_unix_ms = 1700000000000
    mm = c.members.add(); mm.user_id = "u1"; mm.username = "alice"; mm.display_name = "Alice"; mm.delivered_up_to_seq = 2; mm.read_up_to_seq = 1; mm.role = pb.MEMBER_ROLE_OWNER
    mm = c.members.add(); mm.user_id = "u2"; mm.username = "bob"; mm.display_name = "Bob"; mm.role = pb.MEMBER_ROLE_MEMBER
    out["server_conversation_group"] = x
    x = pb.ServerEnvelope(); x.conversation_removed.conversation_id = "c9"
    out["server_conversation_removed"] = x
    return out


official = build()
assert set(official) == set(vectors), f"vector tables differ: {set(official) ^ set(vectors)}"
ok = True
for name, (typ, raw) in vectors.items():
    off = official[name].SerializeToString(deterministic=True)
    if off != raw:
        ok = False
        print("MISMATCH", name, "\n  official:", off.hex(), "\n  by hand: ", raw.hex())
    # round trip: decoding the hand-made bytes with the real schema must succeed and re-encode identically
    back = getattr(pb, typ)()
    back.ParseFromString(raw)
    if back.SerializeToString(deterministic=True) != raw:
        ok = False
        print("ROUNDTRIP FAILED", name)
if not ok:
    sys.exit(1)

out = {
    "note": "Golden protobuf vectors; generated by scripts/dev/make_golden_vectors.py from the real chat.proto and cross-checked "
            "against a hand-written wire encoder. The Erlang (gpb) and Dart tests assert the same bytes.",
    "vectors": [{"name": n, "type": t, "hex": b.hex()} for n, (t, b) in vectors.items()],
}
(ROOT / "proto/testdata/golden_vectors.json").write_text(json.dumps(out, indent=2) + "\n")
print(f"OK: wrote {len(vectors)} vectors; hand encoder == protoc-generated runtime for every one")
