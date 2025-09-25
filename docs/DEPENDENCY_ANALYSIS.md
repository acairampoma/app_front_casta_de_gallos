# 📊 ANÁLISIS DETALLADO DE DEPENDENCIAS - GALLOS APP
## Flutter 3.16.0 | Dart 3.2.0 | Codemagic CI/CD

---

## 🎯 CONTEXTO DEL PROYECTO
- **Flutter Version**: 3.16.0 (stable, Nov 2023)
- **Dart SDK**: 3.2.0
- **Codemagic Xcode**: 16.4 (latest)
- **Target Platforms**: iOS, Android, Web
- **Problemas Principales**: 
  - UnmodifiableUint8ListView error (win32)
  - Swift Launcher protocol error
  - Size parameter error (printing)

---

## 📦 ANÁLISIS INDIVIDUAL DE DEPENDENCIAS

### ✅ DEPENDENCIAS SEGURAS (Funcionan en todas las plataformas)

| Dependencia | Versión | iOS | Android | Web | Análisis |
|------------|---------|-----|---------|-----|----------|
| **provider** | ^6.1.1 | ✅ | ✅ | ✅ | State management puro Dart, sin código nativo |
| **go_router** | ^14.2.3 | ✅ | ✅ | ✅ | Navegación declarativa, puro Dart |
| **http** | ^1.1.2 | ✅ | ✅ | ✅ | Cliente HTTP puro Dart |
| **http_parser** | ^4.0.2 | ✅ | ✅ | ✅ | Parser HTTP, puro Dart |
| **intl** | 0.18.1 | ✅ | ✅ | ✅ | Internacionalización, puro Dart |
| **uuid** | ^4.2.1 | ✅ | ✅ | ✅ | Generador UUID, puro Dart |
| **cupertino_icons** | ^1.0.2 | ✅ | ✅ | ✅ | Iconos iOS style |
| **crypto** | ^3.0.3 | ✅ | ✅ | ✅ | Criptografía pura Dart |
| **fl_chart** | 0.66.2 | ✅ | ✅ | ✅ | Gráficos, puro Flutter |

### ⚠️ DEPENDENCIAS CON CÓDIGO NATIVO (Requieren configuración cuidadosa)

| Dependencia | Versión | iOS | Android | Web | Problema Específico |
|------------|---------|-----|---------|-----|---------------------|
| **image_picker** | ^1.0.7 | ⚠️ | ✅ | ✅ | iOS: Requiere permisos Info.plist |
| **cached_network_image** | ^3.3.1 | ✅ | ✅ | ✅ | Funciona pero usa sqlite en móvil |
| **shared_preferences** | ^2.2.2 | ✅ | ✅ | ✅ | Usa NSUserDefaults/SharedPreferences |
| **video_player** | ^2.8.1 | ⚠️ | ✅ | ✅ | iOS: AVPlayer puede dar problemas |

### 🔴 DEPENDENCIAS PROBLEMÁTICAS PARA iOS

| Dependencia | Versión | Problema | Solución |
|------------|---------|----------|----------|
| **printing** | ^5.12.0 | • Causa "size parameter" error<br>• Arrastra win32 5.2.0<br>• Incompatible con Flutter 3.16 | Usar versión 5.11.1 o remover |
| **pdf** | ^3.10.8 | • Depende de printing<br>• Arrastra win32 | Usar conditional imports |
| **permission_handler** | ^11.3.1 | • Arrastra win32<br>• Problemas App Store<br>• Requiere muchos permisos | Usar versión 10.4.5 |
| **url_launcher** | ^6.1.12 | • Swift Launcher protocol error<br>• url_launcher_ios 6.2.4 incompatible | Downgrade a 6.1.11 |
| **share_plus** | ^7.2.2 | • Warnings prototypes<br>• Conflictos con iOS 17 | Usar share_plus 6.3.4 |
| **path_provider** | ^2.1.1 | • Arrastra win32<br>• Conflictos con printing | Versión 2.1.0 |
| **universal_html** | ^2.2.4 | • Solo para web<br>• Causa conflictos en móvil | Conditional import |
| **device_info_plus** | ^9.1.2 | • No esencial<br>• Puede causar rechazos App Store | Opcional o versión 8.2.2 |

### 🔥 FIREBASE (Configuración especial requerida)

| Dependencia | Versión | Estado | Configuración Codemagic |
|------------|---------|--------|-------------------------|
| **firebase_core** | ^2.15.1 | ⚠️ | • Requiere GoogleService-Info.plist<br>• Configurar en pre-build script |
| **firebase_messaging** | ^14.6.7 | ⚠️ | • Requiere APNs certificates<br>• Background modes en Info.plist |
| **flutter_local_notifications** | ^15.1.0 | ⚠️ | • Conflictos con firebase_messaging<br>• Mejor usar una sola |

---

## 🔧 CONFIGURACIÓN ÓPTIMA PARA CODEMAGIC

### 1️⃣ **pubspec.yaml UNIFICADO** (Todas las plataformas)

