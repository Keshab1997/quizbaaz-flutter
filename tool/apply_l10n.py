#!/usr/bin/env python3
"""One-off migration: replaces hardcoded English UI literals with `S.*` lookups.

Kept in the repo so the same pass can be re-run after new screens are written.

Safety rules — a literal is only replaced when it is unambiguously UI copy:
  * it must exactly match a value in the English catalogue;
  * that value must be unique in the catalogue;
  * it must not sit in a comparison (`== 'Male'`), a `case`, or a map-key slot
    (`'Score': ...`), which are data, not copy;
  * `const` is stripped from any expression that ends up containing `S.`,
    because `S.foo` is a runtime getter and cannot live inside a const context.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LIB = ROOT / 'lib'

SKIP_DIRS = {'l10n'}
# Files that are already localisation-aware and must keep their raw literals
# (language names, catalogue keys) exactly as written.
SKIP_FILES = {
    'firebase_options.dart',
    'translation_service.dart',
    'translatable_text.dart',
    'language_screen.dart',
    'locale_provider.dart',
}


def load_catalogue():
    src = (LIB / 'l10n' / 'strings_en.dart').read_text(encoding='utf-8')
    body = src.split('kStringsEn = {', 1)[1]
    pairs = re.findall(
        r"'([A-Za-z0-9_]+)':\s*((?:'(?:[^'\\]|\\.)*'\s*)+),", body, re.S)
    value_to_key, seen = {}, {}
    for key, raw in pairs:
        value = ''.join(re.findall(r"'((?:[^'\\]|\\.)*)'", raw))
        if '{' in value:          # placeholder strings need manual handling
            continue
        seen[value] = seen.get(value, 0) + 1
        value_to_key[value] = key
    # Drop ambiguous values that map to more than one key.
    return {v: k for v, k in value_to_key.items() if seen[v] == 1 and v.strip()}


def expr_end(src, i):
    """End index of the expression starting at `i` (after a `const`)."""
    n = len(src)
    while i < n and src[i].isspace():
        i += 1
    if i >= n:
        return None
    pairs = {'[': ']', '(': ')', '{': '}'}
    if src[i] in pairs:
        return match_bracket(src, i)
    m = re.match(r'[A-Za-z_$][\w$]*(\s*\.\s*[A-Za-z_$][\w$]*)*', src[i:])
    if not m:
        return None
    j = i + m.end()
    while j < n and src[j].isspace():
        j += 1
    if j < n and src[j] == '<':                     # generic type arguments
        j = match_bracket(src, j, '<', '>') or j
        while j < n and src[j].isspace():
            j += 1
    if j < n and src[j] in '([{':
        return match_bracket(src, j)
    return j


def match_bracket(src, i, open_ch=None, close_ch=None):
    pairs = {'[': ']', '(': ')', '{': '}', '<': '>'}
    open_ch = open_ch or src[i]
    close_ch = close_ch or pairs[open_ch]
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
    triple = src.startswith(quote * 3, i)
    if triple:
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


def strip_bad_const(src):
    """Removes `const` from any expression that now contains an `S.` getter."""
    while True:
        for m in re.finditer(r'\bconst\b[ ]*', src):
            end = expr_end(src, m.end())
            if end and re.search(r'\bS\.', src[m.end():end]):
                src = src[:m.start()] + src[m.end():]
                break
        else:
            return src


# A literal in any of these positions is data, not user-facing copy.
BEFORE_BLOCK = re.compile(r'(==|!=|case)\s*$')
# `json['accuracy']`, `map['name']` — a subscript key.
SUBSCRIPT = re.compile(r'\[\s*$')
# `'en': 'English'` — the value half of a string-keyed map entry.
MAP_VALUE = re.compile(r"'(?:[^'\\]|\\.)*'\s*:\s*$")


def migrate(path, catalogue):
    src = path.read_text(encoding='utf-8')
    original = src
    out, i, n, hits = [], 0, len(src), 0

    while i < n:
        ch = src[i]
        if ch == '/' and src.startswith('//', i):
            j = src.find('\n', i)
            j = n if j < 0 else j
            out.append(src[i:j]); i = j; continue
        if ch == '/' and src.startswith('/*', i):
            j = src.find('*/', i)
            j = n if j < 0 else j + 2
            out.append(src[i:j]); i = j; continue
        if ch == '"' or (ch == "'" and src.startswith("'''", i)) or ch == "'":
            j = skip_string(src, i)
            literal = src[i:j]
            body = literal[1:-1] if len(literal) >= 2 else ''
            key = catalogue.get(body)
            prev = ''.join(out)[-60:]
            after = src[j:j + 1]
            if (key and literal.startswith("'") and not literal.startswith("'''")
                    and '$' not in body
                    and not BEFORE_BLOCK.search(prev)
                    and not SUBSCRIPT.search(prev)
                    and not MAP_VALUE.search(prev)
                    and after != ':'):
                out.append('S.%s' % key)
                hits += 1
            else:
                out.append(literal)
            i = j
            continue
        out.append(ch)
        i += 1

    src = ''.join(out)
    if hits == 0:
        return 0

    src = strip_bad_const(src)

    # Add the import if the file does not already have it.
    if "l10n/app_strings.dart" not in src:
        depth = len(path.relative_to(LIB).parts) - 1
        rel = '../' * depth + 'l10n/app_strings.dart'
        imports = list(re.finditer(r"^import\s+'[^']+';$", src, re.M))
        if imports:
            anchor = imports[-1].end()
            src = src[:anchor] + "\nimport '%s';" % rel + src[anchor:]
        else:
            src = "import '%s';\n\n" % rel + src

    if src != original:
        path.write_text(src, encoding='utf-8')
    return hits


def main():
    catalogue = load_catalogue()
    total, touched = 0, []
    for path in sorted(LIB.rglob('*.dart')):
        rel = path.relative_to(LIB)
        if rel.parts[0] in SKIP_DIRS or path.name in SKIP_FILES:
            continue
        hits = migrate(path, catalogue)
        if hits:
            total += hits
            touched.append((str(rel), hits))
    for name, hits in touched:
        print(f'{hits:4d}  {name}')
    print(f'\n{total} literals replaced across {len(touched)} files.')
    print(f'(catalogue offered {len(catalogue)} unique replaceable values)')


if __name__ == '__main__':
    sys.exit(main())
