# 📊 Resumen: ImageKit y Sistema de Suscripciones

## 🎯 Conclusión Principal: CAMBIOS SOLO EN BACKEND

### ✅ LO QUE DESCUBRIMOS:

**El frontend Flutter NO usa ImageKit directamente**. Solo:
1. Sube archivos (imágenes/videos) al backend
2. Recibe URLs de vuelta (ej: `video_url`, `foto_url`)
3. Muestra esas URLs en la UI

**El backend es quien:**
- Recibe los archivos
- Los sube a ImageKit (o Cloudinary actualmente)
- Devuelve la URL al frontend
- Guarda la URL en la base de datos

### 🔄 MIGRACIÓN A IMAGEKIT = TRANSPARENTE PARA FLUTTER

**NO necesitas cambiar el código Flutter** porque:
- El frontend solo envía `File` al backend
- El frontend solo recibe `String` (URL) del backend
- El frontend solo muestra la URL en `Image.network()` o `VideoPlayer()`

**Solo cambias el BACKEND:**
```python
# ANTES (Cloudinary)
cloudinary.upload(file) → url

# DESPUÉS (ImageKit)
imagekit.upload(file) → url
```

---

## 📁 Módulos que Usan Imágenes/Videos

### 1. **Transmisiones** (Videos de Peleas)
**Archivos Flutter:**
- `gestion_peleas_evento_screen.dart` - Sube video al backend
- `videoteca_peleas_screen.dart` - Muestra `video_url`

**Flujo:**
```
Flutter → Backend → ImageKit/Cloudinary → Backend → BD
                                                    ↓
Flutter ← Backend ← BD (video_url)
```

**Campo en BD:** `peleas_evento.video_url`

---

### 2. **Pedigri** (Fotos de Gallos)
**Archivos Flutter:**
- `add_gallo_multistep_screen.dart` - Sube fotos
- `edit_gallo_multistep_screen.dart` - Edita fotos
- `pedigri_screen.dart` - Muestra fotos
- `genealogy_tree_screen.dart` - Muestra fotos en árbol

**Servicio actual:** `CloudinaryService` (lib/services/cloudinary_service.dart)

**Flujo:**
```
Flutter → CloudinaryService → Cloudinary → URL
                                            ↓
Flutter → Backend → BD (foto_url)
```

**Campo en BD:** `gallos.foto_url` (y posiblemente tabla `archivos`)

---

### 3. **Peleas** (Fotos/Videos)
**Archivos Flutter:**
- `formulario_pelea_screen.dart` - Sube archivos
- `peleas_screen_real.dart` - Muestra archivos

**Campo en BD:** `peleas.video_url`

---

### 4. **Topes** (Fotos/Videos)
**Archivos Flutter:**
- `formulario_tope_screen.dart` - Sube archivos
- `topes_screen_real.dart` - Muestra archivos

**Campo en BD:** `topes.video_url`

---

### 5. **Marketplace** (Fotos de Publicaciones)
**Archivos Flutter:**
- Buscar en `lib/features/` (no encontrado aún)

**Campo en BD:** `marketplace_publicaciones.*`

---

### 6. **Suscripciones** (Comprobantes de Pago)
**Archivos Flutter:**
- `suscripcion_screen.dart`
- `proceso_pago_screen.dart`

**Campo en BD:** `pagos_pendientes.*` o `suscripciones.payment_data`

---

## 🗄️ Análisis de Base de Datos

### Planes Disponibles:

| ID | Código | Nombre | Precio | Gallos | Topes/Gallo | Peleas/Gallo | Vacunas/Gallo | Marketplace |
|----|--------|--------|--------|--------|-------------|--------------|---------------|-------------|
| 1 | gratuito | Plan Gratuito | $0 | 5 | 2 | 2 | 2 | 0 |
| 2 | basico | basico | $30 | 50 | 2 | 2 | 4 | 3 |
| 3 | premium | premium | $50 | 100 | 3 | 3 | 4 | 5 |
| 4 | profesional | profesional | $70 | 150 | 4 | 4 | 4 | 10 |

### Usuarios Admin Identificados:

