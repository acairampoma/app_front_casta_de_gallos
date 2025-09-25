# 🔧 ESTRATEGIA BACKEND MARKETPLACE

## ANÁLISIS ACTUAL DEL SISTEMA

### ✅ ESTRUCTURA EXISTENTE IDENTIFICADA:

1. **Tabla gallos** ya tiene:
   - ✅ `foto_principal_url` - URL de la foto principal
   - ✅ `fotos_adicionales` - Campo JSONB para fotos adicionales
   - ✅ `url_foto_cloudinary` - URL optimizada de Cloudinary

2. **Tabla planes_catalogo** ya tiene:
   - ✅ `marketplace_publicaciones_max` - Límite de publicaciones por plan

3. **API de gallos** ya maneja:
   - ✅ Subida de 1 foto principal a Cloudinary
   - ✅ Campo `fotos_adicionales` (aunque no completamente implementado)

## ESTRATEGIA RECOMENDADA: CONSOLIDAR EN FOTOS_ADICIONALES

### 📋 DECISIÓN ARQUITECTÓNICA:

**Vamos a usar el campo `fotos_adicionales` JSONB para almacenar TODAS las fotos (incluyendo la principal).**

#### VENTAJAS:
1. ✅ **Consistencia**: Una sola fuente de verdad para todas las fotos
2. ✅ **Flexibilidad**: Fácil agregar metadatos (descripción, orden, etc.)
3. ✅ **Escalabilidad**: Fácil cambiar de 4 a N fotos en el futuro
4. ✅ **Marketplace listo**: Las fotos están disponibles automáticamente

#### ESTRUCTURA JSON PROPUESTA:
```json
[
  {
    "url": "https://res.cloudinary.com/xxx/gallo1_foto1.jpg",
    "url_optimized": "https://res.cloudinary.com/xxx/c_thumb,w_200/gallo1_foto1.jpg",
    "orden": 1,
    "es_principal": true,
    "descripcion": "Foto frontal",
    "cloudinary_public_id": "gallos/user123/gallo1_foto1",
    "uploaded_at": "2024-01-15T10:30:00Z"
  },
  {
    "url": "https://res.cloudinary.com/xxx/gallo1_foto2.jpg",
    "url_optimized": "https://res.cloudinary.com/xxx/c_thumb,w_200/gallo1_foto2.jpg",
    "orden": 2,
    "es_principal": false,
    "descripcion": "Foto lateral izquierdo",
    "cloudinary_public_id": "gallos/user123/gallo1_foto2",
    "uploaded_at": "2024-01-15T10:32:00Z"
  }
]
```

## PLAN DE IMPLEMENTACIÓN BACKEND

### FASE 1: ACTUALIZAR MODELOS

#### 1. ✅ Actualizar PlanCatalogo model - COMPLETADO
```python
# app/models/plan_catalogo.py - CAMPOS AGREGADOS AL MODELO:
class PlanCatalogo(Base):
    # ... campos existentes ...

    # CAMPOS AGREGADOS:
    duracion_semanas = Column(Integer, nullable=True)  # Semanas de streaming
    marketplace_publicaciones_max = Column(Integer, default=0)  # Límite marketplace

    def to_dict(self):
        return {
            'id': self.id,
            'codigo': self.codigo,
            'nombre': self.nombre,
            'precio': float(self.precio),
            'duracion_dias': self.duracion_dias,
            'duracion_semanas': self.duracion_semanas,  # ← STREAMING ACCESS
            'limites': {
                'gallos_maximo': self.gallos_maximo,
                'topes_por_gallo': self.topes_por_gallo,
                'peleas_por_gallo': self.peleas_por_gallo,
                'vacunas_por_gallo': self.vacunas_por_gallo,
                'marketplace_publicaciones_max': self.marketplace_publicaciones_max,  # ← MARKETPLACE
            },
            'caracteristicas': {
                'soporte_premium': self.soporte_premium,
                'respaldo_nube': self.respaldo_nube,
                'estadisticas_avanzadas': self.estadisticas_avanzadas,
                'videos_ilimitados': self.videos_ilimitados,
            },
            'destacado': self.destacado,
            'activo': self.activo,
        }
```

#### ✅ CONFIRMACIÓN DE ESTRUCTURA ACTUAL EN BD:
```sql
-- VERIFICADO EN BASE DE DATOS:
gratuito    | duracion_dias: 30  | duracion_semanas: null | marketplace_max: 0
basico      | duracion_dias: 7   | duracion_semanas: 1    | marketplace_max: 3
premium     | duracion_dias: 15  | duracion_semanas: 2    | marketplace_max: 5
profesional | duracion_dias: 30  | duracion_semanas: 4    | marketplace_max: 10
```

**INTERPRETACIÓN:**
- `duracion_dias`: Duración total de la suscripción
- `duracion_semanas`: Semanas de acceso a streaming/transmisiones
- `marketplace_publicaciones_max`: Límite de publicaciones en marketplace

