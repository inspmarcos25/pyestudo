# PyEstudo — Plano de desenvolvimento

App móvel **gratuito** para estudar Python no celular, com execução **local e offline** de código, erros com número de linha, exercícios com feedback automático e progresso salvo no dispositivo. **Sem IA e sem autocomplete** — o aluno digita e raciocina sozinho.

---

## 1) Stack recomendada: Flutter + Pyodide

| Camada | Escolha | Justificativa |
|---|---|---|
| Framework UI | **Flutter (Dart)** | Um único codebase para iOS e Android com renderização idêntica nas duas plataformas — crítico para editor e console; performance nativa |
| Editor de código | `flutter_code_editor` + `highlight` | Destaque de sintaxe Python pronto, numeração de linhas e **nenhum autocomplete por padrão** (exatamente o requisito) |
| Execução Python | **Pyodide** (CPython 3.12 compilado para WebAssembly) em WebView **headless** com assets locais | CPython real → tracebacks reais com linha exata; sandbox WASM (o código do aluno não acessa arquivos nem rede do aparelho); comportamento idêntico em iOS e Android; 100% offline (~12 MB empacotados no app) |
| Ponte Dart ⇄ Python | `webview_flutter` + `JavaScriptChannel` | Streaming de stdout para o console em tempo real |
| Persistência | `sqflite` (SQLite) + `shared_preferences` | Progresso e códigos salvos em SQLite (consultável por capítulo); preferências simples em SharedPreferences |
| Conteúdo didático | JSON em `assets/content/` | Capítulos, lições e exercícios versionados junto com o app — sem backend, sem custo de servidor |

**Por que não as alternativas:**

- **React Native**: não há editor com highlight nativo maduro; a solução prática seria CodeMirror dentro de WebView — somando o Pyodide, seriam duas WebViews e pontes JS extras. Flutter resolve o editor com widget nativo.
- **Kotlin/Swift nativo**: dobra o esforço de desenvolvimento e o problema da execução local se divide em dois: Chaquopy (excelente, CPython real) é **só Android**; no iOS seria preciso embarcar Python via Python-Apple-support, que é complexo. Inviável para um MVP enxuto.
- **serious_python (Flutter)**: embarca CPython real, mas sem sandbox e com captura de stdout/interrupção mais trabalhosas. Fica como alternativa futura se o Pyodide limitar (ex.: bibliotecas com extensão C).

---

## 2) Estrutura de pastas e componentes principais

```
app_python/
├── pubspec.yaml
├── scripts/
│   └── fetch_pyodide.sh              # baixa runtime Pyodide p/ assets (1x no setup)
├── assets/
│   ├── pyodide/                      # pyodide.js, .wasm, stdlib empacotada
│   ├── python/
│   │   └── runner.py                 # wrapper de execução e captura de erro
│   └── content/
│       └── chapters/                 # 01_basico.json, 02_controle.json, 03_funcoes.json
├── lib/
│   ├── main.dart
│   ├── app.dart                      # MaterialApp, rotas, tema, bottom navigation
│   ├── core/
│   │   ├── runtime/
│   │   │   ├── python_runtime.dart   # interface pública de execução
│   │   │   ├── pyodide_bridge.dart   # WebView headless + canais JS
│   │   │   └── execution_result.dart # ExecutionResult, PyError
│   │   ├── storage/
│   │   │   ├── database.dart         # abertura/migração SQLite
│   │   │   ├── code_repository.dart  # snippets do usuário
│   │   │   └── progress_repository.dart
│   │   └── theme/
│   │       └── ide_theme.dart        # tema escuro estilo IDE, tokens de acessibilidade
│   ├── data/
│   │   ├── models/                   # chapter, lesson, exercise, exercise_test, snippet, progress
│   │   └── content_loader.dart       # carrega e valida os JSON dos capítulos
│   └── features/
│       ├── editor/                   # editor_screen, code_editor_widget, editor_toolbar, file_drawer
│       ├── console/                  # console_panel, error_banner (linha clicável → cursor)
│       ├── exercises/                # lista por capítulo, exercise_screen, test_feedback_list
│       ├── lessons/                  # lesson_screen (exemplos comentados, "Abrir no editor")
│       └── progress/                 # progress_screen (% por capítulo)
└── test/
    ├── unit/  ├── widget/  └── integration/
```

