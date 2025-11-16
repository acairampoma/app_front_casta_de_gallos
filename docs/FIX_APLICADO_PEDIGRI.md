# ✅ FIX APLICADO: Error en Módulo Pedigrí

## 📅 Fecha: 2025-11-15

---

## 🎯 PROBLEMA IDENTIFICADO

**Módulo:** Pedigrí (Gallos con Pedigrí)
**Error:** No se podían subir fotos
**Causa:** Nombre de campo incorrecto en el request

---

## 🔧 SOLUCIÓN APLICADA

### Cambio en: `lib/services/gallo_service_v2.dart`

#### 1. Foto Principal (Móvil) - Línea 364-368

**ANTES:**
```dart
request.files.add(await http.MultipartFile.fromPath(
  'foto_principal',  // ❌ Campo incorrecto
  foto.path,
  filename: 'gallo_mobile.jpg'
));
```

**DESPUÉS:**
```dart
request.files.add(await http.MultipartFile.fromPath(
  'file',  // ✅ Campo correcto
  foto.path,
  filename: 'gallo.jpg'
));
```

---

#### 2. Foto Principal (Web) - Línea 354-358

**ANTES:**
```dart
// Enviaba 4 campos diferentes: foto_principal, file, foto, image
request.files.add(http.MultipartFile.fromBytes(
  'foto_principal',  // ❌ Campo incorrecto
  bytes, 
  filename: foto.name ?? 'gallo_web.jpg',
));
// + 3 campos alternativos más (confusión)
```

**DESPUÉS:**
```dart
// Solo envía 1 campo correcto
request.files.add(http.MultipartFile.fromBytes(
  'file',  // ✅ Campo correcto
  bytes, 
  filename: foto.name ?? 'gallo.jpg',
));
```

---

## 📊 COMPARACIÓN CON OTROS MÓDULOS

Ahora **Pedigrí** usa el mismo patrón que los módulos que funcionan:

| Módulo | Endpoint | Campo | Estado |
|--------|----------|-------|--------|
| Perfil | `/profiles/avatar` | `file` | ✅ Funciona |
| Peleas | `/peleas` | `video` | ✅ Funciona |
| Topes | `/topes` | `video` | ✅ Funciona |
| Eventos | `/transmisiones/eventos/{id}/peleas` | `video` | ✅ Funciona |
| **Pedigrí** | `/gallos/con-pedigri` | `file` | ✅ **CORREGIDO** |

---

## 🎯 POR QUÉ FUNCIONABA EN OTROS MÓDULOS

### Backend Migrado a Storage Manager:

El backend ahora usa un patrón estándar para todos los uploads:

```python
# Patrón estándar en todos los endpoints migrados
@router.post("/endpoint")
async def upload_something(
    file: UploadFile = File(None),  # ← Nombre estándar: 'file'
    # ... otros campos
):
    if file:
        url = await storage_manager.upload_file(file)
```

**Todos los endpoints migrados esperan el campo `file`:**
- ✅ `/profiles/avatar` → `file`
- ✅ `/peleas` → `video` (caso especial para videos)
- ✅ `/topes` → `video` (caso especial para videos)
- ✅ `/gallos/con-pedigri` → `file` (imágenes)

---

## 📝 FOTOS ADICIONALES

Las fotos adicionales usan nombres específicos:
- `foto_2` - Segunda foto
- `foto_3` - Tercera foto
- `foto_4` - Cuarta foto

**Esto está correcto** si el backend espera estos nombres específicos.

---

## 🧪 TESTING REQUERIDO

### Pruebas a realizar:

1. **Crear gallo con foto principal:**
   - [ ] Seleccionar 1 foto
   - [ ] Llenar datos del gallo
   - [ ] Guardar
   - [ ] Verificar que la foto se sube correctamente

2. **Crear gallo con múltiples fotos:**
   - [ ] Seleccionar 2-4 fotos
   - [ ] Llenar datos del gallo
   - [ ] Guardar
   - [ ] Verificar que todas las fotos se suben

