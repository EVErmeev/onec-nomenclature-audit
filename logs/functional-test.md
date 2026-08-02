# Functional Test — v4 (BSL encoding + fail-fast release)

**Status:** NOT_TESTED — ожидает ручного открытия в 1С

**Дата:** 02.08.2026
**Платформа:** 8.3.27.1559

## Автоматизированные проверки

| Этап | Результат | Exit code |
|------|-----------|-----------|
| form-validate | PASS (0 errors) | 0 |
| erf-validate | PASS (0 errors) | 0 |
| validate-bsl-encoding (source) | PASS | 0 |
| erf-build | PASS | 0 |
| erf-dump | PASS | 0 |
| validate-bsl-encoding (source + dump) | PASS | 0 |
| verify-release | 20/20 PASS | 0 |

## ERF

- **Файл:** dist\КонтрольЗаполненияНоменклатуры.erf
- **SHA-256:** CAFF562F5F7D7595429235E59BA5E633DAEFE7166EF3A643DC2531360E76A0AC
- **Размер:** 12116 bytes
- **Git blob:** bc5608b77dfdcafb557de01c2cd04fd12fc0f9ee

## Ручные проверки (ожидают выполнения)

| # | Действие | Ожидаемый результат |
|---|---------|-------------------|
| 1 | Открыть .erf в 1С | Форма без ошибок |
| 2 | Нажать Generate | Отчёт формируется |
| 3 | Проверить параметры | Все флажки доступны |
| 4 | OnlyWithProblems=False | Видны строки без проблем |
| 5 | OnlyWithProblems=True | Только строки с проблемами |
| 6 | Пустое наименование | Элементы с пустым наименованием попадают в проверку |
