# 🛒 ÉPICO: MÓDULO MARKETPLACE

## OBJETIVO GENERAL
Crear un marketplace interno donde los usuarios pueden publicar y vender gallos, con control de límites por plan de suscripción y gestión completa de publicaciones.

---

## ANÁLISIS DE BASE DE DATOS

### Nueva Tabla Simplificada: `marketplace_publicaciones`
```sql
CREATE TABLE public.marketplace_publicaciones (
    id serial4 NOT NULL,
    gallo_id int4 NOT NULL, -- FK al gallo existente (tabla gallos)
    precio numeric(10, 2) NOT NULL,
    estado varchar(50) DEFAULT 'venta'::character varying NOT NULL, -- 'venta', 'vendido', 'pausado'
    fecha_publicacion timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    -- Campos de auditoría
    created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by int4 NOT NULL, -- ID del usuario que creó la publicación
    updated_by int4 NOT NULL, -- ID del usuario que actualizó la publicación
    CONSTRAINT marketplace_publicaciones_pkey PRIMARY KEY (id),
    CONSTRAINT marketplace_publicaciones_gallo_id_fkey FOREIGN KEY (gallo_id) REFERENCES public.gallos(id) ON DELETE CASCADE,
    CONSTRAINT marketplace_publicaciones_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE CASCADE,
    CONSTRAINT marketplace_publicaciones_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id) ON DELETE CASCADE,
    CONSTRAINT check_estado_valido CHECK (estado IN ('venta', 'vendido', 'pausado')),
    CONSTRAINT check_precio_positivo CHECK (precio > 0)
);

-- Índices para optimización
CREATE INDEX idx_marketplace_gallo ON public.marketplace_publicaciones USING btree (gallo_id);
CREATE INDEX idx_marketplace_estado ON public.marketplace_publicaciones USING btree (estado);
CREATE INDEX idx_marketplace_precio ON public.marketplace_publicaciones USING btree (precio);
CREATE INDEX idx_marketplace_fecha_pub ON public.marketplace_publicaciones USING btree (fecha_publicacion);
CREATE INDEX idx_marketplace_created_by ON public.marketplace_publicaciones USING btree (created_by);
```

### Modificación Tabla: `planes_catalogo`
```sql
-- Agregar nueva columna para límites de marketplace
ALTER TABLE public.planes_catalogo 
ADD COLUMN marketplace_publicaciones_max int4 DEFAULT 0;

-- Valores por defecto por plan
UPDATE public.planes_catalogo SET marketplace_publicaciones_max = 0 WHERE codigo = 'gratuito';
UPDATE public.planes_catalogo SET marketplace_publicaciones_max = 3 WHERE codigo = 'basico';
UPDATE public.planes_catalogo SET marketplace_publicaciones_max = 5 WHERE codigo = 'premium';
UPDATE public.planes_catalogo SET marketplace_publicaciones_max = 10 WHERE codigo = 'profesional';
```

### Nota sobre las fotos
Las fotos del marketplace se obtendrán directamente de la tabla `gallos`:
- `foto_principal_url`: Foto principal del gallo
- `fotos_adicionales`: Campo JSON que contiene hasta 4 URLs adicionales de fotos
- El campo JSON `url_foto_cloudinary` también está disponible como respaldo

---

## FLUJO COMPLETO DEL SISTEMA

...

---

## ARQUITECTURA DE DESARROLLO

### FRONTEND (Flutter)

