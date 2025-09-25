# 🔄 ÉPICO: FLUJOS COMPLETOS DEL SISTEMA
## Integración de Nueva Estructura de BD y Priorización de Módulos

---

## 🎯 OBJETIVO GENERAL
Actualizar todo el sistema para usar la nueva estructura de la tabla `planes_catalogo` con los nuevos campos, eliminar datos hardcodeados, y establecer el orden correcto de prioridades: **Streaming → Marketplace → Gallos → Peleas → Topes → Vacunas**.

---

## 📊 NUEVA ESTRUCTURA DE BASE DE DATOS

### 🗂️ Tabla Actualizada: `planes_catalogo`
```sql
CREATE TABLE public.planes_catalogo (
    id serial4 NOT NULL,
    codigo varchar(20) NOT NULL,
    nombre varchar(100) NOT NULL,
    precio numeric(8, 2) DEFAULT 0.00 NULL,
    duracion_dias int4 DEFAULT 30 NULL,
    gallos_maximo int4 NOT NULL,
    topes_por_gallo int4 NOT NULL,
    peleas_por_gallo int4 NOT NULL,
    vacunas_por_gallo int4 NOT NULL,
    soporte_premium bool DEFAULT false NULL,
    respaldo_nube bool DEFAULT false NULL,
    estadisticas_avanzadas bool DEFAULT false NULL,
    videos_ilimitados bool DEFAULT false NULL,          -- 🆕 Para marketplace
    activo bool DEFAULT true NULL,
    orden int4 DEFAULT 0 NULL,
    destacado bool DEFAULT false NULL,
    created_at timestamp DEFAULT CURRENT_TIMESTAMP NULL,
    updated_at timestamp DEFAULT CURRENT_TIMESTAMP NULL,
    duracion_semanas int4 NULL,                         -- 🆕 Para streaming
    CONSTRAINT planes_catalogo_codigo_key UNIQUE (codigo),
    CONSTRAINT planes_catalogo_pkey PRIMARY KEY (id)
);
```

### 🔑 Campos Clave Agregados:
- **`duracion_semanas`**: Define periodo de acceso a streaming por plan
- **`videos_ilimitados`**: Define acceso completo a marketplace
- **`soporte_premium`**: Soporte prioritario 
- **`respaldo_nube`**: Backup automático en la nube
- **`estadisticas_avanzadas`**: Reportes y métricas avanzadas
- **`destacado`**: Para marcar plan recomendado

---

## 🏗️ FLUJO COMPLETO DE ACTUALIZACIÓN

### 📱 FASE 1: FRONTEND (Flutter) ✅ COMPLETADO

#### 🔧 Archivos Modificados:

1. **`lib/models/suscripcion_models.dart`** ✅
   - ✅ Agregados nuevos campos a `PlanCatalogo`
   - ✅ Actualizado `fromJson()` para leer desde BD
   - ✅ Agregado getter `duracionStreaming` dinámico
   - ✅ Removido hardcode de características

2. **`lib/features/planes/widgets/plan_card.dart`** ✅
   - ✅ Reordenadas características por prioridad:
     ```
     1. 📺 Streaming (destacado)
     2. 🏪 Marketplace (basado en videos_ilimitados)
     3. 🐓 Gallos
     4. 🥊 Peleas
     5. 🏋️ Entrenamientos (Topes)
     6. 💉 Vacunas
     7. 🎧 Soporte Premium (condicional)
     8. ☁️ Respaldo Nube (condicional)
     9. 📈 Estadísticas Avanzadas (condicional)
     ```
   - ✅ Método `_getAccesoStreaming()` lee desde BD
   - ✅ Características adicionales se muestran condicionalmente

3. **`lib/features/home/screens/home_screen.dart`** ✅
   - ✅ Módulos reordenados: Transmisiones → Marketplace → resto
   - ✅ Sistema de acceso a streaming ya implementado

### 🖥️ FASE 2: BACKEND (FastAPI) 🚧 PENDIENTE

#### 🔧 Archivos a Modificar:

