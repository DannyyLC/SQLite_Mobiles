import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/data/database.dart';

void main() {
  group('validarTitulo', () {
    test('quita los espacios al inicio y al final', () {
      expect(validarTitulo('  Comprar pan  '), 'Comprar pan');
    });

    test('rechaza títulos vacíos o solo con espacios (P5)', () {
      for (final titulo in ['', ' ', '   ', '\t\n']) {
        expect(
          () => validarTitulo(titulo),
          throwsA(isA<TituloInvalidoException>()),
          reason: 'titulo: "$titulo"',
        );
      }
    });
  });

  group('AppDatabase (SQLite en memoria)', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('INSERT + SELECT: guarda la tarea limpia y pendiente', () async {
      final id = await db.insertarTarea('  Estudiar Drift ');
      final tareas = await db.observarTareas().first;

      expect(tareas, hasLength(1));
      expect(tareas.single.id, id);
      expect(tareas.single.titulo, 'Estudiar Drift');
      expect(tareas.single.completada, isFalse);
    });

    test('no inserta títulos vacíos', () async {
      await expectLater(
        db.insertarTarea('   '),
        throwsA(isA<TituloInvalidoException>()),
      );
      expect(await db.observarTareas().first, isEmpty);
    });

    test('el CHECK de SQLite rechaza un título vacío aunque se salte la '
        'validación de Dart', () async {
      await expectLater(
        db.into(db.tareas).insert(TareasCompanion.insert(titulo: '   ')),
        throwsA(isA<SqliteException>()),
      );
    });

    test('UPDATE de título y de estado por id', () async {
      final id = await db.insertarTarea('Original');

      await db.actualizarTitulo(id, 'Editada');
      await db.cambiarEstado(id, true);

      final tarea = (await db.observarTareas().first).single;
      expect(tarea.titulo, 'Editada');
      expect(tarea.completada, isTrue);
    });

    test('no permite editar a un título vacío', () async {
      final id = await db.insertarTarea('Original');

      await expectLater(
        db.actualizarTitulo(id, '  '),
        throwsA(isA<TituloInvalidoException>()),
      );
      expect((await db.observarTareas().first).single.titulo, 'Original');
    });

    test('DELETE por id elimina solo esa tarea', () async {
      final a = await db.insertarTarea('A');
      final b = await db.insertarTarea('B');

      await db.eliminarTarea(a);

      final tareas = await db.observarTareas().first;
      expect(tareas.map((t) => t.id), [b]);
    });

    test(
      'operar sobre un id inexistente lanza TareaNoEncontradaException',
      () async {
        expect(
          db.cambiarEstado(999, true),
          throwsA(isA<TareaNoEncontradaException>()),
        );
        expect(
          db.actualizarTitulo(999, 'X'),
          throwsA(isA<TareaNoEncontradaException>()),
        );
        expect(
          db.eliminarTarea(999),
          throwsA(isA<TareaNoEncontradaException>()),
        );
      },
    );

    test('el Stream emite de nuevo después de cada escritura', () async {
      final emisiones = db.observarTareas().map((l) => l.length);
      final esperado = expectLater(emisiones, emitsInOrder([0, 1, 2]));

      await pumpEventQueue();
      await db.insertarTarea('Uno');
      await pumpEventQueue();
      await db.insertarTarea('Dos');
      await esperado;
    });
  });

  group('Persistencia en archivo (simula cerrar y reabrir la app)', () {
    late Directory dir;
    late File archivo;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('gestor_tareas_test_');
      archivo = File('${dir.path}/tareas.sqlite');
    });
    tearDown(() => dir.deleteSync(recursive: true));

    test('los cambios sobreviven a cerrar y abrir la base (P1–P4)', () async {
      // Primera ejecución.
      var db = AppDatabase(NativeDatabase(archivo));
      final a = await db.insertarTarea('A');
      final b = await db.insertarTarea('B');
      final c = await db.insertarTarea('C');
      await db.cambiarEstado(a, true);
      await db.actualizarTitulo(b, 'B editada');
      await db.eliminarTarea(c);
      await db.close();

      // Segunda ejecución: mismo archivo.
      db = AppDatabase(NativeDatabase(archivo));
      final tareas = await db.observarTareas().first;
      await db.close();

      expect(tareas, hasLength(2));
      expect(tareas[0].titulo, 'A');
      expect(tareas[0].completada, isTrue);
      expect(tareas[1].titulo, 'B editada');
      expect(tareas[1].completada, isFalse);
      expect(tareas.any((t) => t.id == c), isFalse);
    });
  });
}
