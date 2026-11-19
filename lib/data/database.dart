import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../models/tarea.dart';

part 'database.g.dart';

/// Tabla `tareas`; sus filas se leen como el modelo `Tarea`.
@UseRowClass(Tarea)
class Tareas extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// CHECK: título no vacío tras quitar espacios.
  TextColumn get titulo =>
      // ignore: recursive_getters
      text().check(titulo.trim().length.isBiggerOrEqualValue(1))();

  BoolColumn get completada => boolean().withDefault(const Constant(false))();
}

/// Título vacío o solo con espacios.
class TituloInvalidoException implements Exception {
  const TituloInvalidoException();

  @override
  String toString() => 'El título de la tarea no puede estar vacío.';
}

/// El `id` ya no existe en la base.
class TareaNoEncontradaException implements Exception {
  final int id;

  const TareaNoEncontradaException(this.id);

  @override
  String toString() => 'La tarea con ID $id ya no existe.';
}

/// Aplica trim() y rechaza títulos vacíos.
String validarTitulo(String titulo) {
  final limpio = titulo.trim();
  if (limpio.isEmpty) throw const TituloInvalidoException();
  return limpio;
}

@DriftDatabase(tables: [Tareas])
class AppDatabase extends _$AppDatabase {
  /// Sin argumento usa la base real; en pruebas, una en memoria.
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _abrirConexion());

  @override
  int get schemaVersion => 1;

  /// Abre la base según la plataforma (archivo nativo o WASM en web).
  static QueryExecutor _abrirConexion() {
    return driftDatabase(
      name: 'gestor_tareas',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }

  /// SELECT reactivo de todas las tareas.
  Stream<List<Tarea>> observarTareas() {
    return (select(tareas)..orderBy([(t) => OrderingTerm.asc(t.id)])).watch();
  }

  /// INSERT; devuelve el `id` asignado.
  Future<int> insertarTarea(String titulo) async {
    return into(tareas)
        .insert(TareasCompanion.insert(titulo: validarTitulo(titulo)));
  }

  /// UPDATE del título por `id`.
  Future<void> actualizarTitulo(int id, String nuevoTitulo) async {
    final titulo = validarTitulo(nuevoTitulo);
    final filas = await (update(tareas)..where((t) => t.id.equals(id))).write(
      TareasCompanion(titulo: Value(titulo)),
    );
    if (filas == 0) throw TareaNoEncontradaException(id);
  }

  /// UPDATE del estado por `id`.
  Future<void> cambiarEstado(int id, bool completada) async {
    final filas = await (update(tareas)..where((t) => t.id.equals(id))).write(
      TareasCompanion(completada: Value(completada)),
    );
    if (filas == 0) throw TareaNoEncontradaException(id);
  }

  /// DELETE por `id`.
  Future<void> eliminarTarea(int id) async {
    final filas = await (delete(tareas)..where((t) => t.id.equals(id))).go();
    if (filas == 0) throw TareaNoEncontradaException(id);
  }
}
