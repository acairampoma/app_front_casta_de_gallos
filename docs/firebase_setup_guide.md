# 🔥 GUÍA CONFIGURACIÓN FIREBASE - ALAN CAIRAMPOMA

## 🚀 PASO A PASO PARA CONFIGURAR FIREBASE

### 1️⃣ **CREAR PROYECTO FIREBASE:**
1. Ve a: https://console.firebase.google.com
2. Inicia sesión con tu Gmail: **alancairampoma@gmail.com**
3. Clic en "Crear un proyecto"
4. Nombre del proyecto: **galloapp-notifications**
5. Acepta términos y crea el proyecto

### 2️⃣ **AGREGAR APP ANDROID:**
1. En el dashboard, clic en el ícono de Android
2. **Package name:** `com.galloapp.gallos_app_new`
3. **App nickname:** `GalloApp`
4. **SHA-1:** (lo generamos después)
5. Descargar `google-services.json`

### 3️⃣ **AGREGAR APP iOS:**
1. Clic en el ícono de iOS
2. **Bundle ID:** `com.galloapp.gallosAppNew`
3. **App nickname:** `GalloApp iOS`
4. Descargar `GoogleService-Info.plist`

### 4️⃣ **ACTIVAR CLOUD MESSAGING:**
1. En el dashboard de Firebase
2. Ir a "Messaging" en el menú izquierdo
3. Clic en "Comenzar"
4. ¡Ya está activado y listo!

## 📱 **UBICACIÓN DE ARCHIVOS:**

### Android:
```
android/app/google-services.json
```

### iOS:
```
ios/Runner/GoogleService-Info.plist
```

## 🔧 **COMANDOS PARA INSTALAR:**

```bash
# 1. Instalar Flutter CLI para Firebase
dart pub global activate flutterfire_cli

# 2. Instalar dependencias
flutter pub get

# 3. Configurar Firebase automáticamente
flutterfire configure

# 4. Elegir el proyecto que creaste: galloapp-notifications
```

## 🎯 **INFORMACIÓN IMPORTANTE:**

- **Email:** alancairampoma@gmail.com
- **Proyecto:** galloapp-notifications
- **Es gratis:** ✅ Sí, sin límites para uso normal
- **Package Android:** com.galloapp.gallos_app_new
- **Bundle iOS:** com.galloapp.gallosAppNew

## 🔔 **TIPOS DE NOTIFICACIONES QUE VAMOS A IMPLEMENTAR:**

1. **Admin recibe notificación cuando:**
   - Usuario se suscribe a un plan
   - Usuario completa pago
   - Usuario actualiza perfil

2. **Usuario recibe notificación cuando:**
   - Su suscripción está por vencer
   - Hay actualizaciones de la app
   - Recordatorios importantes

## 📝 **PRÓXIMOS PASOS:**
1. Ejecutar los comandos de arriba
2. Crear el servicio de notificaciones
3. Integrar con el backend
4. Probar notificaciones