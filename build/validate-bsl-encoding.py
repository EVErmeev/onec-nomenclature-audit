#!/usr/bin/env python
# validate-bsl-encoding.py — strict UTF-8 BSL validation
import sys
from pathlib import Path

PROJECT_DIR = Path(__file__).resolve().parent.parent

# Actual Win-1251 mojibake patterns (Win-1251 bytes misinterpreted as UTF-8)
MOJIBAKE_CHARS = {
    "\u0432\u0402\u0459",  # common mojibake
}
MOJIBAKE_SIMPLE = ["\u2550", "\u2564", "\u0432\u0402", "\u252c"]

FORBIDDEN_PATTERNS = [
    "Новый ПолеТабличногоДокумента",
]

OBJMOD_TOKENS = [
    "\u041e\u0431\u043b\u0430\u0441\u0442\u044c \u041f\u0440\u043e\u0433\u0440\u0430\u043c\u043c\u043d\u044b\u0439\u0418\u043d\u0442\u0435\u0440\u0444\u0435\u0439\u0441",
    "\u041a\u043e\u043d\u0435\u0446\u041e\u0431\u043b\u0430\u0441\u0442\u0438",
    "\u0412\u042b\u0411\u0420\u0410\u0422\u042c",
    "\u0421\u043f\u0440\u0430\u0432\u043e\u0447\u043d\u0438\u043a.\u041d\u043e\u043c\u0435\u043d\u043a\u043b\u0430\u0442\u0443\u0440\u0430",
    "\u041f\u0440\u043e\u0446\u0435\u0434\u0443\u0440\u0430 \u0421\u0444\u043e\u0440\u043c\u0438\u0440\u043e\u0432\u0430\u0442\u044c\u041e\u0442\u0447\u0435\u0442",
    "\u041f\u043e\u0441\u0442\u0440\u043e\u0438\u0442\u044c\u041e\u0441\u043d\u043e\u0432\u043d\u043e\u0439\u0417\u0430\u043f\u0440\u043e\u0441",
    "\u041d\u043e\u0440\u043c\u0430\u043b\u0438\u0437\u043e\u0432\u0430\u0442\u044c\u041b\u0438\u043c\u0438\u0442",
    "\u0412\u044b\u043f\u043e\u043b\u043d\u0438\u0442\u044c\u041f\u0440\u043e\u0432\u0435\u0440\u043a\u0438\u0413\u0440\u0443\u043f\u043f\u044b",
    "\u0412\u044b\u043f\u043e\u043b\u043d\u0438\u0442\u044c\u041f\u0440\u043e\u0432\u0435\u0440\u043a\u0438\u042d\u043b\u0435\u043c\u0435\u043d\u0442\u0430",
]

def validate_file(filepath, required_tokens, check_bom=False):
    errors = []
    filepath = Path(filepath)
    if not filepath.exists():
        return [f"File not found: {filepath}"]

    with open(filepath, "rb") as f:
        raw = f.read()

    if check_bom and raw[:3] != b"\xef\xbb\xbf":
        errors.append("No UTF-8 BOM")

    try:
        text = raw[3:].decode("utf-8") if raw[:3] == b"\xef\xbb\xbf" else raw.decode("utf-8")
    except UnicodeDecodeError as e:
        errors.append(f"Not valid UTF-8: {e}")
        return errors

    if "\ufffd" in text:
        errors.append("Contains U+FFFD")

    for m in MOJIBAKE_SIMPLE:
        if m in text:
            errors.append(f"Mojibake: {repr(m)}")

    for pattern in FORBIDDEN_PATTERNS:
        if pattern in text:
            errors.append(f"Forbidden pattern: {pattern}")

    for token in required_tokens:
        if token not in text:
            label = token[:60]
            errors.append(f"Missing: {label}")

    return errors


def main():
    errors_total = 0

    src_dir = PROJECT_DIR / "src"
    bsl_files = sorted(src_dir.rglob("*.bsl"))
    print(f"=== Source BSL ({len(bsl_files)} files) ===")
    for f in bsl_files:
        rel = f.relative_to(PROJECT_DIR)
        is_objmod = "ObjectModule" in f.name
        tokens = OBJMOD_TOKENS if is_objmod else []
        check_bom = is_objmod
        errs = validate_file(f, tokens, check_bom)
        if errs:
            print(f"FAIL: {rel}")
            for e in errs:
                print(f"  - {e}")
            errors_total += len(errs)
        else:
            print(f"PASS: {rel}")

    dump_dir = PROJECT_DIR / "build" / "dump_output"
    if dump_dir.exists():
        dump_files = sorted(dump_dir.rglob("*.bsl"))
        print(f"\n=== Dump BSL ({len(dump_files)} files) ===")
        for f in dump_files:
            rel = f.relative_to(PROJECT_DIR)
            errs = validate_file(f, OBJMOD_TOKENS if "ObjectModule" in f.name else [], False)
            if errs:
                print(f"FAIL: {rel}")
                for e in errs:
                    print(f"  - {e}")
                errors_total += len(errs)
            else:
                print(f"PASS: {rel}")

    if errors_total:
        print(f"\n{errors_total} error(s)")
        sys.exit(1)
    print("\nAll valid")
    sys.exit(0)


if __name__ == "__main__":
    main()
