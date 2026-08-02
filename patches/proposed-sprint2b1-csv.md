# Sprint 2B.1 CSV Patch

**Base:** 52a8a49 | **Status:** PREPARED — NOT APPLIED

## Changes

### 1. Replace client procedure ЭкспортироватьCSV
- **Before:** one-liner `ЭкспортироватьCSV(Команда) ЭкспортироватьCSVНаСервере(); КонецПроцедуры`
- **After:** multi-line with call to `СформироватьCSVДляПолученияНаКлиенте()`, `НачатьПолучениеФайла()`

### 2. Replace server procedure ЭкспортироватьCSVНаСервере
- **Before:** `Процедура ЭкспортироватьCSVНаСервере()` — writes file, shows server path 
- **After:** `Функция СформироватьCSVДляПолученияНаКлиенте()` — returns structure with `ПоместитьВоВременноеХранилище` address

### 3. Feature flag
- `ЭкспортCSV = Истина` (was `Экспорт = Ложь`)

## Proc/Function count

| Name | Before | After |
|------|--------|-------|
| ЭкспортироватьCSV | 2 (client+server) | 1 (client only) |
| ЭкспортироватьCSVНаСервере | 1 | 0 |
| СформироватьCSVДляПолученияНаКлиенте | 0 | 1 |
| СформироватьНаСервере | 1 | 1 |
| ПрименитьФильтрНаСервере | 1 | 1 |
| ЭкспортироватьXLSX | 2 | 2 |

## Balance
- Процедура = КонецПроцедуры
- Функция = КонецФункции
- No duplicates
