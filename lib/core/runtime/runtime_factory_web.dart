import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'python_runtime.dart';
import 'simulated_python_runtime.dart';
import 'web_pyodide_runtime.dart';

/// Web: Pyodide carregado direto na página quando os assets existem;
/// caso contrário, runtime simulado.
Future<PythonRuntime> createRuntime() async {
  try {
    await rootBundle.load('assets/pyodide/pyodide.js');
    return WebPyodideRuntime();
  } catch (_) {
    debugPrint(
      'Assets do Pyodide ausentes — usando runtime simulado. '
      'Rode scripts/fetch_pyodide.sh para habilitar o CPython real.',
    );
    return SimulatedPythonRuntime();
  }
}