#### Nuevos Archivos a Crear:
```
lib/
├── features/
│   └── marketplace/
│       ├── models/
│       │   ├── marketplace_models.dart           # Nuevo
│       │   └── publicacion_models.dart           # Nuevo
│       ├── screens/
│       │   ├── marketplace_screen.dart           # Nuevo (pantalla principal con tabs)
│       │   ├── explorar_tab.dart                 # Nuevo (pestaña 1)
│       │   ├── mis_publicaciones_tab.dart        # Nuevo (pestaña 2)
│       │   ├── detalle_publicacion_screen.dart   # Nuevo
│       │   ├── crear_publicacion_screen.dart     # Nuevo (con selector de gallo desde Pedigrí)
│       │   └── editar_publicacion_screen.dart    # Nuevo
│       ├── widgets/
│       │   ├── publicacion_card.dart             # Nuevo (incluye botón de favorito)
│       │   ├── galeria_fotos_widget.dart         # Nuevo
│       │   ├── filtros_marketplace_widget.dart   # Nuevo
│       │   ├── subir_fotos_widget.dart           # Nuevo
│       │   ├── seleccionar_gallo_dialog.dart     # Nuevo (lista/selector de gallos del Pedigrí)
│       │   ├── secciones_info_gallo_widget.dart  # Nuevo (pedigrí/peleas/topes/vacunas)
│       │   └── badges_info_gallo_widget.dart     # Nuevo (badges de "Con Pedigrí", "Con Vacunas", etc.)
│       └── services/
│           └── marketplace_service.dart          # Nuevo (incluye favoritos y métricas)
├── shared/
│   ├── widgets/
│   │   └── contacto_vendedor_widget.dart         # Nuevo
│   └── utils/
│       └── url_launcher_helper.dart              # Nuevo (WhatsApp, llamadas)
```

#### Modificaciones en Home:
```sql
lib/features/home/screens/home_screen.dart
- Reordenar módulos según nueva estructura:
  1. 📺 Transmisiones
  2. 🛒 Marketplace  # NUEVO
  3. 🐓 Pedigrí
  4. 🥊 Peleas
  5. 🏋️ Topes
  6. 💉 Vacunas
  7. 📊 Reportes
```

### BACKEND (FastAPI)

#### Nuevos Endpoints:
```python
# marketplace.py
@router.get("/marketplace/publicaciones")
async def listar_publicaciones_activas(
    skip: int = 0, 
    limit: int = 20,
    precio_min: float = None,
    precio_max: float = None,
    ubicacion: str = None,
    raza: str = None
)

@router.get("/marketplace/publicaciones/{publicacion_id}")
async def obtener_detalle_publicacion(publicacion_id: int)

@router.get("/marketplace/mis-publicaciones")
async def listar_mis_publicaciones(current_user: User = Depends(get_current_user))

@router.post("/marketplace/publicaciones")
async def crear_publicacion(
    publicacion: PublicacionCreate,
    current_user: User = Depends(get_current_user)
)

@router.put("/marketplace/publicaciones/{publicacion_id}")
async def actualizar_publicacion(
    publicacion_id: int,
    publicacion: PublicacionUpdate,
    current_user: User = Depends(get_current_user)
)

@router.delete("/marketplace/publicaciones/{publicacion_id}")
async def eliminar_publicacion(
    publicacion_id: int,
    current_user: User = Depends(get_current_user)
)

@router.put("/marketplace/publicaciones/{publicacion_id}/fotos-seleccion")
async def seleccionar_fotos_publicacion(
    publicacion_id: int,
    fotos: list[FotoSeleccionInput],  # [{pedigri_foto_id, orden_foto, es_principal}]
    current_user: User = Depends(get_current_user)
)

@router.patch("/marketplace/publicaciones/{publicacion_id}/estado")
async def cambiar_estado_publicacion(
    publicacion_id: int,
    nuevo_estado: str,  # 'venta', 'vendido', 'pausado'
    current_user: User = Depends(get_current_user)
)

# Verificación de límites
@router.get("/marketplace/limites")
async def verificar_limites_marketplace(current_user: User = Depends(get_current_user))

# Precarga desde un gallo existente (Pedigrí)
@router.get("/marketplace/preload-from-gallo")
async def preload_from_gallo(gallo_id: int, current_user: User = Depends(get_current_user))

# Crear publicación con referencia a gallo_id y flags de visibilidad
@router.post("/marketplace/publicaciones-from-gallo")
async def crear_publicacion_desde_gallo(
    gallo_id: int,
    data: PublicacionCreateFromGallo,  # incluye precio, estado inicial, flags mostrar_*
    current_user: User = Depends(get_current_user)
)

# Favoritos
@router.post("/marketplace/publicaciones/{publicacion_id}/favorito")
async def marcar_favorito(publicacion_id: int, current_user: User = Depends(get_current_user))

@router.delete("/marketplace/publicaciones/{publicacion_id}/favorito")
async def quitar_favorito(publicacion_id: int, current_user: User = Depends(get_current_user))

@router.get("/marketplace/favoritos")
async def listar_mis_favoritos(current_user: User = Depends(get_current_user))

# Métricas (vista/contacto)
@router.post("/marketplace/publicaciones/{publicacion_id}/eventos")
async def registrar_evento(
    publicacion_id: int,
    evento: EventoCreate  # { tipo: 'vista' | 'contacto', metadata?: any }
)
```

