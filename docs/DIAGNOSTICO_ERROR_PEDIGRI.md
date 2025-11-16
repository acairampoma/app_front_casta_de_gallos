# 🔍 DIAGNÓSTICO: Error en Módulo Pedigrí

## 📅 Fecha: 2025-11-15

---

## 🎯 PROBLEMA REPORTADO

**Módulo:** Pedigrí (Gallos con Pedigrí)
**Síntoma:** Error al subir foto
**Módulos que SÍ funcionan:**
- ✅ Perfil (avatar)
- ✅ Peleas
- ✅ Topes
- ✅ Eventos/Peleas

---

## 🔬 ANÁLISIS DEL CÓDIGO FRONTEND

### Servicio Usado: `GalloServiceV2`

**Archivo:** `lib/services/gallo_service_v2.dart`

#### Endpoint que usa:
```dart
// Línea 27
POST /api/v1/gallos/con-pedigri
```

#### Cómo envía la foto:
```dart
// Línea 385 (móvil)
request.files.add(await http.MultipartFile.fromPath(
  'foto_principal',  // ← Nombre del campo
  foto.path,
  filename: 'gallo_mobile.jpg'
));

// Línea 354-377 (web - envía MÚLTIPLES campos)
'foto_principal'  // Campo principal
'file'            // Alternativo 1
'foto'            // Alternativo 2
'image'           // Alternativo 3
```

---

## 🔍 COMPARACIÓN CON MÓDULOS QUE FUNCIONAN

### 1. **Peleas** ✅
```dart
// Endpoint: POST /api/v1/peleas
// Campo: 'video'
request.files.add(await http.MultipartFile.fromPath(
  'video',
  video.path
));
```

### 2. **Topes** ✅
```dart
// Endpoint: POST /api/v1/topes
// Campo: 'video'
request.files.add(await http.MultipartFile.fromPath(
  'video',
  video.path
));
```

### 3. **Perfil (Avatar)** ✅
```dart
// Endpoint: POST /api/v1/profiles/avatar
// Campo: 'file'
request.files.add(await http.MultipartFile.fromPath(
  'file',
  imageFile.path
));
```

### 4. **Eventos/Peleas** ✅
```dart
// Endpoint: POST /api/v1/transmisiones/eventos/{id}/peleas
// Campo: 'video'
request.files.add(await http.MultipartFile.fromPath(
  'video',
  video.path
));
```

---

## 🎯 HIPÓTESIS DEL PROBLEMA

### Posible Causa 1: **Nombre del campo incorrecto**

**Frontend envía:**
```
foto_principal
```

**Backend espera (según tu migración):**
```
foto_principal  ← Debería ser correcto
```

**Verificar en backend:**
```python
# ¿Qué campo espera el endpoint?
@router.post("/gallos/con-pedigri")
async def crear_gallo_con_pedigri(
    foto_principal: UploadFile = File(None),  # ← ¿Este es el nombre?
    # O tal vez:
    # file: UploadFile = File(None),
    # foto: UploadFile = File(None),
):
```

---

### Posible Causa 2: **Endpoint no migrado**

**¿El endpoint `/api/v1/gallos/con-pedigri` ya usa Storage Manager?**

Verificar en backend:
```python
# ¿Este endpoint ya fue migrado?
# ¿O todavía usa ImageKit directo?
```

---

### Posible Causa 3: **Validación de archivo**

**Backend rechaza el archivo por:**
- Tamaño muy grande
- Formato no soportado
- Falta Content-Type

---

## 🔧 SOLUCIONES PROPUESTAS

### Solución 1: **Verificar nombre del campo en backend**

**Acción:** Revisar el endpoint en el backend:

```python
# En: galloapp_backend/app/api/v1/endpoints/gallos.py
# Buscar: @router.post("/con-pedigri")
# Verificar: ¿Qué nombre de campo espera?
```

**Si el backend espera `file` en lugar de `foto_principal`:**

```dart
// Cambiar en gallo_service_v2.dart línea 385
request.files.add(await http.MultipartFile.fromPath(
  'file',  // ← Cambiar de 'foto_principal' a 'file'
  foto.path,
  filename: 'gallo_mobile.jpg'
));
```

---

### Solución 2: **Agregar Content-Type explícito**

```dart
// En gallo_service_v2.dart línea 385
import 'package:http_parser/http_parser.dart';

request.files.add(await http.MultipartFile.fromPath(
  'foto_principal',
  foto.path,
  filename: 'gallo_mobile.jpg',
  contentType: MediaType('image', 'jpeg'),  // ← AGREGAR ESTO
));
```

---

### Solución 3: **Usar el mismo patrón que Perfil**

**Perfil funciona con campo `file`:**

```dart
// Cambiar línea 385 para usar 'file' como Perfil
request.files.add(await http.MultipartFile.fromPath(
  'file',  // ← Mismo nombre que Perfil
  foto.path,
  filename: 'gallo_mobile.jpg'
));
```

