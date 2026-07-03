import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'app_state.dart';
import 'core/runtime/runtime_factory_mobile.dart'
    if (dart.library.js_interop) 'core/runtime/runtime_factory_web.dart';
import 'core/storage/code_repository.dart';
import 'core/storage/database.dart';
import 'core/storage/progress_repository.dart';
import 'data/content_loader.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = await AppDatabase.open();
  final chapters = await ContentLoader().loadChapters();
  final prefs = await SharedPreferences.getInstance();

  final state = await AppState.load(
    runtime: await createRuntime(),
    codeRepository: CodeRepository(db),
    progressRepository: ProgressRepository(db),
    chapters: chapters,
    prefs: prefs,
  );

  runApp(PyEstudoApp(state: state));
}