**Componentes-chave**

| Componente | Responsabilidade |
|---|---|
| `PythonRuntime` | Fachada única: `initialize()`, `run(code)`, `stdout` stream, `interrupt()` |
| `PyodideBridge` | WebView invisível que carrega o Pyodide local e troca JSON com o Dart |
| `ExerciseChecker` | Concatena código do aluno + testes do exercício, roda no runtime, devolve pass/fail por teste |
| `CodeEditorWidget` | Wrapper do `flutter_code_editor`: highlight, gutter com linhas, `moveCursorToLine()` |
| `ConsolePanel` | Saída em streaming, banner de erro "NameError na linha 3" clicável, botão Parar |
| `CodeRepository` / `ProgressRepository` | CRUD em SQLite (tabelas `snippets` e `progress`) |

**Fluxos de usuário (MVP)**

1. **Escrever e executar**: aba Editor → digita → ▶ Executar → Console abre com stdout; em erro, banner com tipo + linha; tocar no banner leva o cursor à linha no editor.
2. **Exercício**: aba Exercícios → capítulo → exercício (enunciado + starter code no editor) → **Verificar** → testes rodam localmente → lista ✓/✗ com mensagem por teste → aprovado grava no SQLite e destrava o próximo.
3. **Exemplo comentado**: dentro da lição → "Abrir no editor" → aluno altera e executa livremente.
4. **Retomar**: app reaberto → último arquivo e progresso restaurados automaticamente.

**Interface estilo IDE móvel**: barra de ferramentas superior (arquivo atual, ▶, ⏹, salvar), gaveta lateral de arquivos, editor ocupando a área central, console em painel inferior deslizante (arrastar para expandir), banner de erro fixo acima do console.

**Acessibilidade e telas pequenas**: rótulos `Semantics` em todos os controles; alvos de toque ≥ 44 px; fonte do editor escalável e respeito ao `textScaleFactor` do sistema; contraste AA no tema escuro; console anuncia erros ao leitor de tela (`liveRegion`); layout testado a partir de 320 dp de largura, console vira tela cheia em aparelhos muito pequenos.

---

## 3) API interna: executar Python local e capturar erro com linha

### Contrato Dart

```dart
abstract class PythonRuntime {
  /// Carrega o runtime (uma vez por sessão, ~2–4 s). Idempotente.
  Future<void> initialize();

  /// Executa o código do aluno. Nunca lança — erros vêm em ExecutionResult.
  Future<ExecutionResult> run(String code,
      {Duration timeout = const Duration(seconds: 10)});

  /// Linhas de stdout em tempo real (para o console).
  Stream<String> get stdout;

  /// Interrompe execução em andamento (botão Parar / timeout).
  Future<void> interrupt();
}

class ExecutionResult {
  final bool ok;
  final String stdout;
  final PyError? error; // null quando ok == true
}

class PyError {
  final String type;      // "NameError", "SyntaxError", ...
  final String message;   // "name 'x' is not defined"
  final int? line;        // linha no código DO ALUNO (1-based)
  final String traceback; // texto completo, para o modo "detalhes"
}
```

### Como a linha é capturada (lado Python)

O código do aluno é compilado com o filename sentinela `"<exercicio>"`. Quando algo estoura, o traceback é percorrido e **o último frame cujo arquivo é `"<exercicio>"`** dá a linha exata no código do aluno (frames internos do runner são ignorados). `SyntaxError` é caso especial: a linha vem de `e.lineno`, antes mesmo de executar. O resultado volta como JSON pelo canal JS até o Dart.