3. **Editar gallo y cambiar foto:**
   - [ ] Abrir gallo existente
   - [ ] Cambiar foto principal
   - [ ] Guardar
   - [ ] Verificar que la nueva foto se muestra

4. **Verificar en web:**
   - [ ] Probar crear gallo desde navegador web
   - [ ] Verificar que funciona igual que en móvil

---

## 🔍 SI PERSISTE EL ERROR

### Verificar en logs del frontend:

```dart
// Los logs mostrarán:
print('📸 Foto agregada al request - Total archivos: ${request.files.length}');
print('📡 Response: ${response.statusCode} - ${response.body}');
```

### Verificar en backend:

```python
# Confirmar que el endpoint acepta 'file':
@router.post("/con-pedigri")
async def crear_gallo_con_pedigri(
    file: UploadFile = File(None),  # ← Debe ser 'file'
    # ...
):
```

---

## 📋 CHECKLIST DE VERIFICACIÓN

- [x] Cambiar `foto_principal` a `file` en móvil
- [x] Cambiar `foto_principal` a `file` en web
- [x] Eliminar campos alternativos confusos
- [x] Simplificar código
- [ ] **Compilar app**
- [ ] **Probar crear gallo con foto**
- [ ] **Verificar que funciona**

---

## 🚀 PRÓXIMOS PASOS

### 1. Compilar la app:
```bash
cd C:\Users\acairamp\Documents\proyecto\Curso\Flutter\gallos_app_new
flutter clean
flutter pub get
flutter build apk
```

### 2. Instalar en dispositivo:
```bash
flutter install
```

### 3. Probar el módulo de Pedigrí:
- Crear nuevo gallo con foto
- Verificar que se sube correctamente
- Verificar que se muestra en la lista

### 4. Si funciona:
- ✅ Confirmar que el fix fue exitoso
- ✅ Documentar que todos los módulos funcionan
- ✅ Continuar con desarrollo normal

### 5. Si NO funciona:
- Revisar logs del frontend
- Revisar logs del backend
- Verificar que el endpoint espera `file`
- Considerar otras causas (tamaño, formato, etc.)

---

## 💡 LECCIÓN APRENDIDA

### Consistencia en nombres de campos:

**Antes de la migración:**
- Cada módulo usaba nombres diferentes
- Pedigrí: `foto_principal`
- Perfil: `file`
- Peleas: `video`

**Después de la migración:**
- Patrón estándar: `file` para imágenes, `video` para videos
- Todos los endpoints migrados usan el mismo patrón
- Más fácil de mantener y debuggear

---

## 📞 SOPORTE

Si el error persiste después de este fix:

1. **Compartir logs del frontend:**
   - Código de estado HTTP
   - Mensaje de error del backend
   - Campos enviados en el request

2. **Verificar el backend:**
   - ¿El endpoint espera `file`?
   - ¿Ya fue migrado a Storage Manager?
   - ¿Tiene validaciones especiales?

3. **Probar con curl:**
   ```bash
   curl -X POST "https://gallerappback-production.up.railway.app/api/v1/gallos/con-pedigri" \
     -H "Authorization: Bearer YOUR_TOKEN" \
     -F "nombre=Test" \
     -F "codigo_identificacion=TEST001" \
     -F "file=@/path/to/image.jpg"
   ```

---

## ✅ RESUMEN

**Cambio realizado:** Nombre del campo de `foto_principal` → `file`

**Razón:** Alinear con el patrón estándar del backend migrado

**Impacto:** Solo módulo de Pedigrí (otros ya funcionaban)

**Acción requerida:** Compilar y probar

**Expectativa:** ✅ Debería funcionar ahora

---

**Documento creado:** 2025-11-15  
**Estado:** ✅ Fix Aplicado  
**Acción requerida:** Testing
