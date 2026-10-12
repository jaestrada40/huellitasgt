# Checklist de publicación — Huellitas

## Cuentas (la persona)
- [ ] Apple Developer Program (99 USD/año): developer.apple.com/programs
- [ ] Google Play Console (25 USD, pago único): play.google.com/console

## Identidad y versión
- [ ] Identificador `com.huellitas.huellitas` confirmado (no se puede cambiar después de publicar)
- [ ] `version:` en pubspec.yaml y `kAppVersion` coinciden

## App Store (iOS)
- [ ] En Xcode: abrir `ios/Runner.xcworkspace`, elegir el equipo en Signing & Capabilities
- [ ] `flutter build ipa` y subir con Transporter/Xcode
- [ ] Ficha: nombre, descripción, capturas, URL de la política de privacidad
- [ ] Privacidad de la app: «Data Not Collected»
- [ ] `ITSAppUsesNonExemptEncryption` = false (ya en Info.plist)
- [ ] Clasificación por edad completada

## Google Play (Android)
- [ ] Crear llave de firma y configurar `key.properties` (guía: docs.flutter.dev/deployment/android)
- [ ] `flutter build appbundle` y subir a una pista de pruebas
- [ ] Formulario «Seguridad de los datos»: no se recopilan datos
- [ ] Clasificación de contenido y público objetivo (no dirigido a menores)
- [ ] Verificar el requisito vigente de pruebas cerradas para cuentas personales nuevas
      (Google ha exigido un mínimo de testers durante varios días antes de producción)

## Textos de la ficha
- [ ] No afirmar validez oficial, certificación ni reemplazo del veterinario
- [ ] Mencionar que los datos se guardan solo en el teléfono y que hay respaldo manual