---

## DISEÑO DE INTERFAZ

...

### Crear Nueva Publicación
```
┌─────────────────────────────────────┐
│  ➕ Nueva Publicación               │
│  ←                                  │
│                                     │
│  🔗 Seleccionar Gallo desde Pedigrí │
│  ┌─────────────────────────────────┐ │
│  │ [🔍 Buscar gallo] [📄 Ver ficha] │ │
│  └─────────────────────────────────┘ │
│  🏷️ Gallo seleccionado: Shamo 2023  │
│  🧠 Auto-relleno: pedigrí/peleas/top│
│                                     │
│  📸 Seleccionar Fotos desde Pedigrí │
│  ┌─────┬─────┬─────┬─────┐         │
│  │ [1] │ [2] │ [3] │ [4] │         │
│  │     │     │     │     │         │
│  └─────┴─────┴─────┴─────┘         │
│  (Elegir hasta 4 fotos del gallo y marcar portada)
│                                     │
│  📝 Información Básica              │
│  ┌─────────────────────────────────┐ │
│  │ Precio: S/ [__________]         │ │
│  │ Título (opcional): [_________]  │ │
│  │ Descripción (opcional)          │ │
│  └─────────────────────────────────┘ │
│                                     │
│  👁️ Visibilidad de Información      │
│  ┌─────────────────────────────────┐ │
│  │ [✔] Mostrar Pedigrí             │ │
│  │ [✔] Mostrar Peleas              │ │
│  │ [✔] Mostrar Topes               │ │
│  │ [✔] Mostrar Vacunas             │ │
│  └─────────────────────────────────┘ │
│                                     │
│  🔎 Secciones informativas          │
│  ┌─────────────────────────────────┐ │
│  │ 🧬 Pedigrí (padre/madre)        │ │
│  │ 🥊 Peleas destacadas            │ │
│  │ 🏋️ Topes                        │ │
│  │ 💉 Vacunas                      │ │
│  └─────────────────────────────────┘ │
│                                     │
│  👤 Datos Vendedor (Auto-rellenado) │
│  ┌─────────────────────────────────┐ │
│  │ Galpón: Mi Galpón               │ │
│  │ Nombre: Juan Pérez              │ │
│  │ Teléfono: +51 987 654 321      │ │
│  │ Email: juan@email.com           │ │
│  └─────────────────────────────────┘ │
│                                     │
│  ┌─────────────────────────────────┐ │
│  │ 📝 Publicar Gallo               │ │
│  └─────────────────────────────────┘ │
│                                     │
└─────────────────────────────────────┘
```

---

## CONTROL DE LÍMITES POR PLAN

...

---

## HISTORIAS DE USUARIO

### Como Usuario:

1. **US-01: Explorar Marketplace**
   - Como usuario, quiero ver todos los gallos en venta
   - Para encontrar gallos que me interesen comprar

2. **US-02: Filtrar Publicaciones**
   - Como usuario, quiero filtrar por precio, ubicación y raza
   - Para encontrar gallos específicos que busco

...

6. **US-06: Gestionar Mis Publicaciones**
   - Como usuario, quiero editar, pausar o eliminar mis publicaciones
   - Para mantener mi inventario actualizado

7. **US-07: Ver Límites de Plan**
   - Como usuario, quiero saber cuántas publicaciones puedo hacer
   - Para gestionar mi suscripción adecuadamente
   
8. **US-08: Publicar desde Pedigrí**
      - Como vendedor, quiero seleccionar uno de mis gallos del módulo Pedigrí para publicar
      - Para reutilizar toda la información registrada (pedigrí, peleas, topes y vacunas)

9. **US-09: Controlar visibilidad de información**
      - Como vendedor, quiero decidir qué información histórica se muestra (pedigrí/peleas/topes/vacunas)
      - Para proteger mi estrategia y mostrar solo lo necesario al comprador

