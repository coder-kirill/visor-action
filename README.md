# VISOR — GitHub Action

Сканер IaC. Падает при низком Score.

## Пример

```yaml
name: VISOR
on:
  push:
    branches: ["main"]
  pull_request:
    branches: ["main"]
jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: coder-kirill/visor-action@v1
        with:
          path: .          # путь
          min_score: 80    # порог
          language: en     # язык
      - name: upload report
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: visor-report
          path: visor.json
```

## Входы
- `path` — путь (по умолчанию `.`)
- `min_score` — порог (по умолчанию `80`)
- `language` — язык (`en`|`ru`, по умолчанию `en`)

## Выходы
- `score` — число 0..100

## Как работает
- клон VISOR
- ставим зависимости
- запуск сканера `python main.py <path> -l <lang> -o visor.json`
- читаем `visor.json`, сравниваем Score
