import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/auth/auth_service.dart';
import 'core/runtime/runtime_factory_mobile.dart'
    if (dart.library.js_interop) 'core/runtime/runtime_factory_web.dart';
import 'core/storage/database.dart';
import 'data/content_loader.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final db = await AppDatabase.open();
  final chapters = await ContentLoader().loadChapters();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    PyEstudoApp(
      runtime: await createRuntime(),
      db: db,
      chapters: chapters,
      prefs: prefs,
      authService: AuthService(),
    ),
  );
}
