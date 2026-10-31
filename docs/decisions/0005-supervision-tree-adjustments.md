# 0005 - Supervision tree differs from the AGENT.md sketch
Status: accepted
- `chat_config` is a module over `persistent_term`, not a gen_server: it holds no mutable state.
- No `chat_session_sup`: Cowboy runs one process per connection and supervises it; an extra layer would add nothing yet. (Erlang has no `DynamicSupervisor`; the OTP equivalent is `simple_one_for_one`.) A dynamic supervisor will be introduced where it earns its place (presence workers, Milestone 5).
- `chat_message_dispatcher` became the module `chat_dispatch` using OTP `pg` process groups; `pg` monitors members and removes dead ones automatically.
- `rest_for_one` replaces `one_for_one` because children depend on earlier children (see architecture.md).
- `chat_migrate` is a supervisor child that returns `ignore` after running, so migrations complete before the listener accepts traffic.