| ID | Email |
|----|-------|
| 25 | alancairampoma@gmail.com |
| 27 | jsalasc24@gmail.com |
| 123 | sistemas@jsinnovatech.com |
| 125 | castodegallos@jsinnovatech.com |

### Estado Actual de Suscripciones:
- **Total suscripciones:** 155
- **Mayoría:** Plan Gratuito
- **Algunos con planes pagos:**
  - ID 77: alancairampoma@gmail.com → Profesional ($100)
  - ID 76: jsalasc24@gmail.com → Profesional ($100)
  - ID 83: carrilloclorenzo49@gmail.com → Básico ($50)

---

## 🔧 Plan de Acción

### FASE 1: Migración a ImageKit (BACKEND ONLY)

#### Backend debe cambiar:

**Python/FastAPI (ejemplo):**
```python
# ANTES
from cloudinary import uploader

def upload_image(file):
    result = uploader.upload(file)
    return result['secure_url']

# DESPUÉS
from imagekitio import ImageKit

imagekit = ImageKit(
    private_key='your_private_key',
    public_key='your_public_key',
    url_endpoint='https://ik.imagekit.io/your_id'
)

def upload_image(file):
    result = imagekit.upload_file(
        file=file,
        file_name="image.jpg",
        options={
            "folder": "/gallos/",
            "is_private_file": False,
        }
    )
    return result.url
```

#### Endpoints afectados:
1. `POST /api/v1/transmisiones/eventos/{id}/peleas` - Upload video
2. `POST /api/gallos` - Upload foto gallo
3. `PUT /api/gallos/{id}` - Update foto gallo
4. `POST /api/peleas` - Upload video/foto pelea
5. `POST /api/topes` - Upload video/foto tope
6. `POST /api/marketplace/publicaciones` - Upload fotos
7. `POST /api/suscripciones/comprobante` - Upload comprobante

#### Migración de URLs existentes:
```sql
-- Script para migrar URLs de Cloudinary a ImageKit
-- (Ejecutar después de migrar archivos)

UPDATE gallos 
SET foto_url = REPLACE(foto_url, 'cloudinary.com', 'imagekit.io/your_id')
WHERE foto_url LIKE '%cloudinary.com%';

UPDATE peleas_evento 
SET video_url = REPLACE(video_url, 'cloudinary.com', 'imagekit.io/your_id')
WHERE video_url LIKE '%cloudinary.com%';

-- Repetir para otras tablas...
```

---

### FASE 2: Limpiar y Resetear Suscripciones

#### Script SQL para resetear suscripciones:

