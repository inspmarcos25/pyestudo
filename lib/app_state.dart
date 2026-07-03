import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/progress/streak.dart';
import 'core/runtime/exercise_checker.dart';
import 'core/runtime/execution_result.dart';
import 'core/runtime/python_runtime.dart';
import 'core/storage/code_repository.dart';
import 'core/storage/progress_repository.dart';
import 'data/models/models.dart';

/// Estado global do app (injetado via ListenableBuilder/InheritedNotifier).
class AppState extends ChangeNotifier {
  final PythonRuntime runtime;
  final CodeRepository codeRepository;
  final ProgressRepository progressRepository;
  final List<Chapter> chapters;
  final SharedPreferences prefs;

  late final ExerciseChecker checker = ExerciseChecker(runtime);

  static const _lastFileKey = 'last_file';
  static const _darkModeKey = 'dark_mode';
  static const defaultFileName = 'principal.py';
  static const defaultCode =
      "# Escreva seu código Python aqui\n"
      "print('Olá, mundo!')\n";

  String currentFileName;
  String currentCode;
  Brightness brightness;

  /// Respostas já dadas aos input() da execução atual (uma por linha).
  String _stdinBuffer = '';
  bool isRunning = false;
  ExecutionResult? lastResult;
  Set<String> completed = {};

  /// Uma data por exercício concluído — base do cálculo de sequência.
  List<DateTime> completionDays = [];

  AppState({
    required this.runtime,
    required this.codeRepository,
    required this.progressRepository,
    required this.chapters,
    required this.prefs,
    required this.currentFileName,
    required this.currentCode,
    required this.completed,
    this.completionDays = const [],
    this.brightness = Brightness.dark,
  });

  /// Restaura último arquivo, tema e progresso salvos.
  static Future<AppState> load({
    required PythonRuntime runtime,
    required CodeRepository codeRepository,
    required ProgressRepository progressRepository,
    required List<Chapter> chapters,
    required SharedPreferences prefs,
  }) async {
    final lastFile = prefs.getString(_lastFileKey) ?? defaultFileName;
    final snippet = await codeRepository.load(lastFile);
    final completed = await progressRepository.completedExercises();
    final completionDays = await progressRepository.completionDates();
    // Escuro é o padrão (estilo IDE clássico); só vira claro se o aluno
    // já tiver escolhido isso antes.
    final isDark = prefs.getBool(_darkModeKey) ?? true;
    return AppState(
      runtime: runtime,
      codeRepository: codeRepository,
      progressRepository: progressRepository,
      chapters: chapters,
      prefs: prefs,
      currentFileName: snippet?.name ?? defaultFileName,
      currentCode: snippet?.code ?? defaultCode,
      completed: completed,
      completionDays: completionDays,
      brightness: isDark ? Brightness.dark : Brightness.light,
    );
  }

  /// Sequência de dias consecutivos (até hoje ou ontem) com pelo menos um
  /// exercício concluído.
  int get streak => calculateStreak(completionDays);

  /// Quantos capítulos (com ao menos um exercício) estão 100% concluídos.
  int get chaptersFullyCompleted => chapters
      .where(
        (c) =>
            c.exercises.isNotEmpty &&
            c.exercises.every((e) => completed.contains(e.id)),
      )
      .length;

  Future<void> toggleBrightness() async {
    brightness = brightness == Brightness.dark
        ? Brightness.light
        : Brightness.dark;
    await prefs.setBool(_darkModeKey, brightness == Brightness.dark);
    notifyListeners();
  }

  void updateCode(String code) {
    currentCode = code;
    // sem notifyListeners: o editor já reflete o texto; salvar é explícito
  }

  Future<void> saveCurrentFile() async {
    await codeRepository.save(currentFileName, currentCode);
    await prefs.setString(_lastFileKey, currentFileName);
    notifyListeners();
  }

  Future<void> openFile(String name) async {
    await saveCurrentFile();
    final snippet = await codeRepository.load(name);
    currentFileName = name;
    currentCode = snippet?.code ?? '';
    lastResult = null;
    await prefs.setString(_lastFileKey, name);
    notifyListeners();
  }

  Future<void> createFile(String name) async {
    await saveCurrentFile();
    currentFileName = name;
    currentCode = '';
    lastResult = null;
    await codeRepository.save(name, '');
    await prefs.setString(_lastFileKey, name);
    notifyListeners();
  }

  /// Apaga um arquivo salvo. Se for o arquivo aberto no momento, volta
  /// para o arquivo padrão (recriando-o se necessário).
  Future<void> deleteFile(String name) async {
    await codeRepository.delete(name);
    if (currentFileName == name) {
      final fallback = await codeRepository.load(defaultFileName);
      currentFileName = defaultFileName;
      currentCode = fallback?.code ?? defaultCode;
      lastResult = null;
      await prefs.setString(_lastFileKey, defaultFileName);
    }
    notifyListeners();
  }

  /// Renomeia um arquivo salvo. Lança [StateError] se o novo nome já existir.
  Future<void> renameFile(String oldName, String newName) async {
    await codeRepository.rename(oldName, newName);
    if (currentFileName == oldName) {
      currentFileName = newName;
      await prefs.setString(_lastFileKey, newName);
    }
    notifyListeners();
  }

  /// Abre um exemplo de lição no editor, sem sobrescrever arquivos do aluno.
  void openExample(Lesson lesson) {
    currentFileName = '${lesson.id}.py';
    currentCode = lesson.example;
    lastResult = null;
    notifyListeners();
  }

  /// O console está aguardando o aluno responder a um input().
  bool get awaitingInput => lastResult?.needsInput ?? false;

  Future<ExecutionResult> runCurrentCode() {
    _stdinBuffer = '';
    return _run();
  }

  /// Resposta digitada no console: acumula e reexecuta o programa,
  /// que avança até o próximo input() ou até o fim.
  Future<ExecutionResult> submitInput(String line) {
    _stdinBuffer += '$line\n';
    return _run();
  }

  Future<ExecutionResult> _run() async {
    isRunning = true;
    notifyListeners();
    try {
      final result = await runtime.run(currentCode, stdinText: _stdinBuffer);
      lastResult = result;
      return result;
    } catch (e) {
      // Falha de infraestrutura (ex.: runtime não inicializou) nunca deve
      // derrubar a UI — vira um erro exibido no console, como qualquer outro.
      final result = ExecutionResult(
        ok: false,
        stdout: '',
        error: PyError(
          type: 'RuntimeError',
          message: 'não foi possível executar: $e',
          traceback: '',
        ),
      );
      lastResult = result;
      return result;
    } finally {
      isRunning = false;
      notifyListeners();
      await saveCurrentFile();
    }
  }

  Future<void> stopExecution() => runtime.interrupt();

  Future<List<TestResult>> checkExercise(
    Chapter chapter,
    Exercise exercise,
    String code,
  ) async {
    List<TestResult> results;
    try {
      results = await checker.check(exercise, code);
    } catch (e) {
      results = [
        TestResult(
          name: 'Execução',
          passed: false,
          message: 'não foi possível verificar: $e',
        ),
      ];
    }
    if (ExerciseChecker.allPassed(results)) {
      await progressRepository.markCompleted(chapter.id, exercise.id);
      completed = await progressRepository.completedExercises();
      completionDays = await progressRepository.completionDates();
      notifyListeners();
    }
    return results;
  }

  double chapterProgress(Chapter chapter) {
    if (chapter.exercises.isEmpty) return 0;
    final done = chapter.exercises
        .where((e) => completed.contains(e.id))
        .length;
    return done / chapter.exercises.length;
  }
}
