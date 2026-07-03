import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'execution_result.dart';
import 'python_runtime.dart';

/// Runtime para Flutter Web: roda o Pyodide dentro de um Web Worker.
///
/// Um Worker é uma thread real do sistema operacional, separada da thread
/// principal do navegador (onde o app Flutter roda). Isso é o que permite
/// interromper de verdade uma execução travada — `Worker.terminate()` mata
/// a thread instantaneamente, mesmo presa num `while True: pass`, sem
/// qualquer cooperação do código em execução, e sem nunca travar a aba
/// (diferente de um `<iframe>` da mesma origem, que compartilha a thread
/// JS da página principal e trava junto).
class WebPyodideRuntime implements PythonRuntime {
  final _stdoutController = StreamController<String>.broadcast();
  final _pending = <String, Completer<String>>{};

  // No Flutter Web os assets são servidos sob "assets/<caminho no pubspec>".
  static const _workerUrl = 'assets/assets/pyodide/worker.js';

  JSObject? _worker;
  Completer<void>? _ready;
  Future<void>? _interrupting;
  bool _running = false;
  int _requestCounter = 0;

  @override
  Stream<String> get stdout => _stdoutController.stream;

  @override
  Future<void> initialize() {
    if (_ready != null) return _ready!.future;
    _ready = Completer<void>();
    _createWorker();
    return _ready!.future;
  }

  void _createWorker() {
    try {
      final workerClass =
          globalContext.getProperty('Worker'.toJS) as JSFunction;
      final worker = workerClass.callAsConstructor<JSObject>(_workerUrl.toJS);
      worker.setProperty('onmessage'.toJS, _onMessage.toJS);
      worker.setProperty('onerror'.toJS, _onError.toJS);
      _worker = worker;
    } catch (e) {
      if (!_ready!.isCompleted) _ready!.completeError(e);
    }
  }

  void _onMessage(JSObject event) {
    final data = event.getProperty('data'.toJS) as JSObject;
    final channel = (data.getProperty('channel'.toJS) as JSString).toDart;
    final payload = (data.getProperty('data'.toJS) as JSString).toDart;
    switch (channel) {
      case 'PyReady':
        if (_ready == null || _ready!.isCompleted) return;
        if (payload == 'ok') {
          _ready!.complete();
        } else {
          _ready!.completeError(StateError('Pyodide falhou: $payload'));
        }
      case 'PyStdout':
        _stdoutController.add(payload);
      case 'PyResult':
        final decoded = jsonDecode(payload) as Map<String, dynamic>;
        final id = decoded['requestId'] as String;
        _pending.remove(id)?.complete(decoded['resultJson'] as String);
    }
  }

  void _onError(JSObject event) {
    if (_ready != null && !_ready!.isCompleted) {
      _ready!.completeError(StateError('worker do Pyodide falhou ao carregar'));
    }
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
      final msg = JSObject()
        ..setProperty('kind'.toJS, kind.toJS)
        ..setProperty('requestId'.toJS, id.toJS)
        ..setProperty('a'.toJS, a.toJS)
        ..setProperty('b'.toJS, b.toJS);
      _worker!.callMethod('postMessage'.toJS, msg);
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

  Future<void> _doInterrupt() async {
    if (!_running && _pending.isEmpty) return;
    for (final c in _pending.values) {
      if (!c.isCompleted) c.completeError(StateError('runtime reiniciado'));
    }
    _pending.clear();
    // Mata a thread de verdade, mesmo presa num laço infinito.
    _worker?.callMethod('terminate'.toJS);
    _worker = null;
    _ready = Completer<void>();
    _createWorker();
    await _ready!.future;
  }

  @override
  void dispose() {
    _stdoutController.close();
    _worker?.callMethod('terminate'.toJS);
  }
}
