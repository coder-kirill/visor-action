#!/usr/bin/env bash
# точка входа
set -euo pipefail

# входы из GitHub (INPUT_*)
SCAN_PATH="${INPUT_PATH:-.}"
MIN_SCORE="${INPUT_MIN_SCORE:-80}"
LANGUAGE="${INPUT_LANGUAGE:-en}"

# источник
VISOR_REPO_URL="https://github.com/coder-kirill/visor.git"
VISOR_REF_DEFAULT="main"  # переключить на v1 после тега

echo "[VISOR] установка: ${VISOR_REPO_URL} (${VISOR_REF_DEFAULT})" >&2
mkdir -p /opt
rm -rf /opt/visor || true
# клон (ref) или дефолт
if ! git clone --depth 1 --branch "${VISOR_REF_DEFAULT}" "${VISOR_REPO_URL}" /opt/visor 2>/dev/null; then
  git clone --depth 1 "${VISOR_REPO_URL}" /opt/visor
fi

# ставим зависимости
if [ -f /opt/visor/requirements.txt ]; then
  python -m pip install --upgrade pip >/dev/null 2>&1 || true
  pip install -r /opt/visor/requirements.txt
else
  # запасной вариант
  pip install typer==0.20.0 rich==14.2.0 PyYAML==6.0.3 identify==2.6.15
fi

# запуск сканера
cd /github/workspace
OUT_FILE="visor.json"
echo "[VISOR] запуск: path=${SCAN_PATH} lang=${LANGUAGE}" >&2
python /opt/visor/main.py "${SCAN_PATH}" -l "${LANGUAGE}" -o "${OUT_FILE}" --hide-low-info

# читаем score
if [ ! -f "${OUT_FILE}" ]; then
  echo "[VISOR] ошибка: нет ${OUT_FILE}" >&2
  exit 1
fi

SCORE=$(python - <<'PY'
import json,sys
with open('visor.json','r',encoding='utf-8') as f:
    d=json.load(f)
print(int(d.get('score',0)))
PY
)

echo "[VISOR] score: ${SCORE}" >&2

# вывод в step output
if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "score=${SCORE}" >> "$GITHUB_OUTPUT"
fi

# порог
if [ "${SCORE}" -lt "${MIN_SCORE}" ]; then
  echo "[VISOR] провал: ${SCORE} < ${MIN_SCORE}" >&2
  exit 1
fi

echo "[VISOR] ок: ${SCORE} >= ${MIN_SCORE}" >&2