```yaml
name: gallos_app_new
description: "Casta de Gallos - Multiplataforma"
version: 1.1.6+806

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  
  # Core - Seguras para todas las plataformas
  provider: ^6.1.1
  go_router: ^14.2.3
  http: ^1.1.2
  http_parser: ^4.0.2
  intl: ^0.18.1
  uuid: ^4.2.1
  cupertino_icons: ^1.0.2
  crypto: ^3.0.3
  fl_chart: ^0.66.2
  
  # UI y Media - Con precauciones
  image_picker: ^1.0.7
  cached_network_image: ^3.3.1
  shared_preferences: ^2.2.2
  
  # PDF y Compartir - VERSIONES ESPECÍFICAS
  printing: 5.11.1  # FIX: Versión sin "size parameter" error
  pdf: 3.10.7       # Compatible con printing 5.11.1
  url_launcher: 6.1.11  # FIX: Sin Swift Launcher error
  share_plus: 6.3.4     # Versión estable para iOS
  path_provider: 2.1.0  # Sin conflictos win32
  permission_handler: 10.4.5  # Versión estable
  
  # Firebase - Con conditional loading
  firebase_core: ^2.15.1
  firebase_messaging: ^14.6.7
  flutter_local_notifications: ^15.1.0
  
  # Opcional
  device_info_plus: ^8.2.2
  video_player: ^2.8.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

# CRÍTICO: Override para resolver conflictos
dependency_overrides:
  win32: 3.1.4  # Versión anterior sin UnmodifiableUint8ListView
  url_launcher_ios: 6.1.5  # Compatible con iOS 12.0+
  intl: 0.18.1
  fl_chart: 0.66.2
  collection: 1.18.0  # Evita conflictos con win32
```

### 2️⃣ **Codemagic workflow configuración**

```yaml
workflows:
  ios-android-web-build:
    name: Build iOS, Android & Web
    environment:
      flutter: 3.16.0  # Exacta versión local
      xcode: 15.4      # CAMBIAR de 16.4 a 15.4 para estabilidad
      cocoapods: 1.14.3
      node: 18
      
    scripts:
      - name: Set Flutter version
        script: |
          flutter --version
          flutter doctor -v
          
      - name: Install dependencies
        script: |
          flutter pub get
          
      - name: iOS specific setup
        script: |
          cd ios
          pod repo update
          pod install --repo-update
          cd ..
          
      - name: Fix iOS permissions
        script: |
          # Agregar permisos en Info.plist si no existen
          /usr/libexec/PlistBuddy -c "Add :NSCameraUsageDescription string 'Para tomar fotos de gallos'" ios/Runner/Info.plist || true
          /usr/libexec/PlistBuddy -c "Add :NSPhotoLibraryUsageDescription string 'Para seleccionar fotos de gallos'" ios/Runner/Info.plist || true
          
      - name: Build iOS
        script: |
          flutter build ios --release --no-codesign
          
      - name: Build Android
        script: |
          flutter build apk --release
          
      - name: Build Web
        script: |
          flutter build web --release
```

### 3️⃣ **Podfile iOS optimizado**

```ruby
platform :ios, '12.0'  # Mínimo iOS 12 para compatibilidad

# Resolver conflictos de versiones
$FirebaseSDKVersion = '10.12.0'

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    target.build_configurations.each do |config|
      # Forzar versión mínima iOS
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
      
      # Fix para M1/M2 Macs
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
      
      # Deshabilitar bitcode (deprecated en Xcode 14+)
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end
```

---

## 🚨 ERRORES ESPECÍFICOS Y SOLUCIONES

### Error 1: UnmodifiableUint8ListView
**Causa**: win32 5.2.0+ incompatible con Flutter 3.16
**Solución**: 
```yaml
dependency_overrides:
  win32: 3.1.4
```

### Error 2: Swift Launcher Protocol
**Causa**: url_launcher_ios versión incompatible
**Solución**:
```yaml
dependency_overrides:
  url_launcher_ios: 6.1.5
```

### Error 3: Size parameter (printing)
**Causa**: printing 5.12.0+ cambió API
**Solución**:
```yaml
printing: 5.11.1  # Versión específica
```

---

## 📱 ESTRATEGIA DE COMPILACIÓN RECOMENDADA

### OPCIÓN A: Configuración Conservadora (Máxima compatibilidad)
- Remover temporalmente: printing, pdf, firebase
- Compilar versión base funcional
- Agregar features gradualmente

### OPCIÓN B: Configuración con Conditional Imports
- Mantener todas las dependencias
- Usar conditional imports para PDF/Firebase
- Platform-specific implementations

### OPCIÓN C: Versiones Específicas (Recomendada)
- Usar las versiones exactas probadas arriba
- dependency_overrides para resolver conflictos
- Xcode 15.4 en vez de 16.4

---

## ✅ CHECKLIST PRE-COMPILACIÓN

- [ ] Flutter 3.16.0 exacto
- [ ] Xcode 15.4 (no 16.4)
- [ ] dependency_overrides agregados
- [ ] Info.plist con permisos
- [ ] GoogleService-Info.plist presente
- [ ] Pod install ejecutado
- [ ] Firebase inicializado condicionalmente