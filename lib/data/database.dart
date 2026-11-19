import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../models/tarea.dart';

part 'database.g.dart';

/// Tabla `tareas` (ver esquema en README.md).
///
/// `@UseRowClass(Tarea)` hace que Drift devuelva directamente el modelo
/// `Tarea` de `lib/models/` en lugar de generar una clase de fila propia.
@UseRowClass(Tarea)
class Tareas extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// CHECK en SQLite: el título no puede quedar vacío tras quitar espacios.
  /// (Drift usa la propia columna dentro de check(); no es una recursión real.)
  TextColumn get titulo =>
      // ignore: recursive_getters
      text().check(titulo.trim().length.isBiggerOrEqualValue(1))();

  BoolColumn get completada => boolean().withDefault(const Constant(false))();
}

/// Excepción para títulos vacíos o compuestos solo por espacios.
class TituloInvalidoException implements Exception {
  const TituloInvalidoException();

  @override
  String toString() => 'El título de la tarea no puede estar vacío.';
}

/// Limpia el título y lo valida. Lanza [TituloInvalidoException] si queda vacío.
String validarTitulo(String titulo) {
  final limpio = titulo.trim();
  if (limpio.isEmpty) throw const TituloInvalidoException();
  return limpio;
}

@DriftDatabase(tables: [Tareas])
class AppDatabase extends _$AppDatabase {
  /// Sin argumentos abre la base persistente de la plataforma actual.
  /// En pruebas se puede inyectar otro ejecutor (p. ej. una base en memoria).
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _abrirConexion());

  @override
  int get schemaVersion => 1;

  /// Nativo: archivo `gestor_tareas.sqlite` en el directorio de documentos
  /// de la app (path_provider). Web: SQLite en WebAssembly, almacenado en
  /// OPFS o IndexedDB según lo que soporte el navegador.
  static QueryExecutor _abrirConexion() {
    return driftDatabase(
      name: 'gestor_tareas',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }

  /// SELECT reactivo: emite la lista de nuevo tras cada escritura en `tareas`.
  Stream<List<Tarea>> observarTareas() {
    return (select(tareas)..orderBy([(t) => OrderingTerm.asc(t.id)])).watch();
  }

  /// INSERT de una tarea nueva (pendiente). Devuelve el `id` asignado.
  Future<int> insertarTarea(String titulo) {
    return into(tareas)
        .insert(TareasCompanion.insert(titulo: validarTitulo(titulo)));
  }
}
