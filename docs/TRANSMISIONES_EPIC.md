# 📺 ÉPICO: MÓDULO TRANSMISIONES & VIDEOTECA

## 🎯 OBJETIVO GENERAL
Crear un sistema completo de transmisiones en vivo y videoteca de peleas, donde los administradores pueden gestionar eventos y sus peleas individuales, mientras los usuarios pueden ver transmisiones en vivo y acceder a una videoteca organizada.

---

## 📊 ANÁLISIS DE BASE DE DATOS

### 🗂️ Tabla Existente: `eventos_transmision`
```sql
CREATE TABLE public.eventos_transmision (
    id serial4 NOT NULL,
    coliseo_id int4 NULL,
    titulo varchar(255) NOT NULL,
    descripcion text NULL,
    fecha_evento timestamp NOT NULL,
    fecha_fin_evento timestamp NULL,
    url_transmision text NOT NULL,
    estado varchar(50) DEFAULT 'programado'::character varying NULL,
    tipo_evento varchar(100) DEFAULT 'local'::character varying NULL,
    precio_entrada numeric(10, 2) NULL,
    es_premium bool DEFAULT false NULL,
    thumbnail_url text NULL,
    admin_creador_id int4 NULL,
    created_at timestamp DEFAULT CURRENT_TIMESTAMP NULL,
    updated_at timestamp DEFAULT CURRENT_TIMESTAMP NULL
);
```

### 🆕 Nueva Tabla: `peleas_evento` (Videoteca)
```sql
CREATE TABLE public.peleas_evento (
    id serial4 NOT NULL,
    evento_id int4 NOT NULL,
    numero_pelea int4 NOT NULL,
    titulo_pelea varchar(255) NOT NULL,
    gallo_1_nombre varchar(100) NOT NULL,
    gallo_2_nombre varchar(100) NOT NULL,
    hora_inicio_estimada time NULL,
    hora_inicio_real timestamp NULL,
    hora_fin_real timestamp NULL,
    duracion_minutos int4 NULL,
    resultado varchar(100) NULL, -- 'gallo_1_ganador', 'gallo_2_ganador', 'empate', 'sin_resultado'
    video_url text NULL,
    thumbnail_pelea_url text NULL,
    descripcion_pelea text NULL,
    estado_video varchar(50) DEFAULT 'sin_video'::character varying NULL, -- 'sin_video', 'procesando', 'disponible'
    admin_editor_id int4 NULL,
    created_at timestamp DEFAULT CURRENT_TIMESTAMP NULL,
    updated_at timestamp DEFAULT CURRENT_TIMESTAMP NULL,
    CONSTRAINT peleas_evento_pkey PRIMARY KEY (id),
    CONSTRAINT peleas_evento_evento_id_fkey FOREIGN KEY (evento_id) REFERENCES public.eventos_transmision(id) ON DELETE CASCADE,
    CONSTRAINT peleas_evento_admin_editor_id_fkey FOREIGN KEY (admin_editor_id) REFERENCES public.users(id),
    CONSTRAINT unique_pelea_por_evento UNIQUE (evento_id, numero_pelea)
);

-- Índices para optimización
CREATE INDEX idx_peleas_evento ON public.peleas_evento USING btree (evento_id);
CREATE INDEX idx_peleas_estado_video ON public.peleas_evento USING btree (estado_video);
CREATE INDEX idx_peleas_fecha_real ON public.peleas_evento USING btree (hora_inicio_real);
```

---

## 🔄 FLUJO COMPLETO DEL SISTEMA

### 👨‍💼 FLUJO ADMINISTRADOR

#### 📅 Fase 1: Creación del Evento (YA EXISTE)
1. **Admin crea evento** en `/admin-transmisiones`
   - Define título, descripción, fecha, coliseo
   - Configura URL de transmisión (Kick, YouTube, etc.)
   - Establece precio de entrada y si es premium

#### 🥊 Fase 2: Gestión de Peleas del Evento (NUEVO)
1. **Admin accede a detalle del evento**
   - Ve lista de peleas programadas
   - Puede agregar nuevas peleas al evento

2. **Admin crea pelea individual**
   ```json
   {
     "numero_pelea": 1,
     "titulo_pelea": "Primera Pelea - Semifinal",
     "gallo_1_nombre": "El Campeón",
     "gallo_2_nombre": "Furia Roja",
     "hora_inicio_estimada": "20:30:00",
     "descripcion_pelea": "Semifinal del torneo regional"
   }
   ```