### ExerciseChecker

Cada exercício traz `tests` no JSON — asserts nomeados ou pares entrada/saída esperada. O checker executa `código_do_aluno + bloco_de_testes` no mesmo runtime e devolve `List<TestResult>(name, passed, message)`, exibidos um a um na UI ("✓ soma(2,3) retorna 5", "✗ esperado 10, obtido 8").

Formato de um exercício (`assets/content/chapters/01_basico.json`):

```json
{
  "id": "cap01",
  "title": "Fundamentos",
  "lessons": [
    { "id": "l1", "title": "print e variáveis",
      "body": "…markdown…",
      "example": "# Este código mostra uma saudação\nnome = 'Ana'\nprint(f'Olá, {nome}!')" }
  ],
  "exercises": [
    { "id": "e1", "title": "Sua primeira função",
      "prompt": "Escreva uma função soma(a, b) que retorna a + b.",
      "starterCode": "def soma(a, b):\n    pass\n",
      "tests": [
        { "name": "soma(2, 3) == 5",  "code": "assert soma(2, 3) == 5" },
        { "name": "soma(-1, 1) == 0", "code": "assert soma(-1, 1) == 0" }
      ],
      "hints": ["Use a palavra-chave return."] }
  ]
}
```

---

## 4) Critérios de MVP e roadmap

### MVP (release 1.0) — critérios de aceite

- [ ] 4 telas: **Editor**, **Console**, **Exercícios**, **Progresso** (bottom navigation).
- [ ] Editor com highlight Python, números de linha, toolbar e seletor de arquivos; **sem autocomplete**.
- [ ] Executar código 100% offline; stdout no console; timeout de 10 s com interrupção.
- [ ] Todo erro exibido com **tipo + mensagem + linha**; tocar no erro posiciona o cursor.
- [ ] 3 capítulos (~10 exercícios cada) com lições, exemplos comentados e testes com feedback individual.
- [ ] Código e progresso persistem entre sessões (SQLite); último arquivo restaurado ao abrir.
- [ ] Acessibilidade básica: leitor de tela nas 4 telas, fonte escalável, alvos ≥ 44 px, contraste AA.
- [ ] Roda em iPhone SE e Android 320 dp sem cortes de layout.

### Roadmap pós-MVP

| Versão | Melhorias |
|---|---|
| 1.1 | Suporte a `input()` (prompt no console), tema claro/escuro, +3 capítulos |
| 1.2 | Múltiplos arquivos por projeto, execução passo a passo (trace com `sys.settrace`) |
| 1.3 | Conquistas/sequências de estudo, exportar/compartilhar código, ajuste de fonte do editor |
| 2.0 | Pacotes puro-Python selecionados (micropip offline), mini-REPL interativo |

---

## 5) Exemplos mínimos de código

### (a) Inicializar o projeto

```bash
flutter create app_python --org com.marcos.pyestudo --platforms ios,android
cd app_python
flutter pub add flutter_code_editor highlight flutter_highlight \
                webview_flutter sqflite shared_preferences path_provider path
mkdir -p assets/pyodide assets/python assets/content/chapters scripts
```

`scripts/fetch_pyodide.sh` (roda uma vez no setup; assets ficam no app, offline depois):

```bash
#!/usr/bin/env bash
set -euo pipefail
VERSION=0.26.4
BASE="https://cdn.jsdelivr.net/pyodide/v${VERSION}/full"
for f in pyodide.js pyodide.asm.js pyodide.asm.wasm python_stdlib.zip pyodide-lock.json; do
  curl -fL "${BASE}/${f}" -o "assets/pyodide/${f}"
done
echo "Pyodide ${VERSION} baixado para assets/pyodide/"
```

E no `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/pyodide/
    - assets/python/
    - assets/content/chapters/
```

