import 'package:flutter/material.dart';

import '../data/database.dart';
import '../models/tarea.dart';

// Pantalla principal con el CRUD de tareas.
class TareasPage extends StatefulWidget {
  final AppDatabase database;

  const TareasPage({super.key, required this.database});

  @override
  State<TareasPage> createState() => _TareasPageState();
}

class _TareasPageState extends State<TareasPage> {
  final TextEditingController _tituloController = TextEditingController();
  final FocusNode _tituloFocus = FocusNode();

  /// Se crea una vez; build() solo lo escucha.
  late final Stream<List<Tarea>> _tareasStream;

  @override
  void initState() {
    super.initState();
    _tareasStream = widget.database.observarTareas();
  }

  /// Ejecuta una operación y muestra los errores al usuario.
  Future<bool> _ejecutar(
    Future<void> Function() operacion,
    String accion,
  ) async {
    try {
      await operacion();
      return true;
    } on TituloInvalidoException catch (e) {
      _mostrarMensaje(e.toString());
    } on TareaNoEncontradaException catch (e) {
      _mostrarMensaje(e.toString());
    } catch (e) {
      _mostrarMensaje('No se pudo $accion. Detalle: $e');
    }
    return false;
  }

  Future<void> _agregarTarea() async {
    final ok = await _ejecutar(
      () => widget.database.insertarTarea(_tituloController.text),
      'guardar la tarea',
    );
    if (ok) _tituloController.clear();
    // Mantiene el foco para capturar otra tarea.
    _tituloFocus.requestFocus();
  }

  Future<void> _alternarCompletada(Tarea tarea, bool completada) async {
    await _ejecutar(
      () => widget.database.cambiarEstado(tarea.id, completada),
      'actualizar el estado',
    );
  }

  Future<void> _editarTarea(Tarea tarea) async {
    final nuevoTitulo = await showDialog<String>(
      context: context,
      builder: (_) => _EditarTituloDialog(tituloInicial: tarea.titulo),
    );
    if (nuevoTitulo == null || nuevoTitulo.trim() == tarea.titulo) return;

    final ok = await _ejecutar(
      () => widget.database.actualizarTitulo(tarea.id, nuevoTitulo),
      'editar la tarea',
    );
    if (ok) _mostrarMensaje('Título actualizado');
  }

  Future<void> _eliminarTarea(Tarea tarea) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar tarea'),
        content: Text('¿Eliminar "${tarea.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;

    final ok = await _ejecutar(
      () => widget.database.eliminarTarea(tarea.id),
      'eliminar la tarea',
    );
    if (ok) _mostrarMensaje('Tarea eliminada');
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _tituloFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestor de tareas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _tituloController,
              focusNode: _tituloFocus,
              decoration: const InputDecoration(
                labelText: 'Nueva tarea',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _agregarTarea(),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _agregarTarea,
              icon: const Icon(Icons.add),
              label: const Text('Agregar tarea'),
            ),
            const SizedBox(height: 12),
            const Text('Mis tareas', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<Tarea>>(
                stream: _tareasStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error al leer las tareas: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final tareas = snapshot.data!;
                  if (tareas.isEmpty) {
                    return const Center(
                      child: Text('Todavía no hay tareas guardadas'),
                    );
                  }
                  return ListView.builder(
                    itemCount: tareas.length,
                    itemBuilder: (context, index) {
                      final tarea = tareas[index];
                      return Card(
                        child: ListTile(
                          leading: Checkbox(
                            value: tarea.completada,
                            onChanged: (valor) {
                              if (valor != null) {
                                _alternarCompletada(tarea, valor);
                              }
                            },
                          ),
                          title: Text(
                            tarea.titulo,
                            style: tarea.completada
                                ? const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                  )
                                : null,
                          ),
                          subtitle: Text('ID: ${tarea.id}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Editar',
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editarTarea(tarea),
                              ),
                              IconButton(
                                tooltip: 'Eliminar',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _eliminarTarea(tarea),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Diálogo para editar el título.
class _EditarTituloDialog extends StatefulWidget {
  final String tituloInicial;

  const _EditarTituloDialog({required this.tituloInicial});

  @override
  State<_EditarTituloDialog> createState() => _EditarTituloDialogState();
}

class _EditarTituloDialogState extends State<_EditarTituloDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.tituloInicial,
  );
  String? _error;

  void _guardar() {
    try {
      Navigator.pop(context, validarTitulo(_controller.text));
    } on TituloInvalidoException catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar tarea'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(labelText: 'Título', errorText: _error),
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        onSubmitted: (_) => _guardar(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _guardar, child: const Text('Guardar')),
      ],
    );
  }
}
