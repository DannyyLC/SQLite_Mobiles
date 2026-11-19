import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/data/database.dart';
import 'package:gestor_tareas_local/main.dart';

void main() {
  testWidgets('La pantalla inicial se muestra sin errores', (tester) async {
    // Base SQLite en memoria: las pruebas no tocan la base real de la app.
    final database = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(GestorTareasApp(database: database));
    expect(find.text('Gestor de tareas'), findsOneWidget);
    expect(find.text('Agregar tarea'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Desmontar la app cierra la base y cancela el Stream de consultas.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
