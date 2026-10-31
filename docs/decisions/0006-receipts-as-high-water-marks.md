# 0006 - Delivery/read state as per-member sequence marks
Status: accepted
Context: AGENT.md suggests `message_receipts` (or an equivalent).
Decision: `conversation_members.last_delivered_seq` and `last_read_seq`, advanced monotonically (`GREATEST`) and clamped to the conversation's `last_seq`. A message with sequence `s` is delivered to a member iff `last_delivered_seq >= s`.
Consequences: one small row update per ack instead of one row per message per recipient; the unread count is `last_seq - last_read_seq`; clients ack in ranges. Cost: no per-message delivery timestamps (add a table later if analytics need them). Groups work unchanged.
