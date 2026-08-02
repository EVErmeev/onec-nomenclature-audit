# Architecture Decision Record

**ADR-001:** ERF as v1.0/v1.1 platform, CFE for v1.2+
**Rationale:** ERF requires no configuration changes. CFE needed for registers, scheduled jobs, server modules.

**ADR-002:** Read-only for nomenclature objects
**Rationale:** Report must not modify catalog data. Only CFE-owned registers are writable.

**ADR-003:** Feature flags per functional block
**Rationale:** Incomplete blocks must not affect stable functionality.

**ADR-004:** Fallback to embedded engine when CFE absent
**Rationale:** ERF must work standalone even without extension installed.

**ADR-005:** Latin internal names, Russian synonyms
**Rationale:** Platform 8.3.27.1559 truncates Cyrillic in DefaultForm.

**ADR-006:** Single-pass main query with per-card problem tracking
**Rationale:** O(N×M) second pass is unacceptable for large catalogs.

## Target Architecture

```
┌─────────────────────────────────────────────────┐
│                  1C:Enterprise                   │
│  ┌──────────────┐  ┌──────────────────────────┐ │
│  │ ERF (v1.0)   │  │ ERF (v1.1+)              │ │
│  │ Manual run   │  │ Export, filters,          │ │
│  │ Diagnostics  │  │ severity, summary         │ │
│  └──────┬───────┘  └───────────┬──────────────┘ │
│         │                      │                 │
│         └──────────┬───────────┘                 │
│                    ▼                              │
│  ┌─────────────────────────────────────────┐    │
│  │ CFE KontrolKachestvaNSI (v1.2+)         │    │
│  │ ┌─────────┐ ┌────────┐ ┌─────────────┐  │    │
│  │ │ Rules   │ │Profiles│ │ Exceptions  │  │    │
│  │ └─────────┘ └────────┘ └─────────────┘  │    │
│  │ ┌─────────┐ ┌────────┐ ┌─────────────┐  │    │
│  │ │ Quality │ │History │ │ Monitoring  │  │    │
│  │ └─────────┘ └────────┘ └─────────────┘  │    │
│  │ ┌─────────┐ ┌────────┐ ┌─────────────┐  │    │
│  │ │ Engine  │ │Queries │ │Diagnostics  │  │    │
│  │ └─────────┘ └────────┘ └─────────────┘  │    │
│  └─────────────────────────────────────────┘    │
│                                                  │
│  ┌─────────────────────────────────────────┐    │
│  │ Registers (CFE-owned)                   │    │
│  │ Rules, Profiles, Exceptions,            │    │
│  │ Runs, Results, ProblemState,            │    │
│  │ MonitoringSettings                      │    │
│  └─────────────────────────────────────────┘    │
└─────────────────────────────────────────────────┘
```

## CFE Objects

| Type | Name | Purpose |
|------|------|---------|
| CommonModule | ККНСИ_ДвижокПроверокСервер | Check engine |
| CommonModule | ККНСИ_ПостроениеЗапросовСервер | Query builder |
| CommonModule | ККНСИ_ПравилаСервер | Rules CRUD |
| CommonModule | ККНСИ_ПрофилиСервер | Profiles CRUD |
| CommonModule | ККНСИ_ИсключенияСервер | Exceptions CRUD |
| CommonModule | ККНСИ_ОценкаКачестваСервер | Scoring engine |
| CommonModule | ККНСИ_ИсторияСервер | Run history |
| CommonModule | ККНСИ_МониторингСервер | Scheduled execution |
| CommonModule | ККНСИ_УведомленияСервер | Notifications |
| CommonModule | ККНСИ_ДиагностикаСервер | Diagnostics |
| InformationRegister | ККНСИ_ПравилаКонтроля | Rule catalog |
| InformationRegister | ККНСИ_ПрофилиКонтроля | Profile catalog |
| InformationRegister | ККНСИ_СоставПрофилей | Profile composition |
| InformationRegister | ККНСИ_ИсключенияКонтроля | Exception registry |
| InformationRegister | ККНСИ_ЗапускиКонтроля | Run log |
| InformationRegister | ККНСИ_РезультатыКонтроля | Run results |
| InformationRegister | ККНСИ_СостояниеПроблем | Problem state tracking |
| InformationRegister | ККНСИ_НастройкиМониторинга | Monitoring config |
| ScheduledJob | ККНСИ_РегулярныйКонтроль | Daily/weekly check |
| ScheduledJob | ККНСИ_ОчисткаИстории | Archive/cleanup |

**Total: 10 common modules, 8 registers, 2 scheduled jobs = 20 objects**

## Feature Flags

```bsl
ИспользоватьЭкспорт = Истина       // v1.1
ИспользоватьУправляемыеПравила = Ложь  // v1.2
ИспользоватьОценкуКачества = Ложь     // v1.3
ИспользоватьИсторию = Ложь           // v1.3
ИспользоватьМониторинг = Ложь        // v1.4
ИспользоватьУведомления = Ложь       // v1.4
```
