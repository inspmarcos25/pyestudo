import 'package:sqflite/sqflite.dart' show DatabaseFactory;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Web: SQLite compilado para WASM, persistido em IndexedDB.
/// Requer web/sqlite3.wasm (gerado com `dart run sqflite_common_ffi_web:setup`).
/// Variante sem web worker: funciona em qualquer contexto de navegador.
DatabaseFactory get dbFactory => databaseFactoryFfiWebNoWebWorker;

Future<String> databasesPath() async => '/';
