#!/usr/bin/env python3
"""Poor-man's syntax check for when no compiler is available: bracket balance for .erl/.dart, and
function-clause termination for .erl. It catches typos, NOT type or semantic errors."""
import pathlib, re, sys
root = pathlib.Path(__file__).resolve().parents[2]
pairs = {")": "(", "]": "[", "}": "{"}
def strip_erl(s):
    """Character scanner (not regexes): removes comments, strings, quoted atoms and $c literals while
    respecting that '%' inside a string is not a comment and a quote inside a comment is not a string."""
    out, i, n = [], 0, len(s)
    while i < n:
        c = s[i]
        if c == "%":                                   # comment to end of line
            while i < n and s[i] != "\n": i += 1
        elif c == "$" and i + 1 < n:                   # character literal: $a  $\n  $"
            i += 3 if s[i + 1] == "\\" else 2
            out.append("X")
        elif c in "\"'":                               # string or quoted atom, with backslash escapes
            q = c; i += 1
            while i < n and s[i] != q:
                i += 2 if s[i] == "\\" else 1
            i += 1
            out.append(q + q)
        else:
            out.append(c); i += 1
    return "".join(out)
def strip_dart(s):
    s = re.sub(r"'''.*?'''|\"\"\".*?\"\"\"", "''", s, flags=re.S)
    s = re.sub(r"r?'(\\.|[^'\\\n])*'", "''", s)
    s = re.sub(r'r?"(\\.|[^"\\\n])*"', '""', s)
    s = re.sub(r"/\*.*?\*/", "", s, flags=re.S)
    s = re.sub(r"//.*", "", s)
    return s
bad = 0
def check(path, stripped):
    global bad
    stack = []
    for ln, line in enumerate(stripped.splitlines(), 1):
        for ch in line:
            if ch in "([{": stack.append((ch, ln))
            elif ch in ")]}":
                if not stack or stack[-1][0] != pairs[ch]:
                    print(f"{path}:{ln}: unbalanced '{ch}'"); bad += 1; return
                stack.pop()
    if stack: print(f"{path}:{stack[-1][1]}: unclosed '{stack[-1][0]}'"); bad += 1
files = 0
for p in sorted(root.rglob("*")):
    if "_build" in p.parts or ".dart_tool" in p.parts: continue
    if p.suffix in (".erl", ".hrl"):
        t = strip_erl(p.read_text())
        check(p.relative_to(root), t); files += 1
        if p.suffix == ".erl" and not t.rstrip().endswith("."):
            print(f"{p.relative_to(root)}: file does not end with '.'"); bad += 1
    elif p.suffix == ".dart" and not p.name.endswith((".g.dart", ".pb.dart")):
        check(p.relative_to(root), strip_dart(p.read_text())); files += 1
print(f"checked {files} files, problems: {bad}")
sys.exit(1 if bad else 0)