### (b) Editor simples com cor de sintaxe (sem autocomplete)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/python.dart';

class CodeEditorWidget extends StatefulWidget {
  final String initialCode;
  final ValueChanged<String> onChanged;
  const CodeEditorWidget(
      {super.key, required this.initialCode, required this.onChanged});

  @override
  State<CodeEditorWidget> createState() => CodeEditorWidgetState();
}

class CodeEditorWidgetState extends State<CodeEditorWidget> {
  late final CodeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CodeController(
      text: widget.initialCode,
      language: python, // destaque de sintaxe; nenhum autocomplete é ligado
    );
    _controller.addListener(() => widget.onChanged(_controller.fullText));
  }

  /// Chamado quando o aluno toca no banner de erro.
  void moveCursorToLine(int line) {
    final offset = _controller.text
        .split('\n')
        .take(line - 1)
        .fold<int>(0, (sum, l) => sum + l.length + 1);
    _controller.selection = TextSelection.collapsed(offset: offset);
  }

  @override
  Widget build(BuildContext context) {
    return CodeTheme(
      data: CodeThemeData(styles: monokaiSublimeTheme),
      child: SingleChildScrollView(
        child: CodeField(
          controller: _controller,
          textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 16),
          gutterStyle: const GutterStyle(showLineNumbers: true),
        ),
      ),
    );
  }
}
```

### (c) Execução local e captura de erro com linha

**Lado Python — `assets/python/runner.py`** (é este código que roda dentro do Pyodide; a mesma lógica vale para qualquer CPython embarcado):

```python
import io, json, sys, traceback

USER_FILE = "<exercicio>"

def run_user_code(source: str) -> str:
    """Executa o código do aluno e devolve JSON: {ok, stdout, error{type,message,line,traceback}}."""
    out = io.StringIO()
    result = {"ok": True, "stdout": "", "error": None}
    old_out, old_err = sys.stdout, sys.stderr
    sys.stdout = sys.stderr = out
    try:
        code = compile(source, USER_FILE, "exec")
        exec(code, {"__name__": "__main__"})
    except SyntaxError as e:
        result["ok"] = False
        result["error"] = {
            "type": "SyntaxError", "message": e.msg,
            "line": e.lineno, "traceback": traceback.format_exc(),
        }
    except BaseException as e:
        line = None
        for frame in traceback.extract_tb(e.__traceback__):
            if frame.filename == USER_FILE:
                line = frame.lineno  # o último frame do aluno é o mais profundo
        result["ok"] = False
        result["error"] = {
            "type": type(e).__name__, "message": str(e),
            "line": line, "traceback": traceback.format_exc(),
        }
    finally:
        sys.stdout, sys.stderr = old_out, old_err
    result["stdout"] = out.getvalue()
    return json.dumps(result)
```

**Lado Dart — modelo do resultado e um runtime simulado** (mesmo contrato do runtime real; útil para desenvolver a UI e os testes de widget antes de plugar o Pyodide):

```dart
class PyError {
  final String type, message, traceback;
  final int? line;
  PyError({required this.type, required this.message,
           required this.traceback, this.line});

  factory PyError.fromJson(Map<String, dynamic> j) => PyError(
        type: j['type'], message: j['message'],
        line: j['line'], traceback: j['traceback']);
}

class ExecutionResult {
  final bool ok;
  final String stdout;
  final PyError? error;
  ExecutionResult({required this.ok, required this.stdout, this.error});

  factory ExecutionResult.fromJson(Map<String, dynamic> j) => ExecutionResult(
        ok: j['ok'], stdout: j['stdout'] ?? '',
        error: j['error'] == null ? null : PyError.fromJson(j['error']));
}

/// Simula a execução local: reconhece prints simples e nomes indefinidos,
/// devolvendo erro com a linha correta — igual ao runtime real faria.
class SimulatedPythonRuntime implements PythonRuntime {
  final _stdout = StreamController<String>.broadcast();
  @override Stream<String> get stdout => _stdout.stream;
  @override Future<void> initialize() async {}
  @override Future<void> interrupt() async {}