1. **`app/routers/suscripciones.py`** 🚧
   ```python
   # ANTES (hardcoded):
   planes_data = [
       {"codigo": "basico", "duracion_streaming": "1 semana"},
       {"codigo": "premium", "duracion_streaming": "2 semanas"}
   ]
   
   # DESPUÉS (desde BD):
   @router.get("/planes-catalogo")
   async def obtener_planes_catalogo():
       """Obtener planes desde tabla planes_catalogo"""
       planes = await db.execute("""
           SELECT * FROM planes_catalogo 
           WHERE activo = true 
           ORDER BY orden ASC, precio ASC
       """)
       return planes
   ```

2. **`app/models/suscripciones.py`** 🚧
   - Agregar campos nuevos al modelo Pydantic
   - Actualizar validaciones para nuevos campos

3. **`app/services/suscripcion_service.py`** 🚧
   - Eliminar lógica hardcodeada de características
   - Leer todo desde BD

#### 🆕 Nuevos Endpoints Necesarios:

```python
# Gestión de planes desde admin
@router.post("/admin/planes")
async def crear_plan_catalogo(plan: PlanCatalogoCreate)

@router.put("/admin/planes/{plan_id}")
async def actualizar_plan_catalogo(plan_id: int, plan: PlanCatalogoUpdate)

@router.delete("/admin/planes/{plan_id}")
async def desactivar_plan_catalogo(plan_id: int)

# Validación de acceso a funcionalidades
@router.get("/validar-acceso-streaming")
async def validar_acceso_streaming(user_id: int)

@router.get("/validar-acceso-marketplace") 
async def validar_acceso_marketplace(user_id: int)
```

### 📊 FASE 3: BASE DE DATOS 🚧 PENDIENTE

#### 🗃️ Scripts de Migración Necesarios:

1. **Actualizar planes existentes con nuevos campos:**
```sql
-- Actualizar planes con datos de streaming
UPDATE planes_catalogo SET 
    duracion_semanas = CASE 
        WHEN codigo = 'basico' THEN 1
        WHEN codigo = 'premium' THEN 2  
        WHEN codigo = 'profesional' THEN 4
        ELSE 0
    END,
    videos_ilimitados = CASE
        WHEN codigo IN ('premium', 'profesional') THEN true
        ELSE false
    END,
    soporte_premium = CASE
        WHEN codigo = 'profesional' THEN true
        ELSE false
    END,
    estadisticas_avanzadas = CASE
        WHEN codigo IN ('premium', 'profesional') THEN true
        ELSE false
    END,
    respaldo_nube = CASE
        WHEN codigo = 'profesional' THEN true
        ELSE false
    END,
    destacado = CASE
        WHEN codigo = 'premium' THEN true
        ELSE false
    END;
```

2. **Establecer orden correcto:**
```sql
-- Definir orden de presentación
UPDATE planes_catalogo SET orden = CASE
    WHEN codigo = 'gratuito' THEN 1
    WHEN codigo = 'basico' THEN 2
    WHEN codigo = 'premium' THEN 3
    WHEN codigo = 'profesional' THEN 4
END;
```

---

## 🔄 FLUJOS DE USUARIO ACTUALIZADOS

### 👤 FLUJO USUARIO: Selección de Plan

1. **Usuario ve lista de planes** → `GET /api/v1/suscripciones/planes-catalogo`
2. **Planes se muestran ordenados** → Por campo `orden` de BD
3. **Características dinámicas** → Basadas en campos de BD
4. **Streaming destacado** → Primera característica siempre
5. **Marketplace visible** → Segunda característica

### 👨‍💼 FLUJO ADMIN: Gestión de Planes

1. **Admin accede a gestión de planes** → Pantalla admin
2. **Puede modificar características** → CRUD completo
3. **Actualiza duración streaming** → Campo `duracion_semanas`
4. **Configura acceso marketplace** → Campo `videos_ilimitados`
5. **Establece orden presentación** → Campo `orden`

### 🔐 FLUJO ACCESO: Validación de Funcionalidades

1. **Usuario intenta acceder a streaming**
   ```
   → Verificar suscripción activa
   → Calcular fecha_inicio + (duracion_semanas * 7 días)
   → Comparar con fecha actual
   → Permitir/Denegar acceso
   ```

