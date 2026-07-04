import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'app_state.dart';
import 'core/auth/auth_service.dart';
import 'core/runtime/pyodide_runtime.dart';
import 'core/runtime/python_runtime.dart';
import 'core/theme/ide_theme.dart';
import 'data/models/models.dart';
import 'features/auth/auth_gate.dart';
import 'features/editor/editor_screen.dart';
import 'features/exercises/exercises_screen.dart';
import 'features/progress/progress_screen.dart';

class PyEstudoApp extends StatelessWidget {
  final PythonRuntime runtime;
  final Database db;
  final List<Chapter> chapters;
  final SharedPreferences prefs;
  final AuthService authService;
  final FirebaseFirestore? firestore;

  const PyEstudoApp({
    super.key,
    required this.runtime,
    required this.db,
    required this.chapters,
    required this.prefs,
    required this.authService,
    this.firestore,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PyEstudo',
      theme: buildIdeTheme(brightness: Brightness.dark),
      darkTheme: buildIdeTheme(brightness: Brightness.dark),
      home: AuthGate(
        runtime: runtime,
        db: db,
        chapters: chapters,
        prefs: prefs,
        authService: authService,
        firestore: firestore,
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
      builder: (context, _) => Theme(
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
                  ExercisesScreen(
                    state: widget.state,
                    onOpenInEditor: () => setState(() => _tab = 0),
                  ),
                  ProgressScreen(state: widget.state),
                ],
              ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.code),
                label: 'Editor',
                tooltip: 'Editor e console',
              ),
              NavigationDestination(
                icon: Icon(Icons.school_outlined),
                selectedIcon: Icon(Icons.school),
                label: 'Exercícios',
                tooltip: 'Lições e exercícios',
              ),
              NavigationDestination(
                icon: Icon(Icons.insights_outlined),
                selectedIcon: Icon(Icons.insights),
                label: 'Progresso',
                tooltip: 'Seu progresso',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