```sql
-- ============================================================================
-- SCRIPT: RESET DE SUSCRIPCIONES PARA TESTING
-- Fecha: 2025-11-15
-- Descripción: Elimina todas las suscripciones y crea nuevas para admins
-- ============================================================================

-- PASO 1: BACKUP (IMPORTANTE - Ejecutar primero)
-- ============================================================================
CREATE TABLE suscripciones_backup_20251115 AS 
SELECT * FROM suscripciones;

SELECT COUNT(*) as total_respaldadas FROM suscripciones_backup_20251115;
-- Verificar que se respaldaron todas (debería mostrar 155)


-- PASO 2: ELIMINAR TODAS LAS SUSCRIPCIONES
-- ============================================================================
DELETE FROM suscripciones;

SELECT COUNT(*) as total_restantes FROM suscripciones;
-- Verificar que sea 0


-- PASO 3: CREAR SUSCRIPCIONES DE PRUEBA PARA ADMINS
-- ============================================================================

-- 3.1: Admin con Plan GRATUITO (para testing de límites)
-- Usuario: sistemas@jsinnovatech.com (ID: 123)
INSERT INTO suscripciones (
    user_id,
    plan_type,
    plan_name,
    precio,
    status,
    fecha_inicio,
    fecha_fin,
    gallos_maximo,
    topes_por_gallo,
    peleas_por_gallo,
    vacunas_por_gallo,
    payment_method,
    created_at,
    updated_at
)
VALUES (
    123,
    'gratuito',
    'Plan Gratuito',
    0.00,
    'active',
    CURRENT_DATE,
    CURRENT_DATE + INTERVAL '30 days',
    5,
    2,
    2,
    2,
    'testing',
    NOW(),
    NOW()
);


-- 3.2: Admin con Plan BÁSICO (para testing de features básicas)
-- Usuario: castodegallos@jsinnovatech.com (ID: 125)
INSERT INTO suscripciones (
    user_id,
    plan_type,
    plan_name,
    precio,
    status,
    fecha_inicio,
    fecha_fin,
    gallos_maximo,
    topes_por_gallo,
    peleas_por_gallo,
    vacunas_por_gallo,
    payment_method,
    created_at,
    updated_at
)
VALUES (
    125,
    'basico',
    'basico',
    30.00,
    'active',
    CURRENT_DATE,
    CURRENT_DATE + INTERVAL '30 days',
    50,
    2,
    2,
    4,
    'testing',
    NOW(),
    NOW()
);


-- 3.3: Admin con Plan PREMIUM (para testing de features premium)
-- Usuario: alancairampoma@gmail.com (ID: 25)
INSERT INTO suscripciones (
    user_id,
    plan_type,
    plan_name,
    precio,
    status,
    fecha_inicio,
    fecha_fin,
    gallos_maximo,
    topes_por_gallo,
    peleas_por_gallo,
    vacunas_por_gallo,
    payment_method,
    created_at,
    updated_at
)
VALUES (
    25,
    'premium',
    'premium',
    50.00,
    'active',
    CURRENT_DATE,
    CURRENT_DATE + INTERVAL '30 days',
    100,
    3,
    3,
    4,
    'testing',
    NOW(),
    NOW()
);


-- 3.4: Admin con Plan PROFESIONAL (para testing completo)
-- Usuario: jsalasc24@gmail.com (ID: 27)
INSERT INTO suscripciones (
    user_id,
    plan_type,
    plan_name,
    precio,
    status,
    fecha_inicio,
    fecha_fin,
    gallos_maximo,
    topes_por_gallo,
    peleas_por_gallo,
    vacunas_por_gallo,
    payment_method,
    created_at,
    updated_at
)
VALUES (
    27,
    'profesional',
    'profesional',
    70.00,
    'active',
    CURRENT_DATE,
    CURRENT_DATE + INTERVAL '30 days',
    150,
    4,
    4,
    4,
    'testing',
    NOW(),
    NOW()
);


-- PASO 4: VERIFICAR SUSCRIPCIONES CREADAS
-- ============================================================================
SELECT 
    s.id,
    s.user_id,
    u.email,
    s.plan_type,
    s.plan_name,
    s.precio,
    s.status,
    s.fecha_inicio,
    s.fecha_fin,
    s.gallos_maximo,
    s.topes_por_gallo,
    s.peleas_por_gallo,
    s.vacunas_por_gallo
FROM suscripciones s
JOIN users u ON s.user_id = u.id
ORDER BY s.plan_type;

-- Debería mostrar 4 suscripciones (una por cada plan)


-- PASO 5: VERIFICAR CUOTAS DISPONIBLES POR USUARIO
-- ============================================================================

-- Contar gallos actuales por usuario admin
SELECT 
    u.id,
    u.email,
    s.plan_name,
    s.gallos_maximo,
    COUNT(g.id) as gallos_actuales,
    s.gallos_maximo - COUNT(g.id) as cuota_disponible
FROM users u
LEFT JOIN suscripciones s ON u.id = s.user_id
LEFT JOIN gallos g ON u.id = g.user_id
WHERE u.id IN (25, 27, 123, 125)
GROUP BY u.id, u.email, s.plan_name, s.gallos_maximo
ORDER BY u.id;


-- PASO 6: CREAR TABLA DE AUDITORÍA DE SUSCRIPCIONES (OPCIONAL)
-- ============================================================================
CREATE TABLE IF NOT EXISTS suscripcion_movimientos (
    id SERIAL PRIMARY KEY,
    suscripcion_id INT REFERENCES suscripciones(id) ON DELETE CASCADE,
    usuario_id INT REFERENCES users(id) ON DELETE CASCADE,
    tipo_movimiento VARCHAR(50) NOT NULL, -- 'creacion', 'renovacion', 'cancelacion', 'expiracion', 'upgrade', 'downgrade'
    plan_anterior_id INT REFERENCES planes_catalogo(id),
    plan_nuevo_id INT REFERENCES planes_catalogo(id),
    fecha_movimiento TIMESTAMP DEFAULT NOW(),
    detalles JSONB,
    ip_address VARCHAR(50),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Crear índices para mejor rendimiento
CREATE INDEX idx_suscripcion_movimientos_usuario ON suscripcion_movimientos(usuario_id);
CREATE INDEX idx_suscripcion_movimientos_fecha ON suscripcion_movimientos(fecha_movimiento);
CREATE INDEX idx_suscripcion_movimientos_tipo ON suscripcion_movimientos(tipo_movimiento);

-- Insertar movimientos iniciales
INSERT INTO suscripcion_movimientos (suscripcion_id, usuario_id, tipo_movimiento, plan_nuevo_id, detalles)
SELECT 
    s.id,
    s.user_id,
    'creacion',
    pc.id,
    jsonb_build_object(
        'plan', s.plan_name,
        'precio', s.precio,
        'metodo', 'testing_reset'
    )
FROM suscripciones s
JOIN planes_catalogo pc ON s.plan_type = pc.codigo;


-- ============================================================================
-- RESUMEN FINAL
-- ============================================================================
SELECT 
    '✅ SUSCRIPCIONES RESETEADAS' as status,
    COUNT(*) as total_suscripciones_activas
FROM suscripciones
WHERE status = 'active';

SELECT 
    '📊 DISTRIBUCIÓN POR PLAN' as info,
    plan_type,
    COUNT(*) as cantidad
FROM suscripciones
GROUP BY plan_type
ORDER BY plan_type;
```