2. **Usuario intenta acceder a marketplace**
   ```
   → Verificar suscripción activa
   → Validar campo videos_ilimitados = true
   → Permitir acceso completo / Limitado
   ```

---

## 📋 CHECKLIST DE IMPLEMENTACIÓN

### ✅ COMPLETADO:
- [x] Actualizar modelo `PlanCatalogo` con nuevos campos
- [x] Modificar `plan_card.dart` para orden correcto
- [x] Agregar getter `duracionStreaming` dinámico
- [x] Reordenar módulos en home screen
- [x] Implementar características condicionales

### 🚧 EN PROGRESO:
- [ ] **BACKEND**: Actualizar endpoints para leer desde BD
- [ ] **BACKEND**: Eliminar datos hardcodeados
- [ ] **BD**: Script migración de datos existentes

### 📅 PENDIENTE:
- [ ] **ADMIN**: Pantalla gestión de planes
- [ ] **TESTING**: Pruebas de validación de acceso
- [ ] **DOCS**: Actualizar documentación API
- [ ] **DEPLOY**: Migración en producción

---

## 🎨 NUEVA EXPERIENCIA DE USUARIO

### 🏠 Home Screen (Orden Actualizado):
```
┌─────────────────────────────────────┐
│  🏠 Casta de Gallos                 │
│  ┌─────────────┬─────────────────┐  │
│  │ 📺          │ 🏪              │  │
│  │ Transmisio. │ Marketplace     │  │ ← PRIORIDAD
│  └─────────────┴─────────────────┘  │
│  ┌─────────────┬─────────────────┐  │
│  │ 🐓 Pedigrí  │ 🥊 Peleas      │  │
│  └─────────────┴─────────────────┘  │
│  ┌─────────────┬─────────────────┐  │
│  │ 🏋️ Topes    │ 💉 Vacunas     │  │
│  └─────────────┴─────────────────┘  │
└─────────────────────────────────────┘
```

### 📋 Plan Cards (Características Dinámicas):
```
┌─────────────────────────────────────┐
│  💎 Plan Premium                    │
│  ┌─────────────────────────────────┐ │
│  │ 📺 Streaming: 2 semanas        │ │ ← DESTACADO
│  │ 🏪 Marketplace: Acceso completo │ │ ← DESTACADO  
│  │ 🐓 Gallos: 20                   │ │
│  │ 🥊 Peleas: 10 por gallo         │ │
│  │ 🏋️ Entrenamientos: 15 por gallo │ │
│  │ 💉 Vacunas: Ilimitadas          │ │
│  │ 📈 Estadísticas: Avanzadas      │ │ ← CONDICIONAL
│  └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

---

## 🔧 COMANDOS DE DESARROLLO

### 🏃‍♂️ Para Probar Cambios:
```bash
# Flutter - Hot reload
flutter run

# Verificar modelo actualizado
flutter analyze lib/models/suscripcion_models.dart

# Verificar plan cards
flutter analyze lib/features/planes/widgets/plan_card.dart
```

### 🗄️ Para BD (cuando sea necesario):
```sql
-- Verificar estructura actual
\d planes_catalogo

-- Ver datos actuales
SELECT codigo, nombre, duracion_semanas, videos_ilimitados, destacado 
FROM planes_catalogo 
ORDER BY orden;
```

---

## 🎯 RESULTADO ESPERADO

Al completar este épico tendremos:

✅ **Sistema 100% dinámico** - Sin datos hardcodeados
✅ **Priorización correcta** - Streaming y Marketplace primero
✅ **Características basadas en BD** - Totalmente configurables
✅ **Admin control total** - Gestión completa de planes
✅ **UX optimizada** - Orden lógico de funcionalidades
✅ **Escalabilidad** - Fácil agregar nuevas características

---

## 📞 PRÓXIMOS PASOS

1. **BACKEND**: Actualizar API para leer desde BD
2. **TESTING**: Verificar funcionamiento completo
3. **ADMIN**: Implementar panel de gestión de planes
4. **PRODUCCIÓN**: Migrar datos y desplegar cambios

---

*📝 Documento actualizado: $(date)*
*🚀 Estado: Frontend completado, Backend pendiente*