# История изменений
## Диагностический отчёт «Контроль заполнения номенклатуры»

| Версия | Дата | Изменение | Причина |
|---|---|---|---|
| 1.0 | 01.08.2026 | Первичная реализация. Полный цикл MCP-исследования: проверка подключения, получение конфигурации (get_configuration_info), метаданных (get_metadata_tree), структуры объекта (get_object_structure), поиск по коду (search_code), валидация запросов (validate_query ×3), тестовое выполнение (execute_query ×2). Создан внешний отчёт с 16 проверками, 4 параметрами, обработкой исключений. Подготовлена полная документация. | Первичный тест MCP-интеграции OpenCode + 1С |
| 1.0.1 | 01.08.2026 | Исправлена конфигурация opencode: ключ `mcpServers` → `mcp`, формат команды как массив, добавлен `type: "local"` | Несовместимость формата конфигурации Claude Desktop и OpenCode |

| 1.1 | 01.08.2026 | Avtomaticheskaya sborka .erf: sozdana failovaya struktura (ExternalReport.xml, Form.xml, MainForm), skript build-erf.ps1 s ZIP fallback, verify-artifact.ps1, SHA-256. Konfigurator nedostupen (baza ne otkryvaetsya v DESIGNER) - .erf sobran kak ZIP (format 1C 8.3.6+). Verifikatsiya: 15/16 PASS. | Korrektiruyushchee zadanie |
