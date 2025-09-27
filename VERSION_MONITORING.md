# 📱 Control de Versiones - Casta de Gallos

## 🚨 **ARCHIVOS CRÍTICOS A VERIFICAR**

### 1. **pubspec.yaml** ⭐ PRINCIPAL
```yaml
version: 1.6.0+901
```

### 2. **android/local.properties** ⚠️ PUEDE SOBRESCRIBIR
```properties
flutter.versionName=1.6.0
flutter.versionCode=901
```

### 3. **android/app/build.gradle** ℹ️ REFERENCIAS
```gradle
versionCode flutterVersionCode.toInteger()
versionName flutterVersionName
```

---

## 🔄 **HISTORIAL DE CÓDIGOS USADOS**

| Versión | Código | Estado | Fecha | Notas |
|---------|--------|--------|-------|-------|
| 1.1.2   | 850    | ❌ USADO | Anterior | Ya en Play Store |
| 1.6.0   | 860    | ❌ USADO | Anterior | Ya en Play Store |
| 1.6.0   | 900    | ❌ USADO | Anterior | Ya en Play Store |
| 1.6.0   | 901    | 🟡 PREPARANDO | Hoy | Marketplace fixes |

---

## ✅ **CHECKLIST PRE-RELEASE**

Antes de subir al Play Store:

### **1. Verificar Versiones**
- [ ] `pubspec.yaml` - version: 1.6.0+901
- [ ] `android/local.properties` - flutter.versionCode=901
- [ ] Código único (no usado antes)

### **2. Build y Test**
- [ ] `flutter clean`
- [ ] `flutter pub get`
- [ ] `flutter build appbundle --release`
- [ ] Test en dispositivo real
- [ ] WhatsApp funciona en móvil

### **3. Funcionalidades**
- [ ] Marketplace filtros funcionando
- [ ] Botones delete eliminan de BD
- [ ] Create publicación - foto preview
- [ ] WhatsApp en lista y detalle
- [ ] Tamaños de botones correctos

---

## 📋 **COMANDO RÁPIDO DE VERIFICACIÓN**

```bash
# Ver versiones actuales
echo "=== PUBSPEC.YAML ==="
grep "version:" pubspec.yaml

echo "=== LOCAL.PROPERTIES ==="
grep "flutter.version" android/local.properties

# Build release
flutter clean
flutter pub get
flutter build appbundle --release
```

---

## 🔧 **SOLUCIÓN A ERROR "Código ya usado"**

Si Play Store dice "El código de versión X ya se ha usado":

1. **Incrementar en pubspec.yaml**:
   ```yaml
   version: 1.6.0+861  # +1 al código
   ```

2. **Actualizar local.properties**:
   ```properties
   flutter.versionCode=861  # Mismo número
   ```

3. **Rebuild**:
   ```bash
   flutter clean
   flutter build appbundle --release
   ```

---

## 📁 **ARCHIVOS A REVISAR SIEMPRE**

1. ✅ `pubspec.yaml` - Versión principal
2. ⚠️ `android/local.properties` - Puede sobrescribir
3. 📋 `android/app/build.gradle` - Lee de los anteriores
4. 📋 `ios/Runner/Info.plist` - Lee de pubspec automáticamente

---

## 🎯 **PRÓXIMAS VERSIONES**

Para mantener orden:

- **v1.6.1**: Código 861
- **v1.6.2**: Código 862
- **v1.7.0**: Código 870
- **v1.8.0**: Código 880

---

*📅 Última actualización: ${new Date().toLocaleDateString()}*
*🔍 Monitoreo activo de versiones*