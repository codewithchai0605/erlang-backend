# 0007 - All chat data, including history, travels as Protobuf over the WebSocket
Status: accepted
Context: AGENT.md forbids JSON for message payloads. A REST history endpoint would have returned messages as JSON.
Decision: history and sync are WebSocket requests (`history_request`, `sync_request`) returning `MessageBatch`. HTTP carries only auth, profile and user lookup.
Consequences: one codec for message content, one authentication path, and the same code serves reconnect catch-up and scroll-back.