10. **US-10: Marcar Favoritos**
       - Como comprador, quiero marcar publicaciones como favoritos
       - Para guardarlas y compararlas luego

11. **US-11: Ver estadísticas de interés**
       - Como vendedor, quiero ver cuántas vistas y contactos tiene mi publicación
       - Para medir el interés y ajustar mi estrategia de venta

---

## PLAN DE IMPLEMENTACIÓN

### Sprint 1: Base de Datos y Backend
- [ ] Crear tabla `marketplace_publicaciones` (con `gallo_id`, flags `mostrar_*`, y contadores)
- [ ] Modificar tabla `planes_catalogo`
- [ ] Crear tablas `marketplace_favoritos` y `marketplace_eventos`
- [ ] Implementar endpoints básicos CRUD + preload-from-gallo
- [ ] Sistema de límites por plan (al crear y al cambiar estado)
- [ ] Pruebas de API

### Sprint 2: Frontend - Explorar
- [ ] Pantalla principal con tabs
- [ ] Pestaña "Explorar" marketplace
- [ ] Lista de publicaciones con filtros y botón de favorito
- [ ] Detalle de publicación (galería + badges de información)
- [ ] Widget de contacto (WhatsApp/llamada) + registro de evento "contacto"

### Sprint 3: Frontend - Mis Publicaciones
- [ ] Pestaña "Mis Publicaciones"
- [ ] Crear nueva publicación seleccionando gallo desde Pedigrí
- [ ] Flags de visibilidad (pedigrí/peleas/topes/vacunas)
- [ ] Seleccionar/reordenar hasta 4 fotos desde Pedigrí (sin subir)
- [ ] Editar publicaciones existentes
- [ ] Cambiar estados (venta/vendido/pausado)

### Sprint 4: Integración y Pulido
- [ ] Integrar con sistema de planes
- [ ] Validaciones de límites en tiempo real
- [ ] Reordenar módulos en home
- [ ] Sección "Favoritos" del usuario (GET favoritos)
- [ ] Métricas de vistas/contactos en "Mis Publicaciones"
- [ ] Mejoras de UX/UI
- [ ] Pruebas de usuario

---

## CONSIDERACIONES TÉCNICAS
- **Almacenamiento**: Cloudinary
- **Límite por foto**: 5MB máximo
- **Formatos**: JPG, PNG, WebP
- **Optimización**: Compresión automática
- **Miniaturas**: Generación automática para lista

### 📱 Contacto con Vendedores
- **WhatsApp**: url_launcher con link directo
- **Llamadas**: url_launcher con tel:
- **Email**: url_launcher con mailto:
- **Validación**: Verificar aplicaciones instaladas

### 🔍 Búsqueda y Filtros
- **Filtros básicos**: Precio, ubicación, raza
- **Ordenamiento**: Precio, fecha, relevancia
- **Búsqueda**: Por título y descripción
- **Paginación**: 20 publicaciones por página

### 🛡️ Seguridad
- **Autenticación**: JWT token obligatorio
- **Autorización**: Solo owner puede editar/eliminar
- **Validación**: Límites por plan en backend
- **Moderación**: Flag para reportar publicaciones

---

## 📊 MÉTRICAS DE ÉXITO

1. **Adopción**
   - Número de usuarios que publican
   - Publicaciones creadas por mes
   - Tiempo promedio hasta primera publicación

2. **Engagement**
   - Publicaciones vistas por día
   - Contactos generados por publicación
   - Tasa de conversión vista → contacto

3. **Monetización**
   - Upgrades de plan motivados por límites
   - Retención de usuarios con publicaciones activas

4. **Calidad**
   - Publicaciones con 4 fotos vs menos fotos
   - Tiempo promedio de publicación activa
   - Tasa de publicaciones marcadas como vendidas

---

## 🏁 RESULTADO ESPERADO

Al finalizar este épico, tendremos:

✅ **Marketplace funcional** con exploración y gestión
✅ **Sistema de límites** integrado con planes de suscripción
✅ **Herramientas de contacto** para facilitar ventas
✅ **Gestión completa** de publicaciones por usuario
✅ **Interfaz intuitiva** para comprar y vender gallos
✅ **Nuevo módulo principal** en el home de la app
✅ **Incentivo adicional** para upgrades de suscripción