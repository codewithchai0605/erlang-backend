# Learning Guide

Each section points at real code in this repository. Read them in order with the files open.

## Erlang processes, schedulers, and "one process per connection"
An Erlang process is a few KB of heap managed by the VM, not an OS thread. Schedulers (roughly one per CPU core) run thousands of them. Cowboy starts one process per TCP connection; for WebSockets that same process runs `chat_ws_handler`. So "a client misbehaves and crashes" only kills that client's process; its mailbox, heap and state vanish with it. Read: `chat_ws_handler.erl`.

## OTP application startup
`chat.app.src` declares dependencies (`applications`) so OTP starts them first. `chat_app:start/2` validates configuration, THEN starts the supervision tree; bad config fails fast and readably. `prep_stop/1` runs before shutdown to close sockets politely. Read: `chat_app.erl`, `chat_config.erl`.

## Supervisors, restart strategies and intensity
`chat_sup` uses `rest_for_one` with children in dependency order: if `pg` dies the pool and listener restart too; if the listener dies alone nothing else does. `intensity 5, period 10` means more than 5 restarts in 10 seconds makes the supervisor itself give up and escalate. `chat_migrate` shows a child whose start function returns `ignore` - a supervisor can run one-time work as part of startup ordering. Read: `chat_sup.erl`, `chat_otp_SUITE.erl` (kills children and watches the supervisor react).

## gen_server vs plain modules
A `gen_server` is for state that must be owned by one process. `chat_rate_limit` is a gen_server ONLY to own an ETS table (callers update counters directly in ETS, no message passing). `chat_config` is not a process at all: `persistent_term` gives lock-free reads. `chat_dispatch` is a plain module over `pg`. Rule of thumb: don't introduce a process unless you need isolation, ownership of state, or concurrency.

## Mailboxes and backpressure
Sending a message (`Pid ! Msg`) never blocks; the receiver's mailbox grows. A slow client can therefore accumulate unbounded pushes. `chat_dispatch:send/2` checks `message_queue_len` and kills the connection past a limit; the client reconnects and syncs from the database. Meanwhile, requests from a client are handled one at a time by its process, so a flood of sends is throttled by TCP itself.

## Links, monitors, "let it crash"
`pg` monitors group members, so dead connections disappear without cleanup code. In `chat_db:run/3`, an unexpected crash while a connection is checked out resets that connection (it might be mid-transaction) and re-raises; the supervisor/pool recovers. Expected failures (validation, not-a-member) are ordinary return values (`{error, forbidden}`); only the unexpected is allowed to crash.

## Pattern matching and tagged tuples
Almost every function returns `{ok, V}` or `{error, Reason}`, and `case` expressions branch on shape. Function heads do the validation: see `chat_protocol:validate/1`, one clause per request type, with the oneof tuple `{Variant, Map}` as the pattern.

## ETS
In-memory tables owned by a process. `chat_rate_limit` uses `ets:update_counter/4` with a default object so the first increment creates the row atomically - a fixed-window counter in one call. The table dies with its owner (and is rebuilt, empty, when the supervisor restarts it).

## Protobuf and the wire format
Each field is encoded as a tag `(field_number << 3) | wire_type` followed by the value: varints for integers, length-delimited for strings/bytes/submessages. `scripts/dev/make_golden_vectors.py` contains a 10-line encoder; compare its output with `proto/testdata/golden_vectors.json`. A `oneof` is just "whichever of these fields is present". Unknown fields are skipped, which is why adding fields is backwards compatible and reusing a number is not. WebSocket frames already delimit messages, so no length prefix is needed (it would be on raw TCP).

## Database transactions and idempotency
`chat_repo_pg:insert_message/4`: lock the conversation row with `UPDATE ... RETURNING last_seq` (serialises writers per conversation), insert with `ON CONFLICT DO NOTHING` on `(sender_id, client_message_id)`, and abort (roll back the seq bump) if a concurrent twin won the race. Result: retries cannot duplicate messages and sequence numbers have no gaps.

## Testing OTP
EUnit for pure functions (`chat_validate_tests`), Common Test for processes and integration (`chat_otp_SUITE`, `chat_e2e_SUITE`, which drives real WebSockets with `gun`).

## Releases
`rebar.config` `{relx, ...}` builds a self-contained release; `vm.args.src` and the environment configure it at start. Distribution is bound to loopback because an Erlang node with a known cookie can run arbitrary code (Milestone 7 explores distribution in an isolated setup only).
