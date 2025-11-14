# 📱 Guía: Compilar APK/AAB con Soporte 16KB para Android 15+

## Problema
Google Play requiere que todas las apps soporten tamaños de página de memoria de 16 kB para Android 15+ a partir del 30 de mayo de 2026.

## Solución Implementada

### 1. Configuración en `gradle.properties`
```properties
# CRITICAL: Enable 16KB page size support for Android 15+
android.bundle.enableUncompressedNativeLibs=false
android.injected.build.abi=arm64-v8a,armeabi-v7a
```

### 2. Configuración en `build.gradle`
Ya está configurado con:
- `compileSdk = 36`
- `targetSdkVersion 36`
- NDK con `debugSymbolLevel 'SYMBOL_TABLE'`
- ABI filters para todas las arquitecturas

## Comandos para Compilar

### Opción 1: Android App Bundle (AAB) - Recomendado para Google Play
```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

El archivo se genera en:
```
build/app/outputs/bundle/release/app-release.aab
```

### Opción 2: APK Universal
```bash
flutter clean
flutter pub get
flutter build apk --release
```

El archivo se genera en:
```
build/app/outputs/flutter-apk/app-release.apk
```

### Opción 3: APK por Arquitectura (Más pequeños)
```bash
flutter build apk --split-per-abi --release
```

Genera múltiples APKs:
```
build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
build/app/outputs/flutter-apk/app-x86_64-release.apk
```

## Verificar Soporte 16KB

### Usando bundletool
```bash
# Descargar bundletool si no lo tienes
# https://github.com/google/bundletool/releases

# Verificar el AAB
java -jar bundletool.jar validate --bundle=build/app/outputs/bundle/release/app-release.aab

# Generar APKs desde el AAB
java -jar bundletool.jar build-apks --bundle=build/app/outputs/bundle/release/app-release.aab --output=app.apks --mode=universal

# Extraer el APK universal
unzip app.apks -d apks
```

### Usando Android Studio
1. Abre el proyecto en Android Studio
2. Ve a `Build` → `Analyze APK`
3. Selecciona el APK/AAB generado
4. Verifica que las librerías nativas estén alineadas a 16KB

## Subir a Google Play Console

### Paso 1: Generar AAB
```bash
flutter build appbundle --release
```

### Paso 2: Subir a Play Console
1. Ve a https://play.google.com/console
2. Selecciona tu app
3. Ve a `Producción` → `Crear nueva versión`
4. Sube el archivo `app-release.aab`
5. Completa los detalles de la versión
6. Revisa y publica

### Paso 3: Verificar en Play Console
Después de subir, Play Console te dirá si hay problemas con el soporte de 16KB.

## Troubleshooting

### Error: "No admite tamaños de página de memoria de 16 kB"

**Solución:**
1. Asegúrate de que `gradle.properties` tiene las configuraciones correctas
2. Limpia el proyecto: `flutter clean`
3. Elimina la carpeta `build/`: `rm -rf build/`
4. Vuelve a compilar: `flutter build appbundle --release`

### Error: "Native libraries not aligned"

**Solución:**
1. Verifica que `useLegacyPackaging = false` en `build.gradle`
2. Asegúrate de que `enableUncompressedNativeLibs=false` en `gradle.properties`
3. Recompila desde cero

### Error: "Multiple APKs with same version code"

**Solución:**
1. Incrementa el `versionCode` en `pubspec.yaml`
2. Vuelve a compilar

## Checklist Pre-Subida

- [ ] `flutter clean` ejecutado
- [ ] `flutter pub get` ejecutado
- [ ] `flutter build appbundle --release` exitoso
- [ ] AAB generado en `build/app/outputs/bundle/release/`
- [ ] Tamaño del AAB razonable (< 50MB)
- [ ] Versión incrementada en `pubspec.yaml`
- [ ] Changelog preparado para Play Console

## Información Adicional

### Arquitecturas Soportadas
- `arm64-v8a` - 64-bit ARM (mayoría de dispositivos modernos)
- `armeabi-v7a` - 32-bit ARM (dispositivos antiguos)
- `x86` - Emuladores y tablets x86
- `x86_64` - Emuladores 64-bit

### Tamaños Aproximados
- AAB: ~30-50 MB
- APK Universal: ~50-70 MB
- APK por arquitectura: ~20-30 MB cada uno

### Links Útiles
- [Documentación oficial de Google](https://developer.android.com/guide/practices/page-sizes)
- [Flutter deployment guide](https://docs.flutter.dev/deployment/android)
- [Bundletool releases](https://github.com/google/bundletool/releases)

---

**Última actualización:** 14/11/2025
**Versión:** 1.0
