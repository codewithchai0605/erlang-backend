# 0003 - Require OTP 27+ and use the built-in `json` module
Status: accepted
Context: HTTP endpoints need JSON; third-party JSON libraries are one more dependency to vet.
Decision: `minimum_otp_vsn "27"`; use `json:encode/1` and `json:decode/1`.
Consequences: fewer dependencies; older OTP releases are unsupported. Chat traffic is Protobuf and does not use JSON.
