# Estado del proyecto — Huellitas

Última actualización: 11 de octubre de 2026

## Hecho
- App Flutter (iPhone y Android), 100 % local, sin cuentas: mascotas, eventos de salud con fotos, tratamientos
  recurrentes con avisos locales, historial con filtros y PDF, peso, carnet de vacunación, bloqueo con PIN/biometría,
  respaldo `.zip`.
- Diseño copiado del prototipo de Lovable (aprobado), con saludo «Hola, <nombre>».
- Ícono generado en Canva e integrado (`assets/icon/icon.png`).
- 128 pruebas automáticas en verde (también con zonas horarias de México y Nueva York) y `flutter analyze` limpio.
- Compila para el simulador de iOS.

## Pendiente
1. Correo de contacto en `docs/privacy-policy.md` (hoy hay un marcador) y alojarla en una URL pública.
2. Compilar y probar Android (falta instalar Android SDK).
3. Pruebas manuales en iPhone y Android reales (lista en el plan, Task 19, paso 6).
4. Cuentas de Apple Developer y Google Play; seguir `docs/release-checklist.md`.
5. Opcional: pedir el permiso de notificaciones automáticamente en el primer arranque.

## Cómo correrla con datos de ejemplo
`flutter run -d <simulador> --dart-define=SEED_DEMO=true`
(los datos de ejemplo solo existen con esa opción, nunca en la app publicada).