  @override
  Future<ExecutionResult> run(String code, {Duration? timeout}) async {
    final buffer = StringBuffer();
    final lines = code.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final print_ = RegExp(r'''^print\(["'](.*)["']\)$''').firstMatch(line);
      if (print_ != null) {
        buffer.writeln(print_.group(1));
        _stdout.add('${print_.group(1)}\n');
      } else {
        return ExecutionResult(ok: false, stdout: buffer.toString(),
          error: PyError(
            type: 'NameError',
            message: "name '${line.split(RegExp(r'\W')).first}' is not defined",
            line: i + 1, // linha 1-based, como o CPython reporta
            traceback: 'Traceback (most recent call last):\n'
                '  File "<exercicio>", line ${i + 1}, in <module>\nNameError',
          ));
      }
    }
    return ExecutionResult(ok: true, stdout: buffer.toString());
  }
}
```

**Ponte real (esboço)** — `PyodideRuntime.run()` chama a WebView headless:

```dart
final raw = await _webView.runJavaScriptReturningResult(
    'pyodide.globals.get("run_user_code")(${jsonEncode(code)})');
return ExecutionResult.fromJson(jsonDecode(raw as String));
```

---

## 6) Plano de testes e como rodar localmente

### Testes automatizados

| Nível | O que cobre | Ferramenta |
|---|---|---|
| Unit | Parsing do JSON de resultado → `PyError.line` correto para SyntaxError, erro no topo do módulo e erro dentro de função; repositórios SQLite; `ExerciseChecker` aprova/reprova corretamente | `flutter test` + `sqflite_common_ffi` (SQLite em memória no host) |
| Widget | Editor renderiza highlight e números de linha; console exibe stdout e banner de erro; tocar no banner move o cursor para a linha | `flutter test` com `SimulatedPythonRuntime` injetado |
| Integração | Fluxo completo em device/emulador: digitar → executar → ver saída real do Pyodide; resolver exercício → Progresso atualiza; matar e reabrir o app → estado restaurado | `integration_test` |
| CI | `flutter analyze` + `flutter test` a cada push | GitHub Actions |

### Testes manuais (matriz mínima)

- iPhone SE (menor iOS) e Android 320 dp — layout sem cortes, console utilizável.
- VoiceOver (iOS) e TalkBack (Android) nas 4 telas; erro de execução é anunciado.
- Fonte do sistema em 200%; rotação de tela; loop infinito → botão Parar/timeout funciona.

### Rodar localmente

```bash
flutter doctor                    # 1. verificar ambiente (Xcode p/ iOS, Android SDK)
./scripts/fetch_pyodide.sh        # 2. baixar runtime Python p/ assets (uma vez)
flutter pub get                   # 3. dependências
flutter test                      # 4. unit + widget
flutter run                       # 5. no simulador iOS ou emulador Android
flutter test integration_test     # 6. integração (com device/emulador aberto)
```

---

## Estimativas de tempo e recursos (1 dev experiente)

| Fase | Duração |
|---|---|
| Setup do projeto + runtime Pyodide + ponte Dart | 1,5 semana |
| Editor + console + erros com linha | 2 semanas |
| Persistência (SQLite) + modelo de conteúdo | 1 semana |
| Exercícios + checker + feedback | 1,5 semana |
| Progresso + navegação + acessibilidade | 1 semana |
| Conteúdo (3 capítulos) + testes + polimento | 2 semanas |
| **Total MVP** | **~9 semanas** |

Recursos: 1 desenvolvedor Flutter; Mac com Xcode (build iOS); contas Apple Developer (US$ 99/ano) e Google Play (US$ 25 única) para publicar; nenhum custo de servidor (app 100% offline).
