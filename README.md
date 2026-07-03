# PyEstudo

App móvel **gratuito** (iOS e Android) para estudar Python no celular:

- Execução de código Python **local e offline** (CPython 3.12 via Pyodide/WebAssembly)
- Erros sempre com **tipo, mensagem e linha** — tocar no erro leva o cursor à linha
- Editor com destaque de sintaxe e números de linha — **sem IA, sem autocomplete**
- Lições com exemplos comentados, exercícios com feedback teste a teste
- 3 capítulos por nível de dificuldade, progresso salvo localmente (SQLite)

Arquitetura, decisões e roadmap: ver [PLANO.md](PLANO.md).

## Rodar localmente

Pré-requisito: [Flutter](https://docs.flutter.dev/get-started/install) (o SDK está em `~/development/flutter`; adicione ao PATH se necessário):

```bash
export PATH="$HOME/development/flutter/bin:$PATH"
```

Depois:

```bash
flutter doctor                 # 1. verificar ambiente (Xcode p/ iOS, Android SDK)
./scripts/fetch_pyodide.sh     # 2. baixar o runtime Python (uma vez; depois é offline)
flutter pub get                # 3. dependências
flutter test                   # 4. testes unit + widget
flutter run                    # 5. no simulador iOS ou emulador Android
```

Sem os assets do Pyodide o app cai num runtime **simulado** (subconjunto de
Python em Dart) — útil para desenvolver a UI, mas os exercícios só são
verificáveis com o runtime real.

## Estrutura

```
assets/python/runner.py     # execução + captura de erro com linha (CPython)
assets/pyodide/             # runtime Pyodide (bootstrap.html + assets baixados)
assets/content/chapters/    # capítulos: lições, exemplos e exercícios (JSON)
lib/core/runtime/           # PythonRuntime, PyodideRuntime, simulado, checker
lib/core/storage/           # SQLite: códigos salvos e progresso
lib/features/               # telas: editor, console, exercícios, lições, progresso
test/                       # unit (runtime, repos, conteúdo) + widget (console, editor)
```

## Verificar o runner.py com o Python do sistema

```bash
python3 -c "
import sys, json; sys.path.insert(0, 'assets/python')
from runner import run_user_code
print(json.loads(run_user_code('x')))   # NameError na linha 1
"
```
