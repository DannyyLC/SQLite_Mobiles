# Gestor de tareas con SQLite multiplataforma

Aplicación Flutter que administra tareas en una base de datos **SQLite local**, sin servidor ni conexión a internet. Permite agregar, listar, editar el título, marcar como completada o pendiente y eliminar tareas. Las tareas se conservan entre ejecuciones.

La misma base de código está diseñada para Android, iOS, Windows, Linux, macOS y web. Los datos no se sincronizan entre dispositivos: cada instalación (o cada origen y perfil del navegador) tiene su propia base.

## Requisitos

- Flutter 3.47 / Dart 3.13 o compatible (`flutter doctor -v`).
- Para la versión nativa en Linux: las dependencias de escritorio que indique `flutter doctor`.

## Cómo ejecutar

```bash
git clone <url-del-repositorio>
cd Practica_SQLite
flutter pub get
flutter analyze
flutter test
```

**Escritorio (Linux):**

```bash
flutter run -d linux
```

**Web:**

```bash
flutter run -d chrome
```

> `flutter run -d chrome` abre Chrome con un **perfil temporal** que se borra al terminar la sesión. Recargar la página (R) conserva los datos, pero una nueva ejecución de `flutter run` empieza vacía. Para comprobar la persistencia en web (P6), sirve la app en un puerto fijo y ábrela en tu Chrome normal:
>
> ```bash
> flutter build web
> python3 -m http.server 8080 -d build/web
> # abrir http://127.0.0.1:8080
> ```

El código generado por Drift (`lib/data/database.g.dart`) está incluido en el repositorio. Solo hay que regenerarlo si cambia la tabla:

```bash
dart run build_runner build
```

## Decisiones de diseño

### Tecnología de persistencia: Drift + drift_flutter

| Paquete | Versión | Uso |
|---|---|---|
| `drift` | ^2.35.4 | ORM sobre SQLite: define tablas en Dart y genera consultas con tipos verificados. |
| `drift_flutter` | ^0.3.1 | Abre la base de datos con la configuración adecuada para cada plataforma. |
| `drift_dev` (dev) | ^2.35.3 | Generador de código de Drift (tabla, companions, clase base de la base de datos). |
| `build_runner` (dev) | ^2.17.1 | Ejecuta el generador: `dart run build_runner build` (en 2.17 la opción `--delete-conflicting-outputs` ya no existe y se ignora). |

Razones de la elección:

- **Una sola base de código para las seis plataformas.** `drift_flutter` usa SQLite nativo en Android, iOS, Windows, Linux y macOS, y SQLite compilado a WebAssembly en el navegador. La capa de datos no cambia entre plataformas.
- **SQLite real y local.** No hay servidor, API REST ni MySQL, y no se usa `shared_preferences`. Los datos se quedan en cada instalación.
- **Tipos verificados.** Las tablas y consultas se escriben en Dart, así que los errores de columna o de tipo aparecen al compilar y no en tiempo de ejecución.
- **Consultas reactivas.** Drift puede devolver una consulta como `Stream` que vuelve a emitir resultados después de cada `INSERT`, `UPDATE` o `DELETE`, y la interfaz se actualiza sin volver a consultar manualmente.

Se descartó `sqflite` porque en web, Windows y Linux necesita paquetes adicionales (`sqflite_common_ffi`, `sqflite_common_ffi_web`), lo que duplica la configuración.

### Tabla `tareas`

| Columna | Tipo en Dart (Drift) | Tipo en SQLite | Restricciones |
|---|---|---|---|
| `id` | `int` | `INTEGER` | `PRIMARY KEY AUTOINCREMENT` |
| `titulo` | `String` | `TEXT` | `NOT NULL`, `CHECK(LENGTH(TRIM(titulo)) >= 1)` |
| `completada` | `bool` | `INTEGER` (0/1) | `NOT NULL`, `DEFAULT 0`, `CHECK(completada IN (0, 1))` |

- **Identificación:** cada registro se identifica por `id`, que asigna SQLite al insertar. La edición, el cambio de estado y la eliminación se hacen por `id`. Si el `id` ya no existe, la operación lanza `TareaNoEncontradaException`.
- **Booleano:** SQLite no tiene tipo booleano. Drift guarda `completada` como 0 o 1 y la convierte a `bool` automáticamente.
- **Validación en dos niveles:** en Dart, `validarTitulo()` aplica `trim()` y rechaza títulos vacíos con un mensaje para el usuario. En SQLite, el `CHECK` impide guardar un título vacío aunque se salte la validación de Dart.

## Pruebas automatizadas

```bash
flutter test
```

Todas las pruebas usan SQLite real, en memoria o en un archivo temporal, y no tocan la base de la app.

| Archivo | Qué cubre |
|---|---|
| `test/database_test.dart` | `validarTitulo` limpia espacios y rechaza títulos vacíos. INSERT y SELECT. Rechazo de títulos vacíos al insertar y al editar. El `CHECK` de SQLite como segunda barrera. UPDATE de título y de estado, y DELETE por `id`. Excepción con un `id` inexistente. El `Stream` vuelve a emitir tras cada escritura. **Persistencia:** escribe en un archivo, cierra la base, la vuelve a abrir y comprueba los cambios de P1 a P4. |
| `test/widget_test.dart` | La pantalla inicial se muestra. Un título vacío muestra el aviso y no se registra (P5). Agregar desde la interfaz guarda la tarea y la muestra en la lista. |

## Plataformas y resultados

| Plataforma | Estado |
|---|---|
| Linux (escritorio) | Probada |
| Web (Chrome) | Probada (compilación release servida en `127.0.0.1:8080`) |
| Android, iOS, Windows, macOS | Previstas, no probadas. El código no tiene nada específico de plataforma: `drift_flutter` resuelve la conexión en cada una. iOS y macOS requieren una Mac con Xcode, y Windows requiere Windows. |

| ID | Prueba | Linux | Web |
|---|---|---|---|
| P1 | Agregar tres tareas, cerrar y abrir | Correcta | Correcta |
| P2 | Marcar completada y reiniciar | Correcta | Correcta |
| P3 | Cambiar título y reiniciar | Correcta | Correcta |
| P4 | Eliminar y reiniciar | Correcta | Correcta |
| P5 | Agregar título vacío | Correcta | Correcta |
| P6 | Recargar y cerrar/abrir la pestaña (mismo origen y perfil) | No aplica | Correcta |