#### 2. Crear modelo Marketplace
```python
# app/models/marketplace.py - NUEVO ARCHIVO
from sqlalchemy import Column, Integer, String, DECIMAL, DateTime, ForeignKey
from sqlalchemy.orm import relationship

class MarketplacePublicacion(Base):
    __tablename__ = "marketplace_publicaciones"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    gallo_id = Column(Integer, ForeignKey("gallos.id"), nullable=False)
    precio = Column(DECIMAL(10, 2), nullable=False)
    estado = Column(String(50), default="venta")
    fecha_publicacion = Column(DateTime, default=func.now())
    icono_ejemplo = Column(String(100), default="🐓")
    # ... campos de auditoría ...

    # Relaciones
    user = relationship("User", back_populates="marketplace_publicaciones")
    gallo = relationship("Gallo", back_populates="marketplace_publicacion")
```

### FASE 2: ACTUALIZAR API DE GALLOS

#### Modificar gallos_con_pedigri.py para manejar 4 fotos:

```python
@router.post("/crear-con-fotos")
async def crear_gallo_con_multiples_fotos(
    # ... parámetros existentes ...
    foto_1: Optional[UploadFile] = File(None),
    foto_2: Optional[UploadFile] = File(None),
    foto_3: Optional[UploadFile] = File(None),
    foto_4: Optional[UploadFile] = File(None),
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Crear gallo con hasta 4 fotos"""

    # 1. Crear gallo base (como antes)
    # 2. Subir fotos a Cloudinary
    fotos_json = []
    fotos = [foto_1, foto_2, foto_3, foto_4]

    for i, foto in enumerate(fotos):
        if foto:
            cloudinary_result = await CloudinaryService.upload_gallo_photo(
                file=foto,
                gallo_codigo=codigo_final,
                photo_type=f"foto_{i+1}"
            )

            fotos_json.append({
                "url": cloudinary_result['secure_url'],
                "url_optimized": cloudinary_result.get('urls', {}).get('optimized'),
                "orden": i + 1,
                "es_principal": i == 0,  # Primera foto es principal
                "descripcion": f"Foto {i+1}",
                "cloudinary_public_id": cloudinary_result.get('public_id'),
                "uploaded_at": datetime.now().isoformat()
            })

    # 3. Actualizar gallo con fotos_adicionales JSON
    update_fotos = text("""
        UPDATE gallos
        SET fotos_adicionales = :fotos_json,
            foto_principal_url = :foto_principal
        WHERE id = :id
    """)

    foto_principal = fotos_json[0]["url"] if fotos_json else None

    db.execute(update_fotos, {
        "fotos_json": json.dumps(fotos_json),
        "foto_principal": foto_principal,
        "id": gallo_id
    })
```

### FASE 3: CREAR API MARKETPLACE

#### Endpoints necesarios:
```python
# app/api/v1/marketplace.py - NUEVO ARCHIVO

@router.get("/publicaciones")
async def listar_publicaciones():
    """Listar todas las publicaciones activas"""
    pass

@router.post("/publicaciones")
async def crear_publicacion():
    """Crear nueva publicación desde un gallo existente"""
    pass

@router.get("/mis-publicaciones")
async def mis_publicaciones():
    """Listar publicaciones del usuario actual"""
    pass

@router.post("/publicaciones/{id}/favorito")
async def marcar_favorito():
    """Marcar/desmarcar publicación como favorita"""
    pass

@router.get("/limites")
async def verificar_limites():
    """Verificar límites de marketplace por plan"""
    pass
```

### FASE 4: ACTUALIZAR SUSCRIPCIONES API

Agregar marketplace_publicaciones_max a los endpoints de límites existentes.

## MIGRACIÓN GRADUAL

### PASO 1: Mantener compatibilidad
- Mantener `foto_principal_url` funcionando
- API devuelve ambos campos durante transición

### PASO 2: Migrar datos existentes
```sql
-- Script para migrar fotos existentes al formato JSON
UPDATE gallos
SET fotos_adicionales = CASE
    WHEN foto_principal_url IS NOT NULL THEN
        json_build_array(
            json_build_object(
                'url', foto_principal_url,
                'url_optimized', url_foto_cloudinary,
                'orden', 1,
                'es_principal', true,
                'descripcion', 'Foto principal',
                'uploaded_at', created_at::text
            )
        )::jsonb
    ELSE '[]'::jsonb
END
WHERE fotos_adicionales IS NULL OR fotos_adicionales = '[]'::jsonb;
```

### PASO 3: Frontend consume nuevo formato
- Frontend lee fotos desde `fotos_adicionales` JSON
- Fallback a `foto_principal_url` si JSON vacío

### PASO 4: Deprecar campos antiguos
- Solo después de confirmar que todo funciona
- Mantener `foto_principal_url` como cache de la foto principal

## TESTING STRATEGY

1. **Unit Tests**: Modelos y schemas
2. **Integration Tests**: APIs con uploads múltiples
3. **Load Tests**: Subida simultánea de 4 fotos
4. **Migration Tests**: Migración de datos existentes

---

**PRÓXIMOS PASOS:**
1. ✅ Actualizar modelo PlanCatalogo
2. ✅ Crear modelos Marketplace
3. ✅ Modificar API gallos para 4 fotos
4. ✅ Crear API marketplace
5. ✅ Actualizar API suscripciones