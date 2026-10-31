#!/usr/bin/env bash
# Milestone 0 toolchain check. Prints what is installed; exits non-zero if a REQUIRED tool is missing.
# Paste the output into docs/operations.md ("Tested tool versions").
missing=0
check() { # name, required(yes/no), version-command...
  local name=$1 req=$2; shift 2
  if command -v "$name" >/dev/null 2>&1; then
    printf "%-20s OK       %s\n" "$name" "$("$@" 2>&1 | head -1)"
  else
    printf "%-20s MISSING  (%s)\n" "$name" "$req"
    [ "$req" = required ] && missing=1
  fi
}
if command -v erl >/dev/null 2>&1; then
  printf "%-20s OK       OTP %s\n" erl "$(erl -noshell -eval "io:format(\"~s\",[erlang:system_info(otp_release)]),halt().")"
else printf "%-20s MISSING  (required)\n" erl; missing=1; fi
check rebar3 required rebar3 version
check flutter required flutter --version
check dart required dart --version
check protoc required protoc --version
check protoc-gen-dart required echo "(plugin on PATH)"
check psql optional psql --version
check docker optional docker --version
check java optional java -version
check adb optional adb --version
echo
echo "Windows desktop builds also need Visual Studio with the Desktop development with C++ workload. Run: flutter doctor -v"
exit $missing