#### 📺 Fase 3: Durante la Transmisión EN VIVO
1. **Admin transmite en Kick/plataforma**
   - Los usuarios ven la transmisión completa
   - Todas las peleas se transmiten en secuencia

2. **Admin actualiza horarios reales** (opcional)
   - Marca hora real de inicio/fin de cada pelea
   - Ajusta resultados en tiempo real

#### 🎬 Fase 4: Post-Evento (Editor de Video)
1. **Editor descarga grabación completa**
2. **Editor corta cada pelea individual**
3. **Admin/Editor sube videos por pelea**
   - Actualiza `video_url` para cada pelea
   - Cambia estado a 'disponible'
   - Opcionalmente agrega thumbnail específico

### 👤 FLUJO USUARIO

#### 📺 Pestaña 1: TRANSMISIONES
- **Lista de eventos en vivo** y programados
- **Filtros**: Fecha, coliseo, tipo de evento
- **Acceso controlado** por suscripción (ya implementado)
- **Reproducción en WebView** de la transmisión completa

#### 🎥 Pestaña 2: VIDEOTECA (NUEVO)
- **Lista de eventos pasados** con videos disponibles
- **Filtros**: Fecha, coliseo, tipo de evento
- **Vista por evento**: Al seleccionar un evento, ve todas sus peleas
- **Reproducción individual** de cada pelea
- **Información detallada**: Gallos, resultado, duración

---

## 🏗️ ARQUITECTURA DE DESARROLLO

### 📱 FRONTEND (Flutter)

#### 🆕 Nuevos Archivos a Crear:
```
lib/
├── features/
│   └── transmisiones/
│       ├── models/
│       │   ├── pelea_evento_models.dart          # Nuevo
│       │   └── transmision_models.dart           # Actualizar
│       ├── screens/
│       │   ├── transmisiones_screen.dart         # Actualizar (agregar tabs)
│       │   ├── videoteca_tab.dart                # Nuevo
│       │   ├── evento_detalle_screen.dart        # Nuevo
│       │   └── pelea_video_screen.dart           # Nuevo
│       ├── widgets/
│       │   ├── evento_card.dart                  # Existente
│       │   ├── pelea_card.dart                   # Nuevo
│       │   └── video_player_widget.dart          # Nuevo
│       └── services/
│           ├── transmision_service.dart          # Existente
│           └── videoteca_service.dart            # Nuevo
└── features/
    └── admin/
        └── screens/
            ├── admin_transmisiones_screen.dart   # Existente
            ├── evento_peleas_admin_screen.dart   # Nuevo
            └── crear_pelea_screen.dart           # Nuevo
```

#### 📋 Modificaciones a Archivos Existentes:
1. **`transmisiones_screen.dart`**
   - Convertir a `TabBarView` con 2 pestañas
   - Pestaña 1: Transmisiones (código existente)
   - Pestaña 2: Videoteca (nuevo)

2. **`admin_transmisiones_screen.dart`**
   - Agregar botón "Gestionar Peleas" en cada evento
   - Navegación a pantalla de peleas del evento

### 🖥️ BACKEND (FastAPI)

#### 🆕 Nuevos Endpoints:
```python
# peleas_evento.py
@router.post("/eventos/{evento_id}/peleas")
async def crear_pelea_evento(evento_id: int, pelea: PeleaEventoCreate)

@router.get("/eventos/{evento_id}/peleas")
async def listar_peleas_evento(evento_id: int)

@router.put("/peleas/{pelea_id}")
async def actualizar_pelea(pelea_id: int, pelea: PeleaEventoUpdate)

@router.delete("/peleas/{pelea_id}")
async def eliminar_pelea(pelea_id: int)

@router.post("/peleas/{pelea_id}/subir-video")
async def subir_video_pelea(pelea_id: int, video: UploadFile)

# videoteca.py
@router.get("/videoteca/eventos")
async def listar_eventos_con_videos()

@router.get("/videoteca/eventos/{evento_id}")
async def obtener_evento_con_peleas(evento_id: int)

@router.get("/videoteca/peleas/recientes")
async def obtener_peleas_recientes(limit: int = 10)
```

---

## 🎨 DISEÑO DE INTERFAZ

### 📺 Pantalla Principal: TransmisionesScreen
```
┌─────────────────────────────────────┐
│  📺 Transmisiones                   │
│  ┌─────────────┬─────────────────┐  │
│  │ EN VIVO 🔴  │   VIDEOTECA 🎥  │  │
│  └─────────────┴─────────────────┘  │
│                                     │
│  [Contenido según pestaña activa]   │
│                                     │
└─────────────────────────────────────┘
```

