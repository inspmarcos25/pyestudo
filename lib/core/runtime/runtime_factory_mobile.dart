import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';

import 'pyodide_runtime.dart';
import 'python_runtime.dart';
import 'simulated_python_runtime.dart';

/// iOS/Android: Pyodide numa WebView headless quando os assets existem;
/// caso contrário, runtime simulado.
Future<PythonRuntime> createRuntime() async {
  try {
    await rootBundle.load('assets/pyodide/pyodide.js');
    return PyodideRuntime(WebViewController());
  } catch (_) {
    debugPrint(
      'Assets do Pyodide ausentes — usando runtime simulado. '
      'Rode scripts/fetch_pyodide.sh para habilitar o CPython real.',
    );
    return SimulatedPythonRuntime();
  }
}
