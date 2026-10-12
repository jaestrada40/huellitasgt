# Huellitas — Diseño (spec)

Fecha: 2026-10-11
Estado: pendiente de revisión del usuario

## 1. Objetivo

App móvil para iPhone y Android que ayuda a una persona a **no olvidar** las fechas de salud
preventiva de sus mascotas (vacunas, desparasitación, antipulgas/garrapatas) y a **conservar el
historial** (enfermedades, consultas, recetas y carnets en foto).

Criterios de éxito:
- La persona recibe un aviso antes de cada vencimiento, sin abrir la app y sin internet.
- Puede ver de un vistazo qué está atrasado, qué viene pronto y qué está al día.
- Puede consultar todo el historial de una mascota y llevarlo en PDF al veterinario.
- No pierde sus datos al cambiar de teléfono si hizo un respaldo.

Se publicará en App Store y Google Play. Primer proyecto de la persona; se prioriza simplicidad.

## 2. Decisiones tomadas

| Tema | Decisión |
|---|---|
| Plataformas | iPhone y Android, una sola base de código: **Flutter** |
| Datos | **100% locales** en el teléfono (SQLite). Sin servidor, sin nube, sin costo de backend |
| Cuentas | **Sin login ni cuentas** |
| Seguridad | Bloqueo opcional con Face ID / huella / PIN |
| Respaldo | Manual: exportar e importar un archivo `.zip` |
| Compartir | Fuera de la primera versión. Solo PDF del historial y archivo de respaldo |
| Fotos y recetas | Se guardan en el teléfono, comprimidas |
| Diseño | Proyecto de Stitch «Huellitas Pet Health Tracker» (id `15285772595589445161`), sistema «Huellitas Health System» |
| Seguro / póliza | Fuera de la primera versión |

Supuesto a confirmar: el nombre de la app es **Huellitas** (viene del diseño de Stitch).

## 3. Alcance

Incluye:
1. Una o varias mascotas con perfil.
2. Registro de eventos de salud con fotos adjuntas.
3. Tratamientos recurrentes con próxima fecha calculada y recordatorio local.
4. Inicio con «Lo que toca pronto».
5. Historial con filtros y búsqueda; exportación a PDF.
6. Historial de peso.
7. Carnet de vacunación (resumen generado por el usuario, exportable a PDF).
8. Ajustes: bloqueo, recordatorios, exportar/importar respaldo.

No incluye (por ahora): login, sincronización, compartir en vivo, WhatsApp, póliza de seguro,
Apple Wallet, QR, certificación o sello «oficial».

## 4. Modelo de datos

Cinco tablas (SQLite vía `drift`). Todos los ids son UUID de texto.

**Pet**
`id, name, species (dog|cat|other), breed?, sex (male|female)?, neutered (bool), birthDate?,
microchip?, photoPath?, allergiesNotes?, vetName?, vetClinic?, vetPhone?, createdAt, archived`

**WeightEntry**
`id, petId, date, kg, note?`

**Treatment** — plan recurrente
`id, petId, type, name, intervalValue, intervalUnit (days|weeks|months|years), nextDueDate (día),
reminderDaysBefore, reminderEnabled, active`

**HealthEvent** — lo que ya ocurrió
`id, petId, treatmentId?, type, title, occurredAt (fecha y hora), product?, lot?, vetName?,
clinic?, notes?, weightKg?, createdAt`

**Attachment**
`id, eventId, relativePath, kind (image|pdf), label?`

Tipos de evento (`type`): `vaccine`, `deworming`, `fleaTick`, `illness`, `checkup`.
Solo los tres primeros pueden tener `Treatment` asociado.

Preferencias simples (no en la base): bloqueo activado, hora del aviso, días de aviso por
defecto, fecha del último respaldo.

### Reglas

- **Guardar evento con frecuencia**: busca un `Treatment` activo con la misma mascota, tipo y
  nombre (sin distinguir mayúsculas). Si existe lo actualiza; si no, lo crea. Luego
  `nextDueDate = fecha de aplicación + intervalo`.
- **Marcar como hecha**: crea un `HealthEvent` con fecha de hoy y fija
  `nextDueDate = hoy + intervalo` (se cuenta desde la fecha de aplicación, no desde el
  vencimiento original).
- **Sumar meses/años** ajusta fin de mes (31 ene + 1 mes = 28/29 feb).
- **Fechas de vencimiento** se guardan como día calendario, sin hora ni zona.
- **Estado** (calculado, no guardado): `atrasada` si `nextDueDate < hoy`; `vencePronto`
  («Vence en N días») si faltan 7 o menos; `próxima` si faltan más; `alDía` si no hay vencimiento
  pendiente.
- **«% al día»** = tratamientos activos no atrasados / tratamientos activos.
- Archivar una mascota la oculta pero conserva su historial.
- Borrar un evento borra sus adjuntos del disco.

## 5. Arquitectura

Capas, de afuera hacia adentro:

- **UI** (Flutter): pantallas y widgets. Navegación con `go_router`, estado con `riverpod`.
- **Dominio**: modelos y reglas puras (cálculo de fechas, estado, porcentaje). Sin dependencias
  de Flutter ni de la base; son lo más probado.
- **Repositorios** (interfaces): `PetRepository`, `EventRepository`, `TreatmentRepository`,
  `WeightRepository`, `BackupService`, `ReminderScheduler`. La UI solo conoce estas interfaces.
  Si algún día se agrega nube, se cambia la implementación sin tocar las pantallas.
