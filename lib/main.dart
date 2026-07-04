import 'package:firebase_app_check/firebase_app_check.dart';
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

/// Site key do reCAPTCHA v3 (console: google.com/recaptcha/admin),
/// cadastrado para os domínios pyestudo-app.netlify.app e localhost.
const _recaptchaSiteKey = '6Lf780QtAAAAAA6gfOUpt53ywUs4t18qt4lbQiJJ';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    webProvider: ReCaptchaV3Provider(_recaptchaSiteKey),
    // Debug provider: gera um token de teste que precisa ser autorizado no
    // console (App Check > Apps > gerenciar tokens de depuração). Antes de
    // publicar o app na Play Store, trocar por AndroidProvider.playIntegrity.
    androidProvider: AndroidProvider.debug,
  );

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