### 🎥 Pestaña Videoteca
```
┌─────────────────────────────────────┐
│  🎥 Videoteca de Peleas             │
│  ┌─────────────────────────────────┐ │
│  │ 🔍 Filtros: [Fecha] [Coliseo]  │ │
│  └─────────────────────────────────┘ │
│                                     │
│  📅 Evento: Torneo Regional         │
│  🏟️ Coliseo San Juan               │
│  ┌─────────────────────────────────┐ │
│  │ 🥊 Pelea 1: El Campeón vs Furia│ │
│  │ ⏱️ 15:30 min  🏆 El Campeón    │ │
│  │ [▶️ Ver Video]                 │ │
│  └─────────────────────────────────┘ │
│                                     │
│  🥊 Pelea 2: Rayo vs Trueno        │
│  ⏱️ 12:45 min  🏆 Trueno           │
│  [▶️ Ver Video]                    │
│                                     │
└─────────────────────────────────────┘
```

### 👨‍💼 Panel Admin: Gestión de Peleas
```
┌─────────────────────────────────────┐
│  🥊 Peleas del Evento               │
│  📅 Torneo Regional - 15 Oct 2024  │
│                                     │
│  ┌─────────────────────────────────┐ │
│  │ ➕ Agregar Nueva Pelea          │ │
│  └─────────────────────────────────┘ │
│                                     │
│  🥊 Pelea 1: El Campeón vs Furia    │
│  ⏰ Estimada: 20:30                 │
│  ⏰ Real: 20:35 - 20:47            │
│  🎥 Estado: Video Disponible        │
│  [✏️ Editar] [🎥 Subir Video]      │
│                                     │
│  🥊 Pelea 2: Rayo vs Trueno        │
│  ⏰ Estimada: 21:00                 │
│  🎥 Estado: Sin Video               │
│  [✏️ Editar] [🎥 Subir Video]      │
│                                     │
└─────────────────────────────────────┘
```

---

## 📝 HISTORIAS DE USUARIO

### 👨‍💼 Como Administrador:

1. **US-01: Gestionar Peleas de Evento**
   - Como admin, quiero agregar peleas individuales a un evento
   - Para organizar mejor el contenido de la transmisión

2. **US-02: Subir Videos de Peleas**
   - Como admin, quiero subir el video de cada pelea individual
   - Para que los usuarios puedan verlas en la videoteca

3. **US-03: Actualizar Horarios Reales**
   - Como admin, quiero actualizar las horas reales de cada pelea
   - Para tener información precisa del evento

### 👤 Como Usuario:

4. **US-04: Ver Videoteca**
   - Como usuario, quiero acceder a una videoteca de peleas
   - Para ver peleas específicas de eventos pasados

5. **US-05: Filtrar Videos**
   - Como usuario, quiero filtrar videos por fecha y coliseo
   - Para encontrar fácilmente las peleas que me interesan

6. **US-06: Ver Información de Pelea**
   - Como usuario, quiero ver detalles de cada pelea (gallos, resultado, duración)
   - Para tener contexto antes de ver el video

---

## 🚀 PLAN DE IMPLEMENTACIÓN

### 📅 Sprint 1: Base de Datos y Backend
- [ ] Crear tabla `peleas_evento`
- [ ] Implementar endpoints de peleas
- [ ] Implementar endpoints de videoteca
- [ ] Pruebas de API

### 📅 Sprint 2: Frontend Admin
- [ ] Pantalla gestión de peleas por evento
- [ ] Formulario crear/editar pelea
- [ ] Subida de videos de peleas
- [ ] Integración con backend

### 📅 Sprint 3: Frontend Usuario
- [ ] Agregar pestaña Videoteca
- [ ] Lista de eventos con videos
- [ ] Reproductor de videos individual
- [ ] Filtros y búsqueda

### 📅 Sprint 4: Optimización y Pulido
- [ ] Mejoras de UX/UI
- [ ] Optimización de carga de videos
- [ ] Pruebas de usuario
- [ ] Ajustes finales

---

## 🏁 RESULTADO ESPERADO

Al finalizar este épico, tendremos:

✅ **Un sistema completo** de transmisiones y videoteca
✅ **Gestión granular** de peleas por evento
✅ **Videoteca organizada** por eventos y peleas
✅ **Herramientas admin** para gestión de contenido
✅ **Experiencia de usuario** mejorada para consumo de contenido
✅ **Base sólida** para futuras funcionalidades de video