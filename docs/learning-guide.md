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

## Dynamic supervision: `simple_one_for_one` (Milestone 5)
`chat_task_sup` creates children at runtime (`supervisor:start_child(chat_task_sup, [Fun])`), one per job. Compare with `chat_sup`, whose children are fixed at startup. `restart => temporary` means a crashed job is never restarted: re-running a half-finished broadcast would be wrong, and the crash is logged instead. `count_children/1` provides a cheap overload guard. Read: `chat_task_sup.erl`, `chat_task.erl`, `chat_otp_SUITE:task_supervisor_isolates_failures`.

## Monitors, and rebuilding state from the source of truth
`chat_presence` calls `erlang:monitor(process, Pid)` for every connection and receives `{'DOWN', ...}` when one dies; no connection has to say goodbye (a crash or a pulled network cable cannot say goodbye). Its state is a cache of facts that also live in `pg`, so `init/1` rebuilds from `pg:which_groups/1` after a crash instead of starting empty. Rule: state you can re-derive should be re-derived, not persisted. Read: `chat_presence.erl`, `chat_otp_SUITE:presence_restart_rebuilds_state`.

## Timers and the stale-timer pattern
The grace period uses `erlang:send_after/3`. Cancelling a timer that already fired cannot unsend its message, so the message carries a unique id and `handle_info` ignores it unless the id still matches the stored one. This pattern removes a whole class of race conditions. Read: `chat_presence:drop_conn/4`, `handle_info({grace_over, ...})`.

## Why a supervisor's child ORDER is a design decision
With `rest_for_one`, "last child" means "crashing it disturbs nobody". Presence is placed last on purpose. If it were placed before the listener, every presence bug would disconnect every user. Read: `chat_sup.erl`, ADR 0010.

## Pitfall found by testing: `with_transaction/2` swallows exceptions
`epgsql:with_transaction/2` converts any exception to `{rollback, Reason}`; the code expected `throw({abort, X})` to propagate. A race handler built on that assumption was dead code until a test provoked it (8 sockets sending the same message id at once). Lessons: read the library source when behaviour matters, and write the regression test that fails without the fix (the mutation check in the Milestone 5 session did exactly that). Read: `chat_db:transaction/1`, `chat_e2e_SUITE:concurrent_duplicate_sends`.

## Ephemeral vs durable events
Messages are durable (stored, sequenced, synced). Typing and presence are ephemeral (relayed, never stored, may be lost). The client therefore *expires* typing indicators itself and *re-asks* presence after reconnecting. Designing for loss, instead of trying to make every event reliable, keeps the system simple. Read: `chat_typing.erl`, `typing_tracker.dart`.

## Containers and releases
A release bundles the Erlang VM, but its NIFs (`crypto`, `bcrypt`) link system libraries dynamically: the build and runtime images must come from the same distribution. (This is easy to see: running a conda-built release on Ubuntu fails with `libcrypto.so.3: version OPENSSL_3.4.0 not found`.) Signals matter too: `docker stop` sends SIGTERM to PID 1; `exec` in the entrypoint makes the VM PID 1's child so it receives it and runs `prep_stop` (graceful close). Read: `Dockerfile`, `docker/entrypoint.sh`.
