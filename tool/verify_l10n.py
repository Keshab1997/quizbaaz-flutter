#!/usr/bin/env python3
"""Static sanity checks for the localisation migration.

Not a Dart parser — a cheap guard for the three mistakes this refactor can
realistically make:

  1. an `S.someKey` that does not exist in the generated accessor;
  2. an `S.*` getter left inside a `const` expression (a compile error);
  3. unbalanced brackets from a bad text edit.

Run:  python3 tool/verify_l10n.py
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LIB = ROOT / 'lib'


def strip_code(src):
    """Blanks out string bodies and comments so regexes only see real code.

    Interpolations survive: `'total: ${items[0].name}'` keeps `items[0].name`
    as code, because that part really is code — and because a naive scanner
    that stops at the first quote inside `${...}` miscounts every bracket in
    the file.
    """
    out = []

    def blank(n):
        out.append(' ' * n)

    def scan_string(i):
        """Consumes the literal starting at `i`; returns the index after it."""
        quote = src[i]
        triple = src.startswith(quote * 3, i)
        opener = quote * (3 if triple else 1)
        raw_string = i > 0 and src[i - 1] == 'r'
        blank(len(opener))
        j = i + len(opener)
        n = len(src)
        while j < n:
            if not raw_string and src[j] == '\\':
                blank(2); j += 2; continue
            if src.startswith(opener, j):
                blank(len(opener))
                return j + len(opener)
            if not triple and src[j] == '\n':
                return j                       # unterminated; let Dart complain
            if not raw_string and src.startswith('${', j):
                blank(2)
                j = scan_interpolation(j + 2)
                continue
            blank(1)
            j += 1
        return n

    def scan_interpolation(i):
        """Consumes `${ ... }` — its contents are emitted verbatim as code."""
        depth, j, n = 1, i, len(src)
        while j < n:
            c = src[j]
            if c in ('"', "'"):
                j = scan_string(j)
                continue
            if c == '{':
                depth += 1
            elif c == '}':
                depth -= 1
                if depth == 0:
                    blank(1)
                    return j + 1
            out.append(c)
            j += 1
        return n

    i, n = 0, len(src)
    while i < n:
        if src.startswith('//', i):
            j = src.find('\n', i)
            j = n if j < 0 else j
            blank(j - i); i = j; continue
        if src.startswith('/*', i):
            j = src.find('*/', i)
            j = n if j < 0 else j + 2
            blank(j - i); i = j; continue
        if src[i] in ('"', "'"):
            i = scan_string(i)
            continue
        out.append(src[i])
        i += 1
    return ''.join(out)


def expr_end(src, i):
    """End index of the expression a `const` keyword at `i` applies to."""
    n = len(src)
    while i < n and src[i].isspace():
        i += 1
    if i >= n:
        return None
    if src[i] in '([{':
        return match_bracket(src, i)
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
    if j < n and src[j] in '([{':
        return match_bracket(src, j)
    return j


def match_bracket(src, i):
    pairs = {'[': ']', '(': ')', '{': '}', '<': '>'}
    open_ch = src[i]
    close_ch = pairs[open_ch]
    depth, j, n = 0, i, len(src)
    while j < n:
        if src[j] == open_ch:
            depth += 1
        elif src[j] == close_ch:
            depth -= 1
            if depth == 0:
                return j + 1
        j += 1
    return None


def declared_members():
    src = (LIB / 'l10n' / 'app_strings.dart').read_text(encoding='utf-8')
    getters = set(re.findall(r'static [\w<>?]+ get (\w+)', src))
    methods = set(re.findall(r'static [\w<>?]+ (\w+)\(', src))
    return getters | methods | {'load', 'raw', 'fill', 'code'}


def main():
    known = declared_members()
    problems = []

    for path in sorted(LIB.rglob('*.dart')):
        raw = path.read_text(encoding='utf-8')
        code = strip_code(raw)
        rel = path.relative_to(ROOT)

        if path.parent.name == 'l10n':
            continue

        # 1. unknown keys
        for m in re.finditer(r'\bS\.(\w+)', code):
            if m.group(1) not in known:
                line = raw[:m.start()].count('\n') + 1
                problems.append(f'{rel}:{line}: unknown string key S.{m.group(1)}')

        # 2. const contexts containing an S.* getter. `const` only applies to
        #    the single expression that follows it, so the span is found by
        #    bracket matching rather than by scanning to the next semicolon.
        for m in re.finditer(r'\bconst\b', code):
            end = expr_end(code, m.end())
            if end and re.search(r'\bS\.\w', code[m.end():end]):
                line = raw[:m.start()].count('\n') + 1
                problems.append(f'{rel}:{line}: `const` wraps an S.* getter')

        # 3. bracket balance
        for opener, closer in (('(', ')'), ('[', ']'), ('{', '}')):
            if code.count(opener) != code.count(closer):
                problems.append(
                    f'{rel}: unbalanced {opener}{closer} '
                    f'({code.count(opener)} vs {code.count(closer)})')

    # 4. every file using S. imports the catalogue
    for path in sorted(LIB.rglob('*.dart')):
        if path.parent.name == 'l10n':
            continue
        code = strip_code(path.read_text(encoding='utf-8'))
        if re.search(r'\bS\.\w+', code) and 'app_strings.dart' not in path.read_text(encoding='utf-8'):
            problems.append(f'{path.relative_to(ROOT)}: uses S.* without importing app_strings.dart')

    if problems:
        print(f'{len(problems)} problem(s):')
        for p in problems:
            print('  -', p)
        return 1
    print('Localisation checks passed ✅')
    return 0


if __name__ == '__main__':
    sys.exit(main())