---

## 🧪 Testing del Sistema de Suscripciones

### Casos de Prueba por Plan:

#### 1. Plan GRATUITO (sistemas@jsinnovatech.com)
**Límites:**
- ✅ Máximo 5 gallos
- ✅ 2 topes por gallo
- ✅ 2 peleas por gallo
- ✅ 2 vacunas por gallo
- ❌ Sin acceso a Marketplace

**Pruebas:**
1. Crear 5 gallos → ✅ OK
2. Intentar crear gallo #6 → ❌ Error: "Límite alcanzado. Mejora tu plan"
3. Crear 2 topes para gallo #1 → ✅ OK
4. Intentar crear tope #3 para gallo #1 → ❌ Error
5. Intentar acceder a Marketplace → ❌ Bloqueado

---

#### 2. Plan BÁSICO (castodegallos@jsinnovatech.com)
**Límites:**
- ✅ Máximo 50 gallos
- ✅ 2 topes por gallo
- ✅ 2 peleas por gallo
- ✅ 4 vacunas por gallo
- ✅ Máximo 3 publicaciones en Marketplace

**Pruebas:**
1. Crear 50 gallos → ✅ OK
2. Intentar crear gallo #51 → ❌ Error
3. Publicar 3 items en Marketplace → ✅ OK
4. Intentar publicar item #4 → ❌ Error

---

#### 3. Plan PREMIUM (alancairampoma@gmail.com)
**Límites:**
- ✅ Máximo 100 gallos
- ✅ 3 topes por gallo
- ✅ 3 peleas por gallo
- ✅ 4 vacunas por gallo
- ✅ Máximo 5 publicaciones en Marketplace
- ✅ Estadísticas avanzadas
- ✅ Respaldo en nube

**Pruebas:**
1. Crear 100 gallos → ✅ OK
2. Acceder a reportes avanzados → ✅ OK
3. Publicar 5 items en Marketplace → ✅ OK

---

#### 4. Plan PROFESIONAL (jsalasc24@gmail.com)
**Límites:**
- ✅ Máximo 150 gallos
- ✅ 4 topes por gallo
- ✅ 4 peleas por gallo
- ✅ 4 vacunas por gallo
- ✅ Máximo 10 publicaciones en Marketplace
- ✅ Videos ilimitados
- ✅ Soporte premium

**Pruebas:**
1. Crear 150 gallos → ✅ OK
2. Subir múltiples videos → ✅ OK
3. Publicar 10 items en Marketplace → ✅ OK

---

## 📝 Queries Útiles para Monitoreo

