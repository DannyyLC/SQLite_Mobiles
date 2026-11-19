/// Modelo de tarea (fila de la tabla `tareas`).
class Tarea {
  final int id;
  final String titulo;
  final bool completada;

  const Tarea({
    required this.id,
    required this.titulo,
    required this.completada,
  });
}