- **Datos**: implementación local con `drift` + sistema de archivos.

Paquetes previstos: `drift`, `sqlite3_flutter_libs`, `flutter_riverpod`, `go_router`,
`flutter_local_notifications`, `timezone`, `flutter_timezone`, `image_picker`,
`flutter_image_compress`, `path_provider`, `archive`, `share_plus`, `file_picker`,
`local_auth`, `flutter_secure_storage`, `pdf`, `printing`, `shared_preferences`, `intl`.
(Versiones se fijan en el plan de implementación, verificando contra la documentación vigente.)

### Recordatorios

- Notificaciones **locales**; sin servidor ni WhatsApp.
- Se programa **solo el siguiente vencimiento** de cada `Treatment` (iOS permite 64 pendientes).
- Se reprograma todo al abrir la app, al editar un tratamiento y tras reiniciar el teléfono.
- Hora y anticipación configurables (por defecto 9:00 a. m. y 3 días antes).
- Android 13+: se solicita el permiso de notificaciones; se contempla el permiso de alarmas
  exactas según la versión.

### Respaldo

Archivo `huellitas-AAAA-MM-DD.zip` con `backup.json` (incluye `schemaVersion`) y la carpeta
`attachments/`. Exportar usa la hoja de compartir del sistema (Archivos, Drive, WhatsApp, etc.).
Importar **reemplaza todos los datos** tras confirmar; se extrae primero a una carpeta temporal y
solo se intercambia si todo es válido.

## 6. Pantallas

Pestañas: Inicio, Historial, Mascotas, Ajustes.

| Pantalla (Stitch) | Decisión |
|---|---|
| Bienvenida y Onboarding | Se queda. La diapositiva «Comparte con tu familia» cambia a «Respalda y lleva su carnet». Termina en «Agrega tu primera mascota» |
| Inicio | Se queda. Sin etiqueta «Sincronizado» |
| Agregar evento de salud | Se queda. Recordatorio solo por notificación (sin WhatsApp) |
| Historial médico | Se queda: filtros por tipo, búsqueda, Exportar PDF |
| Detalle de evento | Se queda |
| Perfil de mascota | Se queda. Sin póliza. Con acceso al peso |
| Mascotas / Nueva mascota | Nuevas, ya diseñadas |
| Control de peso | Nueva, ya diseñada. **Se elimina** el «Rango ideal» y las etiquetas «Óptimo/Ideal» |
| Carnet de vacunación | Resumen generado por el usuario + PDF. Sin sello, folio, QR, Wallet ni textos de validez oficial (SAGARPA/SENASICA, aerolíneas). El encabezado «CARNET MÉDICO DIGITAL» y la cédula profesional se tratan como datos que el usuario escribe |
| Ajustes | Nueva, ya diseñada |
| Iniciar sesión | **Eliminada** |
| Compartir con familia | **Eliminada** (primera versión) |

## 7. Manejo de errores

| Situación | Comportamiento |
|---|---|
| Notificaciones denegadas | La app funciona; aviso en Inicio y Ajustes con acceso a activar el permiso |
| Falla al guardar una foto (disco lleno) | Guarda el evento sin foto y avisa. Escrituras a la base en transacción |
| Respaldo dañado o de versión más nueva | Se rechaza con mensaje claro; no se toca ningún dato |
| Importar respaldo válido | Muestra «X mascotas, Y eventos», pide confirmación y reemplaza todo de forma atómica |
| Face ID no disponible | Cae a PIN guardado en almacén seguro |
| Sin respaldo en 30 días | Recordatorio suave en Inicio |

## 8. Pruebas

Automáticas:
1. Cálculo de próxima fecha (fin de mes, bisiestos, todas las unidades).
2. Estado de tratamientos y porcentaje «al día».
3. Marcar como hecha (crea evento, mueve la fecha desde hoy) y la regla de alta/actualización de
   `Treatment`.
4. Respaldo: exportar → importar devuelve los mismos datos; migraciones de la base conservan datos.
5. Programador de avisos con plugin simulado: nunca más de 64, solo el siguiente vencimiento,
   reprograma al abrir.
6. Pantallas: Inicio con atrasadas / sin pendientes / vacía; validación del formulario de evento.

Manuales en iPhone y Android reales: avisos con la app cerrada y tras reiniciar, Face ID/huella,
permiso de notificaciones en Android 13+, compartir el respaldo a Archivos y Google Drive,
importar en otro teléfono.

## 9. Publicación (fuera del código)

- Apple Developer Program (99 USD/año) y Google Play (25 USD, pago único).
- Política de privacidad (la app no recolecta ni envía datos; todo es local).
- Textos de la ficha de la tienda sin afirmar validez oficial ni veterinaria.
- La API key de Stitch usada en el MCP debe regenerarse (quedó expuesta en el chat).

## 10. Riesgos conocidos

- **Pérdida de datos** si el teléfono se pierde sin respaldo. Mitigación: recordatorio de respaldo.
- **Primer app y dos tiendas**: el mayor esfuerzo no es el código sino firmas, cuentas de
  desarrollador y revisión de las tiendas.
- **Deriva del diseño**: Stitch contiene pantallas descartadas (login, compartir); no usarlas.
