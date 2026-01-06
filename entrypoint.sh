#!/usr/bin/env bash
set -euo pipefail

SCAN_PATH="${INPUT_PATH:-.}"
MIN_SCORE="${INPUT_MIN_SCORE:-80}"
LANGUAGE="${INPUT_LANGUAGE:-en}"
MIN_SEVERITY="${INPUT_MIN_SEVERITY:-INFO}"
THREADS="${INPUT_THREADS:-4}"
SORT_BY="${INPUT_SORT_BY:-severity}"
VISOR_REF="${INPUT_VISOR_REF:-main}"
VISOR_DIR="/opt/visor"
VISOR_REPO_URL="https://github.com/coder-kirill/visor.git"

mkdir -p /opt
rm -rf "${VISOR_DIR}"
git clone --depth 1 --branch "${VISOR_REF}" "${VISOR_REPO_URL}" "${VISOR_DIR}" || \
  git clone --depth 1 "${VISOR_REPO_URL}" "${VISOR_DIR}"

if [ -f "${VISOR_DIR}/requirements.txt" ]; then
    pip install --no-cache-dir -r "${VISOR_DIR}/requirements.txt" >/dev/null
else
    pip install --no-cache-dir typer rich PyYAML identify >/dev/null
fi

cd /github/workspace
OUT_FILE="visor_report.json"
export PYTHONPATH="${VISOR_DIR}:${PYTHONPATH:-}"

RULES_PATH="${INPUT_RULES:-${VISOR_DIR}/rules}"

ARGS=(
    "${SCAN_PATH}"
    "--rules" "${RULES_PATH}"
    "--lang" "${LANGUAGE}"
    "--output" "${OUT_FILE}"
    "--threads" "${THREADS}"
    "--sort-by" "${SORT_BY}"
    "--min-severity" "${MIN_SEVERITY}"
)

if [ "${INPUT_HIDE_LOW_INFO:-true}" = "true" ]; then
    ARGS+=("--hide-low-info")
fi

python "${VISOR_DIR}/main.py" "${ARGS[@]}"

if [ ! -f "${OUT_FILE}" ]; then
    echo "::error::Report file ${OUT_FILE} not found"
    exit 1
fi

SCORE=$(python3 -c "import json; d=json.load(open('${OUT_FILE}')); print(int(d.get('score', 0)))" 2>/dev/null || echo "0")

if [ -n "${GITHUB_OUTPUT:-}" ]; then
    echo "score=${SCORE}" >> "$GITHUB_OUTPUT"
fi

if [ "${SCORE}" -lt "${MIN_SCORE}" ]; then
    echo "::error::Score ${SCORE} is below threshold ${MIN_SCORE}"
    exit 1
fi

echo "[VISOR] OK: ${SCORE} >= ${MIN_SCORE}"
