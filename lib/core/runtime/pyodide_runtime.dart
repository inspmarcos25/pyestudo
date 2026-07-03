import 'dart:async';
import 'dart:convert';

import 'package:webview_flutter/webview_flutter.dart';

import 'execution_result.dart';
import 'python_runtime.dart';

/// Runtime real: CPython 3.12 (Pyodide/WebAssembly) numa WebView headless.
///
/// A WebView carrega `assets/pyodide/bootstrap.html`, que inicializa o
/// Pyodide e busca o `runner.py` por fetch relativo (nada é injetado via
/// runJavaScript antes da navegação — isso perderia o valor, já que
/// navegar cria um novo contexto JS). Cada execução é despachada por
/// `execRequest` e o resultado chega pelo canal `PyResult`, nunca pelo
/// valor de retorno de `runJavaScriptReturningResult` (que não aguarda
/// Promises de forma confiável em todas as plataformas).
///
/// A WebView precisa estar montada na árvore de widgets (num Offstage de
/// tamanho zero) — ver `HomeShell` em app.dart.
class PyodideRuntime implements PythonRuntime {
  final WebViewController controller;
  final _stdoutController = StreamController<String>.broadcast();
  final _pending = <String, Completer<String>>{};
  Completer<void>? _ready;
  Future<void>? _interrupting;
  bool _running = false;
  int _requestCounter = 0;

  PyodideRuntime(this.controller);

  @override
  Stream<String> get stdout => _stdoutController.stream;

  @override
  Future<void> initialize() {
    if (_ready != null) return _ready!.future;
    _ready = Completer<void>();
    _boot();
    return _ready!.future;
  }

  Future<void> _boot() async {
    try {
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.addJavaScriptChannel(
        'PyStdout',
        onMessageReceived: (msg) => _stdoutController.add(msg.message),
      );
      await controller.addJavaScriptChannel(
        'PyReady',
        onMessageReceived: (msg) {
          if (_ready == null || _ready!.isCompleted) return;
          if (msg.message == 'ok') {
            _ready!.complete();
          } else {
            _ready!.completeError(StateError('Pyodide falhou: ${msg.message}'));
          }
        },
      );
      await controller.addJavaScriptChannel(
        'PyResult',
        onMessageReceived: (msg) => _handleResult(msg.message),
      );
      await controller.loadFlutterAsset('assets/pyodide/bootstrap.html');
    } catch (e) {
      if (!_ready!.isCompleted) _ready!.completeError(e);
    }
  }

  void _handleResult(String raw) {
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final id = decoded['requestId'] as String;
    _pending.remove(id)?.complete(decoded['resultJson'] as String);
  }

  Future<String> _call(
    String kind,
    String a,
    String b, {
    required Duration timeout,
  }) async {
    await initialize();
    final id = '${DateTime.now().microsecondsSinceEpoch}-${_requestCounter++}';
    final completer = Completer<String>();
    _pending[id] = completer;
    _running = true;
    try {
      final argsJson = jsonEncode({
        'kind': kind,
        'requestId': id,
        'a': a,
        'b': b,
      });
      await controller.runJavaScript(
        'window.execRequest(${jsonEncode(argsJson)})',
      );
      return await completer.future.timeout(timeout);
    } on TimeoutException {
      _pending.remove(id);
      await interrupt();
      rethrow;
    } finally {
      _running = false;
    }
  }

  @override
  Future<ExecutionResult> run(
    String code, {
    String stdinText = '',
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final resultJson = await _call('run', code, stdinText, timeout: timeout);
      return ExecutionResult.fromJson(
        jsonDecode(resultJson) as Map<String, dynamic>,
      );
    } on TimeoutException {
      return ExecutionResult(
        ok: false,
        stdout: '',
        error: PyError(
          type: 'TimeoutError',
          message:
              'execução interrompida após ${timeout.inSeconds}s (laço infinito?)',
          traceback: '',
        ),
      );
    }
  }

  @override
  Future<List<TestResult>> runTests(
    String code,
    List<({String name, String code})> tests, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final testsJson = jsonEncode([
      for (final t in tests) {'name': t.name, 'code': t.code},
    ]);
    final resultJson = await _call('tests', code, testsJson, timeout: timeout);
    final decoded = jsonDecode(resultJson) as Map<String, dynamic>;
    return [
      for (final t in decoded['tests'] as List)
        TestResult.fromJson(t as Map<String, dynamic>),
    ];
  }

  @override
  Future<void> interrupt() {
    if (_interrupting != null) return _interrupting!;
    final future = _doInterrupt();
    _interrupting = future;
    return future.whenComplete(() => _interrupting = null);
  }

  /// Recarrega a WebView do zero. Diferente de um SharedArrayBuffer/worker,
  /// isto funciona mesmo com o JS travado num laço infinito: navegar para
  /// uma nova página descarta o contexto JS anterior independentemente do
  /// que ele estava fazendo — a navegação é controlada pelo motor da
  /// WebView, não pela thread de JS presa.
  Future<void> _doInterrupt() async {
    if (!_running && _pending.isEmpty) return;
    for (final c in _pending.values) {
      if (!c.isCompleted) c.completeError(StateError('runtime reiniciado'));
    }
    _pending.clear();
    _ready = null;
    await controller.loadFlutterAsset('assets/pyodide/bootstrap.html');
    await initialize();
  }

  @override
  void dispose() {
    _stdoutController.close();
  }
}