### Ver uso actual de cuotas:
```sql
SELECT 
    u.email,
    s.plan_name,
    s.gallos_maximo,
    COUNT(DISTINCT g.id) as gallos_actuales,
    s.gallos_maximo - COUNT(DISTINCT g.id) as gallos_disponibles,
    s.topes_por_gallo,
    s.peleas_por_gallo,
    s.vacunas_por_gallo
FROM users u
JOIN suscripciones s ON u.id = s.user_id
LEFT JOIN gallos g ON u.id = g.user_id
WHERE s.status = 'active'
GROUP BY u.id, u.email, s.plan_name, s.gallos_maximo, s.topes_por_gallo, s.peleas_por_gallo, s.vacunas_por_gallo
ORDER BY u.email;
```

### Ver topes por gallo:
```sql
SELECT 
    g.nombre as gallo,
    u.email,
    s.topes_por_gallo as limite,
    COUNT(t.id) as topes_actuales,
    s.topes_por_gallo - COUNT(t.id) as topes_disponibles
FROM gallos g
JOIN users u ON g.user_id = u.id
JOIN suscripciones s ON u.id = s.user_id
LEFT JOIN topes t ON g.id = t.gallo_id
WHERE s.status = 'active'
GROUP BY g.id, g.nombre, u.email, s.topes_por_gallo
HAVING COUNT(t.id) > 0
ORDER BY u.email, g.nombre;
```

### Ver peleas por gallo:
```sql
SELECT 
    g.nombre as gallo,
    u.email,
    s.peleas_por_gallo as limite,
    COUNT(p.id) as peleas_actuales,
    s.peleas_por_gallo - COUNT(p.id) as peleas_disponibles
FROM gallos g
JOIN users u ON g.user_id = u.id
JOIN suscripciones s ON u.id = s.user_id
LEFT JOIN peleas p ON g.id = p.gallo_id
WHERE s.status = 'active'
GROUP BY g.id, g.nombre, u.email, s.peleas_por_gallo
HAVING COUNT(p.id) > 0
ORDER BY u.email, g.nombre;
```

### Ver publicaciones en Marketplace:
```sql
SELECT 
    u.email,
    s.plan_name,
    pc.marketplace_publicaciones_max as limite,
    COUNT(mp.id) as publicaciones_actuales,
    pc.marketplace_publicaciones_max - COUNT(mp.id) as publicaciones_disponibles
FROM users u
JOIN suscripciones s ON u.id = s.user_id
JOIN planes_catalogo pc ON s.plan_type = pc.codigo
LEFT JOIN marketplace_publicaciones mp ON u.id = mp.user_id AND mp.estado = 'activa'
WHERE s.status = 'active'
GROUP BY u.id, u.email, s.plan_name, pc.marketplace_publicaciones_max
ORDER BY u.email;
```

---

## 🎯 Próximos Pasos

### 1. Backend - Migración a ImageKit
- [ ] Instalar SDK de ImageKit en backend
- [ ] Configurar credenciales (env variables)
- [ ] Cambiar lógica de upload en endpoints
- [ ] Migrar archivos existentes
- [ ] Actualizar URLs en BD
- [ ] Testing de upload/display

### 2. Backend - Control de Cuotas
- [ ] Crear middleware de validación de cuotas
- [ ] Implementar en endpoints de creación (gallos, topes, peleas, etc.)
- [ ] Crear endpoints de consulta de cuotas
- [ ] Implementar tabla de auditoría

### 3. Frontend - Mejoras de UI
- [ ] Crear widget de estado de suscripción
- [ ] Mostrar cuotas disponibles en cada módulo
- [ ] Implementar guards de acceso a Marketplace
- [ ] Crear diálogos de "Mejora tu plan"
- [ ] Tabla comparativa de planes

### 4. Testing
- [ ] Ejecutar script SQL de reset
- [ ] Probar límites de cada plan
- [ ] Verificar mensajes de error
- [ ] Probar upgrade/downgrade de planes

---

## 📚 Documentos Relacionados

- `PLAN_MEJORAS_MODULOS.md` - Plan completo de mejoras
- `EMAIL_VERIFICATION_TESTING.md` - Testing de verificación de email
- `ANDROID_16KB_BUILD.md` - Build para Android 15

---

**Última actualización:** 2025-11-15
**Estado:** 📋 Análisis Completo
