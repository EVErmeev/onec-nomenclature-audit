# Baseline v1.0.0

**Date:** 02.08.2026
**Commit:** `eb3875e` (functional ERF)
**ERF SHA-256:** `69809782D5F03D87CBE215867B6A35EFA9AF9FD0D4A9F7C62499EF4D0B236F80`

## Scope

External report `KontrolAudit` (synonym: Контроль заполнения номенклатуры):
- TableField + ValueTable (8 columns, read-only)
- 4 parameters (deletion mark, groups, only problems, max cards)
- Split group/element checks (4 group checks, 16 element checks)
- Parameterized duplicate queries (`&ПустаяСтрока`)
- Fail-closed error handling
- Visible copyable diagnostics
- Informational SettingsForm
- Single-pass main query with normalized limit (1–100000)
- Russian UI

## Architecture

```
ExternalReport KontrolAudit
├── MainForm (primary)
│   ├── Parameters (checkboxes + number)
│   ├── Status field
│   ├── Result table (ValueTable, 8 columns)
│   ├── Totals (4 counters)
│   ├── Technical error (multi-line)
│   └── Command bar (Generate + Close)
└── SettingsForm
    └── Informational text + Close
```