---

### Solución 4: **Verificar que el endpoint fue migrado**

**Si el endpoint NO fue migrado a Storage Manager:**

1. Migrar el endpoint en el backend
2. O temporalmente, hacer que acepte ambos nombres de campo

---

## 📋 PLAN DE ACCIÓN

### Paso 1: **Obtener el error exacto**

**Agregar logs en el frontend:**

```dart
// En gallo_service_v2.dart después de línea 59
print('📡 Response: ${response.statusCode}');
print('📡 Body: ${response.body}');
print('📡 Headers: ${response.headers}');
```

**Ejecutar y capturar:**
- Código de estado HTTP
- Mensaje de error del backend
- Headers de respuesta

---

### Paso 2: **Verificar el backend**

**Revisar el endpoint en el backend:**

```bash
# En galloapp_backend
grep -r "con-pedigri" app/api/v1/endpoints/
grep -r "foto_principal" app/api/v1/endpoints/
```

**Verificar:**
- ¿Qué nombre de campo espera?
- ¿Ya usa Storage Manager?
- ¿Tiene validaciones especiales?

---

### Paso 3: **Probar cambio rápido**

**Cambiar nombre del campo a `file`:**

```dart
// En lib/services/gallo_service_v2.dart línea 385
request.files.add(await http.MultipartFile.fromPath(
  'file',  // ← Cambiar aquí
  foto.path,
  filename: 'gallo.jpg'
));
```

**Recompilar y probar.**

---

### Paso 4: **Si persiste el error**

**Verificar en el backend que el endpoint acepta archivos:**

```python
# Debe tener algo como:
@router.post("/con-pedigri")
async def crear_gallo_con_pedigri(
    file: UploadFile = File(None),  # ← Debe aceptar archivo
    # ... otros campos
):
    if file:
        # Procesar archivo
        url = await storage_manager.upload_file(file)
```

---

## 🧪 PRUEBA DE DIAGNÓSTICO

### Comando para probar el endpoint directamente:

```bash
# Probar con curl
curl -X POST "https://gallerappback-production.up.railway.app/api/v1/gallos/con-pedigri" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "nombre=Gallo Test" \
  -F "codigo_identificacion=TEST001" \
  -F "file=@/path/to/image.jpg"
```

**Probar con diferentes nombres de campo:**
- `file`
- `foto_principal`
- `foto`
- `image`

**Ver cuál funciona.**

---

## 📊 TABLA DE COMPATIBILIDAD

| Módulo | Endpoint | Campo | Estado |
|--------|----------|-------|--------|
| Perfil | `/profiles/avatar` | `file` | ✅ Funciona |
| Peleas | `/peleas` | `video` | ✅ Funciona |
| Topes | `/topes` | `video` | ✅ Funciona |
| Eventos | `/transmisiones/eventos/{id}/peleas` | `video` | ✅ Funciona |
| **Pedigrí** | `/gallos/con-pedigri` | `foto_principal` | ❌ **ERROR** |

---

## 🎯 SOLUCIÓN MÁS PROBABLE

**Cambiar el nombre del campo de `foto_principal` a `file`:**

### Archivo: `lib/services/gallo_service_v2.dart`

**Línea 385 (móvil):**
```dart
// ANTES:
request.files.add(await http.MultipartFile.fromPath(
  'foto_principal',
  foto.path,
  filename: 'gallo_mobile.jpg'
));

// DESPUÉS:
request.files.add(await http.MultipartFile.fromPath(
  'file',  // ← CAMBIO AQUÍ
  foto.path,
  filename: 'gallo.jpg'
));
```

**Línea 354 (web):**
```dart
// ANTES:
request.files.add(http.MultipartFile.fromBytes(
  'foto_principal',
  bytes, 
  filename: foto.name ?? 'gallo_web.jpg',
));

// DESPUÉS:
request.files.add(http.MultipartFile.fromBytes(
  'file',  // ← CAMBIO AQUÍ
  bytes, 
  filename: foto.name ?? 'gallo.jpg',
));
```

**Eliminar los campos alternativos (líneas 361-377)** ya que solo confunden.

---

## 📝 CHECKLIST DE VERIFICACIÓN

- [ ] Obtener error exacto del backend
- [ ] Verificar nombre del campo que espera el backend
- [ ] Probar cambio de `foto_principal` a `file`
- [ ] Agregar Content-Type si es necesario
- [ ] Verificar que el endpoint fue migrado a Storage Manager
- [ ] Probar con curl para aislar el problema
- [ ] Revisar logs del backend

---

## 🚀 PRÓXIMOS PASOS

1. **Compartir el error exacto** que muestra el frontend
2. **Verificar el backend** - ¿Qué campo espera?
3. **Aplicar fix** según el diagnóstico
4. **Probar** y confirmar que funciona

---

**Documento creado:** 2025-11-15  
**Estado:** 🔍 Diagnóstico en progreso  
**Acción requerida:** Obtener error exacto y verificar backend
