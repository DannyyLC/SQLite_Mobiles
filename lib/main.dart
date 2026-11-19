import 'package:flutter/material.dart';

import 'data/database.dart';
import 'screens/tareas_page.dart';

void main() {
  runApp(const GestorTareasApp());
}

/// Punto de entrada de la aplicación.
/// Crea una única instancia de la base de datos y la cierra al desmontarse.
class GestorTareasApp extends StatefulWidget {
  /// Permite inyectar una base distinta (p. ej. en memoria para pruebas).
  final AppDatabase? database;

  const GestorTareasApp({super.key, this.database});

  @override
  State<GestorTareasApp> createState() => _GestorTareasAppState();
}

class _GestorTareasAppState extends State<GestorTareasApp> {
  late final AppDatabase _database = widget.database ?? AppDatabase();

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestor de tareas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: TareasPage(database: _database),
    );
  }
}
