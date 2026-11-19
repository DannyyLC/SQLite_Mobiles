import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/data/database.dart';
import 'package:gestor_tareas_local/main.dart';

void main() {
  testWidgets('La pantalla inicial se muestra sin errores', (tester) async {
    // Base en memoria, no toca la real.
    final database = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(GestorTareasApp(database: database));
    expect(find.text('Gestor de tareas'), findsOneWidget);
    expect(find.text('Agregar tarea'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Desmontar cierra la base.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('Un título vacío muestra aviso y no se registra (P5)', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(GestorTareasApp(database: database));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '    ');
    await tester.tap(find.text('Agregar tarea'));
    await tester.pumpAndSettle();

    expect(
      find.text('El título de la tarea no puede estar vacío.'),
      findsOneWidget,
    );
    expect(find.text('Todavía no hay tareas guardadas'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('Agregar desde la interfaz guarda y muestra la tarea', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(GestorTareasApp(database: database));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '  Entregar práctica ');
    await tester.tap(find.text('Agregar tarea'));
    await tester.pumpAndSettle();

    expect(find.text('Entregar práctica'), findsOneWidget);
    expect(find.text('Todavía no hay tareas guardadas'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
