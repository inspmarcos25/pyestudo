import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'app_state.dart';
import 'core/auth/auth_service.dart';
import 'core/i18n/app_language.dart';
import 'core/i18n/app_strings.dart';
import 'core/i18n/locale_controller.dart';
import 'core/runtime/pyodide_runtime.dart';
import 'core/runtime/python_runtime.dart';
import 'core/theme/brightness_controller.dart';
import 'core/theme/ide_theme.dart';
import 'data/models/models.dart';
import 'features/auth/auth_gate.dart';
import 'features/editor/editor_screen.dart';
import 'features/exercises/exercises_screen.dart';
import 'features/learn/learn_screen.dart';
import 'features/progress/progress_screen.dart';

class PyEstudoApp extends StatefulWidget {
  final PythonRuntime runtime;
  final Database db;
  final Map<AppLanguage, List<Chapter>> chaptersByLanguage;
  final SharedPreferences prefs;
  final AuthService authService;
  final FirebaseFirestore? firestore;

  const PyEstudoApp({
    super.key,
    required this.runtime,
    required this.db,
    required this.chaptersByLanguage,
    required this.prefs,
    required this.authService,
    this.firestore,
  });

  @override
  State<PyEstudoApp> createState() => _PyEstudoAppState();
}

class _PyEstudoAppState extends State<PyEstudoApp> {
  late final LocaleController _locale = LocaleController(widget.prefs);
  late final BrightnessController _brightness = BrightnessController(
    widget.prefs,
  );

  @override
  void dispose() {
    _locale.dispose();
    _brightness.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LocaleScope(
      controller: _locale,
      child: ListenableBuilder(
        listenable: Listenable.merge([_locale, _brightness]),
        builder: (context, _) => MaterialApp(
          title: 'PyEstudo',
          // Só `theme` (sem `darkTheme`): o MaterialApp segue exatamente a
          // preferência do usuário, nunca o tema do sistema — e isso vale
          // para toda rota empurrada via Navigator.push, não só o HomeShell.
          theme: buildIdeTheme(brightness: _brightness.brightness),
          locale: Locale(_locale.language.code),
          supportedLocales: const [Locale('pt'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: AuthGate(
            runtime: widget.runtime,
            db: widget.db,
            chaptersByLanguage: widget.chaptersByLanguage,
            locale: _locale,
            brightnessController: _brightness,
            prefs: widget.prefs,
            authService: widget.authService,
            firestore: widget.firestore,
          ),
        ),
      ),
    );
  }
}

/// Shell com a navegação inferior entre as 3 áreas (o Console é um painel
/// dentro do Editor). Hospeda também a WebView invisível do Pyodide.
class HomeShell extends StatefulWidget {
  final AppState state;

  const HomeShell({super.key, required this.state});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final runtime = widget.state.runtime;
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final strings = AppStrings.of(widget.state.language);
        return Theme(
        data: buildIdeTheme(brightness: widget.state.brightness),
        child: Scaffold(
          body: Stack(
            children: [
              // WebView headless que executa o Pyodide (tamanho zero, invisível).
              if (runtime is PyodideRuntime)
                Offstage(
                  child: SizedBox(
                    width: 1,
                    height: 1,
                    child: WebViewWidget(controller: runtime.controller),
                  ),
                ),
              IndexedStack(
                index: _tab,
                children: [
                  EditorScreen(state: widget.state),
                  LearnScreen(
                    state: widget.state,
                    onOpenInEditor: () => setState(() => _tab = 0),
                  ),
                  ExercisesScreen(state: widget.state),
                  ProgressScreen(state: widget.state),
                ],
              ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.code),
                label: strings.editorTab,
                tooltip: strings.editorTooltip,
              ),
              NavigationDestination(
                icon: const Icon(Icons.menu_book_outlined),
                selectedIcon: const Icon(Icons.menu_book),
                label: strings.learnTab,
                tooltip: strings.learnTooltip,
              ),
              NavigationDestination(
                icon: const Icon(Icons.fitness_center_outlined),
                selectedIcon: const Icon(Icons.fitness_center),
                label: strings.exercisesTab,
                tooltip: strings.exercisesTooltip,
              ),
              NavigationDestination(
                icon: const Icon(Icons.insights_outlined),
                selectedIcon: const Icon(Icons.insights),
                label: strings.progressTab,
                tooltip: strings.progressTooltip,
              ),
            ],
          ),
        ),
      );
      },
    );
  }
}
