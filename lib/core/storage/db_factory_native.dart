import 'package:sqflite/sqflite.dart';

/// iOS/Android (e testes com sqflite_common_ffi): usa a factory global.
DatabaseFactory get dbFactory => databaseFactory;

Future<String> databasesPath() => databaseFactory.getDatabasesPath();
