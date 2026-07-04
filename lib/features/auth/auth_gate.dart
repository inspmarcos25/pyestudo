import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../app.dart';
import '../../app_state.dart';
import '../../core/auth/auth_service.dart';
import '../../core/runtime/python_runtime.dart';
import '../../core/storage/code_repository.dart';
import '../../core/storage/progress_repository.dart';
import '../../core/sync/firestore_sync_service.dart';
import '../../core/sync/sync_coordinator.dart';
import '../../data/models/models.dart';
import 'login_screen.dart';

/// Sem login -> [LoginScreen]. Com login -> hidrata/migra os dados da
/// conta uma vez e então mostra o app ([HomeShell]).
///
/// Repositórios locais só são criados aqui, depois que o uid é conhecido,
/// para garantir que cada conta só enxergue os próprios dados no mesmo
/// navegador/dispositivo.
class AuthGate extends StatefulWidget {
  final PythonRuntime runtime;
  final Database db;
  final List<Chapter> chapters;
  final SharedPreferences prefs;
  final AuthService authService;

  /// Instância do Firestore a usar; `null` usa `FirebaseFirestore.instance`
  /// (permite injetar um fake nos testes, sem tocar num projeto real).
  final FirebaseFirestore? firestore;

  const AuthGate({
    super.key,
    required this.runtime,
    required this.db,
    required this.chapters,
    required this.prefs,
    required this.authService,
    this.firestore,
  });

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _hydratedForUid;
  Future<AppState>? _stateFuture;

  Future<AppState> _buildState(String uid) async {
    final codeRepository = CodeRepository(widget.db, userId: uid);
    final progressRepository = ProgressRepository(widget.db, userId: uid);
    final syncService = FirestoreSyncService(
      uid,
      firestore: widget.firestore,
    );
    await SyncCoordinator(
      codeRepository: codeRepository,
      progressRepository: progressRepository,
      sync: syncService,
    ).hydrateAndMigrate(uid);
    return AppState.load(
      runtime: widget.runtime,
      codeRepository: codeRepository,
      progressRepository: progressRepository,
      chapters: widget.chapters,
      prefs: widget.prefs,
      authService: widget.authService,
      syncService: syncService,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: widget.authService.authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;
        final waiting =
            !snapshot.hasData &&
            snapshot.connectionState == ConnectionState.waiting;
        if (waiting) {
          return const _Splash();
        }
        if (user == null) {
          _hydratedForUid = null;
          _stateFuture = null;
          return const LoginScreen();
        }
        if (_hydratedForUid != user.uid) {
          _hydratedForUid = user.uid;
          _stateFuture = _buildState(user.uid);
        }
        return FutureBuilder<AppState>(
          future: _stateFuture,
          builder: (context, snap) {
            if (!snap.hasData) return const _Splash();
            return HomeShell(state: snap.data!);
          },
        );
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
