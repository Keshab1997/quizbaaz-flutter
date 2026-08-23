#!/usr/bin/env python3
"""Applies `prefer_const_constructors` fixes from a `flutter analyze` run.

Why this exists: stripping `const` off an expression that gained an `S.*`
getter also strips it from that expression's still-const-able children. The
analyzer knows exactly where each one is, so rather than guess, feed it the
report:

    flutter analyze | grep prefer_const_constructors > /tmp/analyze.txt
    python3 tool/apply_const_hints.py /tmp/analyze.txt

Accepts either raw analyzer output or bare `path:line:col` lines.

Two guards keep the result compiling:
  * a position is skipped if the expression there contains an `S.*` getter
    (a runtime call can never be const);
  * after insertion, any `const` nested inside another `const` is removed,
    because that is exactly what `unnecessary_const` flags.
"""
import re
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

POS = re.compile(r'(lib/[\w/]+\.dart):(\d+):(\d+)')


def match_bracket(src, i):
    pairs = {'[': ']', '(': ')', '{': '}', '<': '>'}
    open_ch = src[i]
    close_ch = pairs[open_ch]
    depth, j, n = 0, i, len(src)
    while j < n:
        c = src[j]
        if c in ("'", '"'):
            j = skip_string(src, j)
            continue
        if c == open_ch:
            depth += 1
        elif c == close_ch:
            depth -= 1
            if depth == 0:
                return j + 1
        j += 1
    return None


def skip_string(src, i):
    quote = src[i]
    if src.startswith(quote * 3, i):
        end = src.find(quote * 3, i + 3)
        return len(src) if end < 0 else end + 3
    j = i + 1
    while j < len(src):
        if src[j] == '\\':
            j += 2
            continue
        if src[j] == quote:
            return j + 1
        j += 1
    return len(src)


def expr_end(src, i):
    """End index of the constructor invocation starting at `i`."""
    n = len(src)
    m = re.match(r'[A-Za-z_$][\w$]*(\s*\.\s*[A-Za-z_$][\w$]*)*', src[i:])
    if not m:
        return None
    j = i + m.end()
    while j < n and src[j].isspace():
        j += 1
    if j < n and src[j] == '<':
        j = match_bracket(src, j) or j
        while j < n and src[j].isspace():
            j += 1
    if j < n and src[j] == '(':
        return match_bracket(src, j)
    return j


def strip_nested_const(src):
    """Removes any `const` that already sits inside another const expression."""
    while True:
        for m in re.finditer(r'\bconst\b[ ]*', src):
            end = expr_end(src, m.end())
            if not end:
                continue
            inner = re.search(r'\bconst\b[ ]*', src[m.end():end])
            if inner:
                at = m.end() + inner.start()
                src = src[:at] + src[at + inner.end() - inner.start():]
                break
        else:
            return src


def utf16_col_to_index(line, col):
    """Converts a 1-based analyzer column to a Python string index.

    The Dart analyzer counts UTF-16 code units; Python counts code points. Any
    character outside the BMP — every emoji in this codebase — is two units to
    Dart and one to Python, so a naive `col - 1` lands mid-identifier on every
    line containing one. That is how `DropdownMenuItem` once became
    `Dconst ropdownMenuItem`.
    """
    target = col - 1
    units = 0
    for index, char in enumerate(line):
        if units == target:
            return index
        units += 2 if ord(char) > 0xFFFF else 1
    return len(line) if units == target else None


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2

    report = Path(argv[1]).read_text(encoding='utf-8')
    by_file = defaultdict(list)
    for path, line, col in POS.findall(report):
        by_file[path].append((int(line), int(col)))

    applied = skipped = 0
    for rel, positions in sorted(by_file.items()):
        path = ROOT / rel
        lines = path.read_text(encoding='utf-8').split('\n')

        # Descending order so earlier insertions never shift later offsets.
        for line_no, col in sorted(set(positions), reverse=True):
            line = lines[line_no - 1]
            at = utf16_col_to_index(line, col)
            if at is None:
                print(f'  ?? {rel}:{line_no}:{col} column is past end of line')
                skipped += 1
                continue
            if line[at:at + 6] == 'const ':
                continue
            if not re.match(r'[A-Za-z_$]', line[at:at + 1] or ' '):
                print(f'  ?? {rel}:{line_no}:{col} does not start an identifier')
                skipped += 1
                continue
            # Guard: never const-ify an expression containing a runtime getter.
            tail = '\n'.join([line[at:]] + lines[line_no:line_no + 40])
            end = expr_end(tail, 0)
            if end and re.search(r'\bS\.\w', tail[:end]):
                print(f'  -- {rel}:{line_no}:{col} contains S.* — skipped')
                skipped += 1
                continue
            lines[line_no - 1] = line[:at] + 'const ' + line[at:]
            applied += 1

        src = strip_nested_const('\n'.join(lines))
        path.write_text(src, encoding='utf-8')
        print(f'{len(set(positions)):4d}  {rel}')

    print(f'\n{applied} const inserted, {skipped} skipped, '
          f'{len(by_file)} files touched.')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
