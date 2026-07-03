#!/usr/bin/env bash
# Baixa o runtime Pyodide para assets/pyodide/ (rodar uma vez no setup).
# Depois disso o app funciona 100% offline.
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION=0.26.4
BASE="https://cdn.jsdelivr.net/pyodide/v${VERSION}/full"
mkdir -p assets/pyodide

# Runtime base
CORE=(pyodide.js pyodide.asm.js pyodide.asm.wasm python_stdlib.zip pyodide-lock.json)

# Bibliotecas pré-instaladas (offline): numpy e pandas + dependências
PACKAGES=(
  numpy-1.26.4-cp312-cp312-pyodide_2024_0_wasm32.whl
  pandas-2.2.0-cp312-cp312-pyodide_2024_0_wasm32.whl
  python_dateutil-2.9.0.post0-py2.py3-none-any.whl
  pytz-2024.1-py2.py3-none-any.whl
  six-1.16.0-py2.py3-none-any.whl
)

for f in "${CORE[@]}" "${PACKAGES[@]}"; do
  echo "Baixando ${f}..."
  curl -fL "${BASE}/${f}" -o "assets/pyodide/${f}"
done

echo "Pyodide ${VERSION} + numpy/pandas baixados para assets/pyodide/"
