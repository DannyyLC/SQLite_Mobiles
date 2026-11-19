# Práctica - Gestor de tareas SQLite multiplataforma

**Código base deliberadamente incompleto.** Su objetivo es ofrecer una pantalla Flutter que se pueda ejecutar desde el primer momento; **NO implementa SQLite, CRUD ni persistencia**.

## Decisiones de diseño

### Tecnología de persistencia: Drift + drift_flutter

| Paquete | Versión | Uso |
|---|---|---|
| `drift` | ^2.35.4 | ORM sobre SQLite: define tablas en Dart y genera consultas con tipos verificados. |
| `drift_flutter` | ^0.3.1 | Abre la base de datos con la configuración adecuada para cada plataforma. |
| `drift_dev` (dev) | ^2.35.3 | Generador de código de Drift (clases de filas, companions, DAO). |
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
| `titulo` | `String` | `TEXT` | `NOT NULL`; longitud ≥ 1 después de quitar espacios |
| `completada` | `bool` | `INTEGER` (0/1) | `NOT NULL`, `DEFAULT 0` |

- **Identificación:** cada registro se identifica por `id`, que asigna SQLite al insertar. La edición, el cambio de estado y la eliminación se hacen por `id`.
- **Booleano:** SQLite no tiene tipo booleano. Drift guarda `completada` como 0 o 1 y la convierte a `bool` automáticamente.
- **Validación:** el título se limpia con `trim()` antes de guardarlo. Si queda vacío, la tarea no se registra.

## Preparación

1. Instala Flutter y comprueba `flutter doctor -v`.
2. Crea un proyecto nuevo **con este nombre**, para que coincida el `package:` usado en la prueba inicial:

   ```bash
   flutter create gestor_tareas_local
   cd gestor_tareas_local
   ```

3. Copia al proyecto generado las carpetas `lib/` y `test/` de esta base. No sobrescribas las carpetas `android/`, `ios/`, `web/`, `windows/`, `linux/` ni `macos/` generadas por Flutter.
4. Ejecuta:

   ```bash
   flutter pub get
   flutter analyze
   flutter test
   flutter run -d chrome
   ```

   Sustituye `chrome` por otro identificador de `flutter devices` si lo necesitas.

## Tarea por realizar

- Persistencia SQLite real en Android, iOS, Windows, Linux, macOS y web.
- Agregar, listar, editar título, marcar completada y eliminar tareas.
- Comprobar que la información persiste después de cerrar/abrir la app y, en web, después de recargar/cerrar la pestaña en un mismo origen y perfil.
- Investigar Drift + drift_flutter para compartir una sola base de código entre plataformas.
- Investigar cómo agregar `sqlite3.wasm` y `drift_worker.dart.js` en `web/` para que la base funcione en el navegador.
- Añadir pruebas significativas y documentar las plataformas verificadas.

Consulta la consigna PDF/LaTeX: contiene pasos de investigación, criterios, evidencias y rúbrica.

## Notas

- **No uses una base MySQL ni API REST:** esta práctica es de almacenamiento **local**.
- **No se acepta una lista solo en memoria** ni guardar la lista como JSON en `shared_preferences` en lugar de SQLite.
- Los datos de cada instalación/plataforma son propios; no se exige sincronización entre dispositivos.
- iOS y macOS requieren una Mac para compilarse/probarse; Windows requiere Windows para compilarse y Linux, Linux. La compatibilidad del código sí debe contemplar las seis plataformas.

### Referencias recomendadas

- https://drift.simonbinder.eu/
- https://drift.simonbinder.eu/platforms/web/
- https://pub.dev/packages/drift_flutter
- https://docs.flutter.dev/data-and-backend/persistence/sqlite
