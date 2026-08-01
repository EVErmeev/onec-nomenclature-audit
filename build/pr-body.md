## Problem

Opening the report in 1C:Enterprise causes:
```
Unknown form name.
Name: "ExternalReport.KontrolAudit.Form"
```

## Root Causes

1. **1C platform 8.3.27.1559 bug**: `DefaultForm` with Cyrillic chars gets truncated
2. **ObjectModule.bsl** missing from binary when root XML has wrong properties

## Solution

- Latin internal name `KontrolAudit` (Cyrillic synonym kept)
- Full skills pipeline: `erf-init` -> `form-add --set-default` -> `form-compile`
- English attribute and procedure names in form module

## Verification Plan

```
form-validate -> erf-validate -> erf-build -> erf-dump -> open in 1C -> Generate
```

## Completion Criteria

Main form opens without error, Generate command executes, result is displayed.