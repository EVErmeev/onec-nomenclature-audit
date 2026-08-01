# Корректирующее задание №5
## Восстановление кодировки BSL, fail-fast release, функциональные правки

**Репозиторий:** https://github.com/EVErmeev/onec-nomenclature-audit
**Ветка:** fix/default-form-and-object-module
**Commit:** e28e134c71f0e420f27bcd4a91310a133e51fb38
**Дата:** 01.08.2026

---

## 1. Восстановить ObjectModule.bsl

Восстановить из commit `cf0765a1553df1d967dc21adddf8acb3367a649f` путь `src/КонтрольЗаполненияНоменклатуры/Ext/ObjectModule.bsl`.
Git blob чистого файла: `2c97f7bb029f103b41400bbbdd9f31e603028606`.

## 2. Исправить адаптер формы

Форма передаёт английские свойства (IncludeDeletionMark, IncludeGroups, OnlyWithProblems, MaxRowCount). Процедура `СформироватьОтчет` ожидает русские. Добавить `#Область СовместимостьФормы` с `Процедура GenerateReport`.

## 3. Реализовать «Только с проблемами»

Когда `Истина` — только проблемы. Когда `Ложь` — все элементы + строка «Проблем не обнаружено».

## 4. Сделать проверку пустого наименования достижимой

Удалить `Номенклатура.Наименование <> ""` из основного запроса.

## 5. Добавить проверку кодировки

`build/validate-bsl-encoding.py`: strict UTF-8, отсутствие mojibake, наличие ключевых токенов, BOM.

## 6. Исправить verify-release.ps1

Exit code 1 при ошибках.

## 7. Исправить build-erf.ps1

Удаление старого ERF, проверка времени сборки, вызов validate-bsl-encoding.

## 8. Полный цикл

Восстановление → адаптер → OnlyWithProblems → пустое наименование → encoding → form-validate → erf-validate → erf-build → erf-dump → encoding (dump) → verify-release → commit → push.
