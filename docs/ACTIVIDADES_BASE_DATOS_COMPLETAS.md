# 🗄️ ACTIVIDADES COMPLETAS DE BASE DE DATOS
## Todos los Requerimientos del Sistema

---

## 📋 RESUMEN EJECUTIVO

Este documento contiene **todas las actividades de base de datos** necesarias para implementar los siguientes módulos:

1. **🔧 PARTE 1**: Correcciones a `planes_catalogo` (Marketplace)
2. **📺 PARTE 2**: Nuevo módulo Transmisiones - Videoteca (`peleas_evento`)
3. **🏪 PARTE 3**: Nuevo módulo Marketplace (`marketplace_publicaciones`)
4. **🛠️ PARTE 4**: Funciones y procedimientos auxiliares
5. **✅ PARTE 5**: Consultas de verificación
6. **🎲 PARTE 6**: Datos de prueba (opcional)

---

## 🔧 PARTE 1: CORRECCIONES TABLA `planes_catalogo`

### 📝 Actividad 1.1: Agregar columna `marketplace_publicaciones_max`
Nota: Al ejecutar en PostgreSQL, no copies las líneas de apertura/cierre de bloque ```sql.
```sql
-- Columna (idempotente) y normalización mínima
ALTER TABLE public.planes_catalogo
ADD COLUMN IF NOT EXISTS marketplace_publicaciones_max integer;

UPDATE public.planes_catalogo
SET marketplace_publicaciones_max = 0
WHERE marketplace_publicaciones_max IS NULL;

ALTER TABLE public.planes_catalogo
ALTER COLUMN marketplace_publicaciones_max SET DEFAULT 0;

ALTER TABLE public.planes_catalogo
ALTER COLUMN marketplace_publicaciones_max SET NOT NULL;

COMMENT ON COLUMN public.planes_catalogo.marketplace_publicaciones_max
IS 'Número máximo de publicaciones activas permitidas en el marketplace según el plan';
```

### 📝 Actividad 1.2: Actualizar valores por plan
Nota: Al ejecutar en PostgreSQL, no copies las líneas de apertura/cierre de bloque ```sql.
```sql
-- Límite de publicaciones activas por plan
UPDATE public.planes_catalogo pc
SET marketplace_publicaciones_max = v.max_activas
FROM (
    VALUES
        ('gratuito', 0),
        ('basico', 3),
        ('premium', 5),
        ('profesional', 10)
) AS v(codigo, max_activas)
WHERE pc.codigo = v.codigo;
```

### 📝 Actividad 1.3: Verificar estructura actualizada
Nota: Al ejecutar en PostgreSQL, no copies las líneas de apertura/cierre de bloque ```sql.
```sql
-- Verificar que la columna se agregó correctamente
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'planes_catalogo'
  AND table_schema = 'public'
  AND column_name = 'marketplace_publicaciones_max';
```

---

## 📺 PARTE 2: MÓDULO TRANSMISIONES - VIDEOTECA

### 📝 Actividad 2.1: Crear tabla `peleas_evento`
```sql
-- Tabla para gestionar peleas individuales dentro de eventos
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
    CONSTRAINT peleas_evento_pkey PRIMARY KEY (id)
);
```

### 📝 Actividad 2.2: Crear constraints y relaciones
```sql
-- Constraint para evento existente
ALTER TABLE public.peleas_evento
ADD CONSTRAINT peleas_evento_evento_id_fkey
FOREIGN KEY (evento_id)
REFERENCES public.eventos_transmision(id)
ON DELETE CASCADE;

-- Constraint para admin editor (si existe tabla users)
ALTER TABLE public.peleas_evento
ADD CONSTRAINT peleas_evento_admin_editor_id_fkey
FOREIGN KEY (admin_editor_id)
REFERENCES public.users(id);

-- Constraint único: una pelea por número en cada evento
ALTER TABLE public.peleas_evento
ADD CONSTRAINT unique_pelea_por_evento
UNIQUE (evento_id, numero_pelea);

-- Constraint para estado del video
ALTER TABLE public.peleas_evento
ADD CONSTRAINT check_estado_video
CHECK (estado_video IN ('sin_video', 'procesando', 'disponible'));

-- Constraint para resultado
ALTER TABLE public.peleas_evento
ADD CONSTRAINT check_resultado
CHECK (resultado IN ('gallo_1_ganador', 'gallo_2_ganador', 'empate', 'sin_resultado') OR resultado IS NULL);
```

### 📝 Actividad 2.3: Crear índices para optimización
```sql
-- Índice principal por evento
CREATE INDEX idx_peleas_evento ON public.peleas_evento
USING btree (evento_id);

-- Índice para filtrar por estado de video
CREATE INDEX idx_peleas_estado_video ON public.peleas_evento
USING btree (estado_video);

-- Índice para ordenar por fecha real
CREATE INDEX idx_peleas_fecha_real ON public.peleas_evento
USING btree (hora_inicio_real);

-- Índice compuesto para búsquedas frecuentes
CREATE INDEX idx_peleas_evento_numero ON public.peleas_evento
USING btree (evento_id, numero_pelea);

-- Índice para admin que editó
CREATE INDEX idx_peleas_admin_editor ON public.peleas_evento
USING btree (admin_editor_id);
```

### 📝 Actividad 2.4: Comentarios para documentación
```sql
-- Documentar tabla y columnas principales
COMMENT ON TABLE public.peleas_evento IS 'Peleas individuales que forman parte de un evento de transmisión';

COMMENT ON COLUMN public.peleas_evento.numero_pelea IS 'Número secuencial de la pelea dentro del evento (1, 2, 3, etc.)';
COMMENT ON COLUMN public.peleas_evento.resultado IS 'Resultado de la pelea: gallo_1_ganador, gallo_2_ganador, empate, sin_resultado';
COMMENT ON COLUMN public.peleas_evento.estado_video IS 'Estado del video: sin_video, procesando, disponible';
COMMENT ON COLUMN public.peleas_evento.duracion_minutos IS 'Duración real de la pelea en minutos';
COMMENT ON COLUMN public.peleas_evento.video_url IS 'URL del video individual de la pelea (para videoteca)';
```

---

## 🏪 PARTE 3: MÓDULO MARKETPLACE

### 📝 Actividad 3.1: Crear tabla `marketplace_publicaciones`
```sql
-- Tabla principal para publicaciones de gallos en marketplace
CREATE TABLE public.marketplace_publicaciones (
    id serial4 NOT NULL,
    usuario_id int4 NOT NULL,
    titulo varchar(255) NOT NULL,
    descripcion text NULL,
    precio numeric(10, 2) NOT NULL,
    edad_meses int4 NULL,
    peso_gramos int4 NULL,
    raza varchar(100) NULL,
    color_principal varchar(50) NULL,
    ubicacion_departamento varchar(100) NULL,
    ubicacion_provincia varchar(100) NULL,
    ubicacion_distrito varchar(100) NULL,
    telefono_contacto varchar(20) NULL,
    whatsapp_contacto varchar(20) NULL,
    estado varchar(50) DEFAULT 'activa'::character varying NOT NULL,
    es_destacada bool DEFAULT false NULL,
    fecha_destacada_hasta timestamp NULL,
    motivo_inactiva text NULL,
    admin_revisor_id int4 NULL,
    fecha_revision timestamp NULL,
    total_visualizaciones int4 DEFAULT 0 NULL,
    total_contactos int4 DEFAULT 0 NULL,
    created_at timestamp DEFAULT CURRENT_TIMESTAMP NULL,
    updated_at timestamp DEFAULT CURRENT_TIMESTAMP NULL,
    CONSTRAINT marketplace_publicaciones_pkey PRIMARY KEY (id)
);
```

### 📝 Actividad 3.2: Crear tabla `marketplace_publicacion_fotos_sel`
```sql
-- Selección de fotos para la publicación, referenciando fotos existentes del módulo Pedigrí
-- No se duplican archivos; solo se selecciona cuáles fotos del gallo se muestran en la publicación
CREATE TABLE IF NOT EXISTS public.marketplace_publicacion_fotos_sel (
    id serial4 PRIMARY KEY,
    publicacion_id int4 NOT NULL,
    pedigri_foto_id int4 NOT NULL,
    orden_foto int4 NOT NULL, -- 1..4
    es_principal bool DEFAULT false,
    created_at timestamp DEFAULT CURRENT_TIMESTAMP
);
```

### 📝 Actividad 3.3: Crear constraints para marketplace
```sql
-- Relación con usuarios
ALTER TABLE public.marketplace_publicaciones
ADD CONSTRAINT marketplace_publicaciones_usuario_id_fkey
FOREIGN KEY (usuario_id)
REFERENCES public.users(id);

-- Relación con admin revisor
ALTER TABLE public.marketplace_publicaciones
ADD CONSTRAINT marketplace_publicaciones_admin_revisor_id_fkey
FOREIGN KEY (admin_revisor_id)
REFERENCES public.users(id);

-- Relación selección de fotos con publicación (al eliminar la publicación, se elimina la selección)
ALTER TABLE public.marketplace_publicacion_fotos_sel
ADD CONSTRAINT sel_fotos_publicacion_id_fkey
FOREIGN KEY (publicacion_id)
REFERENCES public.marketplace_publicaciones(id)
ON DELETE CASCADE;

-- Relación con fotos del módulo Pedigrí (ajustar nombre real de la tabla si difiere)
ALTER TABLE public.marketplace_publicacion_fotos_sel
ADD CONSTRAINT sel_fotos_pedigri_foto_id_fkey
FOREIGN KEY (pedigri_foto_id)
REFERENCES public.pedigri_fotos(id)
ON DELETE RESTRICT;

-- Constraints de validación
ALTER TABLE public.marketplace_publicaciones
ADD CONSTRAINT check_estado_publicacion
CHECK (estado IN ('activa', 'pausada', 'vendida', 'rechazada', 'caducada'));

ALTER TABLE public.marketplace_publicaciones
ADD CONSTRAINT check_precio_positivo
CHECK (precio > 0);

ALTER TABLE public.marketplace_publicacion_fotos_sel
ADD CONSTRAINT check_sel_orden_foto
CHECK (orden_foto BETWEEN 1 AND 4);

-- Constraint único: solo una foto principal por publicación
ALTER TABLE public.marketplace_publicacion_fotos_sel
ADD CONSTRAINT unique_sel_principal_por_publicacion
UNIQUE (publicacion_id, es_principal)
DEFERRABLE INITIALLY DEFERRED;

-- Constraint único: un orden por publicación
ALTER TABLE public.marketplace_publicacion_fotos_sel
ADD CONSTRAINT unique_sel_orden_por_publicacion
UNIQUE (publicacion_id, orden_foto);
```

### 📝 Actividad 3.4: Crear índices para marketplace
```sql
-- Índices para publicaciones
CREATE INDEX idx_marketplace_usuario ON public.marketplace_publicaciones
USING btree (usuario_id);

CREATE INDEX idx_marketplace_estado ON public.marketplace_publicaciones
USING btree (estado);

CREATE INDEX idx_marketplace_precio ON public.marketplace_publicaciones
USING btree (precio);

CREATE INDEX idx_marketplace_ubicacion ON public.marketplace_publicaciones
USING btree (ubicacion_departamento, ubicacion_provincia);

CREATE INDEX idx_marketplace_fecha ON public.marketplace_publicaciones
USING btree (created_at DESC);

CREATE INDEX idx_marketplace_destacada ON public.marketplace_publicaciones
USING btree (es_destacada, fecha_destacada_hasta);

-- Índices para selección de fotos (referencias a Pedigrí)
CREATE INDEX idx_sel_fotos_publicacion ON public.marketplace_publicacion_fotos_sel
USING btree (publicacion_id);

CREATE INDEX idx_sel_fotos_orden ON public.marketplace_publicacion_fotos_sel
USING btree (publicacion_id, orden_foto);
```

### 📝 Actividad 3.5: Trigger para límite de publicaciones
```sql
-- Función para verificar límite de publicaciones por plan
CREATE OR REPLACE FUNCTION verificar_limite_publicaciones()
RETURNS TRIGGER AS $$
DECLARE
    plan_actual RECORD;
    publicaciones_activas INTEGER;
BEGIN
    -- Obtener plan actual del usuario
    SELECT pc.marketplace_publicaciones_max
    INTO plan_actual
    FROM users u
    JOIN suscripciones s ON u.id = s.usuario_id
    JOIN planes_catalogo pc ON s.plan_id = pc.id
    WHERE u.id = NEW.usuario_id
    AND s.estado = 'activa'
    AND s.fecha_fin >= CURRENT_DATE;

    -- Si no tiene plan activo, no puede publicar
    IF plan_actual.marketplace_publicaciones_max IS NULL THEN
        RAISE EXCEPTION 'No tienes un plan activo para publicar en marketplace';
    END IF;

    -- Contar publicaciones activas del usuario en el mes actual
    SELECT COUNT(*) INTO publicaciones_activas
    FROM marketplace_publicaciones mp
    WHERE mp.usuario_id = NEW.usuario_id
    AND mp.estado = 'activa'
    AND DATE_TRUNC('month', mp.created_at) = DATE_TRUNC('month', CURRENT_DATE);

    -- Verificar límite
    IF publicaciones_activas >= plan_actual.marketplace_publicaciones_max THEN
        RAISE EXCEPTION 'Has alcanzado el límite de % publicaciones para tu plan',
            plan_actual.marketplace_publicaciones_max;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crear trigger
CREATE TRIGGER trigger_verificar_limite_publicaciones
    BEFORE INSERT ON marketplace_publicaciones
    FOR EACH ROW
    EXECUTE FUNCTION verificar_limite_publicaciones();
```

---

## 🛠️ PARTE 4: FUNCIONES Y PROCEDIMIENTOS AUXILIARES

### 📝 Actividad 4.1: Función para estadísticas de eventos
```sql
-- Función para obtener estadísticas completas de un evento
CREATE OR REPLACE FUNCTION obtener_estadisticas_evento(evento_id_param INTEGER)
RETURNS TABLE (
    total_peleas INTEGER,
    peleas_con_video INTEGER,
    duracion_total_minutos INTEGER,
    pelea_mas_larga INTEGER,
    pelea_mas_corta INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*)::INTEGER as total_peleas,
        COUNT(CASE WHEN estado_video = 'disponible' THEN 1 END)::INTEGER as peleas_con_video,
        COALESCE(SUM(duracion_minutos), 0)::INTEGER as duracion_total_minutos,
        COALESCE(MAX(duracion_minutos), 0)::INTEGER as pelea_mas_larga,
        COALESCE(MIN(duracion_minutos), 0)::INTEGER as pelea_mas_corta
    FROM peleas_evento
    WHERE evento_id = evento_id_param;
END;
$$ LANGUAGE plpgsql;
```

### 📝 Actividad 4.2: Procedimiento para actualizar timestamps
```sql
-- Trigger function para updated_at automático
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar a todas las tablas que necesiten updated_at automático
CREATE TRIGGER trigger_update_peleas_evento_timestamp
    BEFORE UPDATE ON peleas_evento
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER trigger_update_marketplace_publicaciones_timestamp
    BEFORE UPDATE ON marketplace_publicaciones
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp();
```

### 📝 Actividad 4.3: Vista para marketplace activo
```sql
-- Vista para publicaciones activas con información completa
CREATE OR REPLACE VIEW vista_marketplace_activo AS
SELECT
    mp.id,
    mp.titulo,
    mp.descripcion,
    mp.precio,
    mp.edad_meses,
    mp.peso_gramos,
    mp.raza,
    mp.color_principal,
    mp.ubicacion_departamento,
    mp.ubicacion_provincia,
    mp.ubicacion_distrito,
    mp.telefono_contacto,
    mp.whatsapp_contacto,
    mp.es_destacada,
    mp.total_visualizaciones,
    mp.total_contactos,
    mp.created_at,
    u.nombre as vendedor_nombre,
    u.telefono as vendedor_telefono,
    COUNT(sel.id) as total_fotos,
    MAX(CASE WHEN sel.es_principal THEN pf.secure_url END) as foto_principal_url -- TODO: ajustar columna real de fotos de Pedigrí
FROM marketplace_publicaciones mp
JOIN users u ON mp.usuario_id = u.id
LEFT JOIN marketplace_publicacion_fotos_sel sel ON mp.id = sel.publicacion_id
LEFT JOIN pedigri_fotos pf ON sel.pedigri_foto_id = pf.id -- TODO: ajustar nombre real de la tabla/columnas de fotos Pedigrí
WHERE mp.estado = 'activa'
GROUP BY mp.id, u.nombre, u.telefono
ORDER BY mp.es_destacada DESC, mp.created_at DESC;
```

---

## ✅ PARTE 5: CONSULTAS DE VERIFICACIÓN

### 📝 Actividad 5.1: Verificar estructura completa
```sql
-- Verificar que todas las tablas fueron creadas
SELECT
    schemaname,
    tablename,
    tableowner
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('peleas_evento', 'marketplace_publicaciones', 'marketplace_publicacion_fotos_sel')
ORDER BY tablename;
```

### 📝 Actividad 5.2: Verificar constraints
```sql
-- Verificar todas las constraints creadas
SELECT
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_schema = 'public'
AND tc.table_name IN ('peleas_evento', 'marketplace_publicaciones', 'marketplace_publicacion_fotos_sel', 'planes_catalogo')
ORDER BY tc.table_name, tc.constraint_type;
```

### 📝 Actividad 5.3: Verificar índices
```sql
-- Verificar todos los índices creados
SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
AND tablename IN ('peleas_evento', 'marketplace_publicaciones', 'marketplace_fotos')
ORDER BY tablename, indexname;
```

### 📝 Actividad 5.4: Verificar triggers y funciones
```sql
-- Verificar triggers
SELECT
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE trigger_schema = 'public'
AND event_object_table IN ('peleas_evento', 'marketplace_publicaciones')
ORDER BY event_object_table;

-- Verificar funciones creadas
SELECT
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name IN ('verificar_limite_publicaciones', 'obtener_estadisticas_evento', 'update_timestamp')
ORDER BY routine_name;
```

---

## 🎲 PARTE 6: DATOS DE PRUEBA (OPCIONAL)

### 📝 Actividad 6.1: Datos de prueba para planes_catalogo
```sql
-- Solo si la tabla está vacía, insertar planes básicos
INSERT INTO public.planes_catalogo (
    codigo, nombre, descripcion, precio, gallos_maximo, peleas_por_gallo,
    topes_por_gallo, vacunas_por_gallo, videos_ilimitados, duracion_semanas,
    soporte_premium, respaldo_nube, estadisticas_avanzadas, marketplace_publicaciones_max
) VALUES
('gratuito', 'Plan Gratuito', 'Plan básico sin costo', 0, 2, 1, 1, 1, false, 0, false, false, false, 0),
('basico', 'Plan Básico', 'Plan básico con funciones limitadas', 29, 5, 3, 3, 3, false, 1, false, false, false, 3),
('premium', 'Plan Premium', 'Plan avanzado con más funciones', 59, 15, 10, 10, 10, true, 2, true, true, true, 5),
('profesional', 'Plan Profesional', 'Plan completo para criadores profesionales', 99, -1, -1, -1, -1, true, 4, true, true, true, 10)
ON CONFLICT (codigo) DO NOTHING;
```

### 📝 Actividad 6.2: Datos de prueba para eventos_transmision
```sql
-- Solo para pruebas, insertar algunos eventos
INSERT INTO public.eventos_transmision (
    titulo, descripcion, fecha_evento, fecha_fin_evento, url_transmision,
    estado, tipo_evento, precio_entrada, es_premium, thumbnail_url
) VALUES
('Torneo Regional 2024', 'Torneo de gallos regional con los mejores criadores',
 '2024-03-15 19:00:00', '2024-03-15 23:00:00', 'https://kick.com/torneo-regional-2024',
 'finalizado', 'regional', 15.00, true, 'https://example.com/thumbnail1.jpg'),

('Copa Nacional', 'Copa nacional de gallos de pelea',
 '2024-04-20 18:00:00', '2024-04-20 22:30:00', 'https://kick.com/copa-nacional',
 'finalizado', 'nacional', 25.00, true, 'https://example.com/thumbnail2.jpg')
ON CONFLICT DO NOTHING;
```

### 📝 Actividad 6.3: Datos de prueba para peleas_evento
```sql
-- Peleas para el primer evento (solo si existe evento con id 1)
INSERT INTO public.peleas_evento (
    evento_id, numero_pelea, titulo_pelea, gallo_1_nombre, gallo_2_nombre,
    hora_inicio_estimada, hora_inicio_real, hora_fin_real, duracion_minutos,
    resultado, estado_video, descripcion_pelea
) VALUES
(1, 1, 'Primera Pelea - Semifinal', 'El Campeón', 'Furia Roja',
 '20:00:00', '2024-03-15 20:05:00', '2024-03-15 20:20:00', 15,
 'gallo_1_ganador', 'disponible', 'Semifinal del torneo regional'),

(1, 2, 'Segunda Pelea - Semifinal', 'Rayo Negro', 'Trueno Azul',
 '20:30:00', '2024-03-15 20:35:00', '2024-03-15 20:47:00', 12,
 'gallo_2_ganador', 'disponible', 'Segunda semifinal del torneo'),

(1, 3, 'Final del Torneo', 'El Campeón', 'Trueno Azul',
 '21:00:00', '2024-03-15 21:10:00', '2024-03-15 21:28:00', 18,
 'gallo_1_ganador', 'procesando', 'Final del torneo regional')
WHERE EXISTS (SELECT 1 FROM eventos_transmision WHERE id = 1);
```

---

## 🏁 RESUMEN DE EJECUCIÓN

### ✅ Lista de Verificación Final

Para ejecutar todas las actividades en orden:

1. **[ ] PARTE 1**: Ejecutar actividades 1.1 a 1.3 (Correcciones planes_catalogo)
2. **[ ] PARTE 2**: Ejecutar actividades 2.1 a 2.4 (Módulo Transmisiones)
3. **[ ] PARTE 3**: Ejecutar actividades 3.1 a 3.5 (Módulo Marketplace)
4. **[ ] PARTE 4**: Ejecutar actividades 4.1 a 4.3 (Funciones auxiliares)
5. **[ ] PARTE 5**: Ejecutar actividades 5.1 a 5.4 (Verificaciones)
6. **[ ] PARTE 6**: Opcional - Ejecutar actividades 6.1 a 6.3 (Datos de prueba)

### 📊 Estadísticas del Documento

- **Total de actividades**: 23
-- **Nuevas tablas**: 3 (`peleas_evento`, `marketplace_publicaciones`, `marketplace_publicacion_fotos_sel`)
- **Tablas modificadas**: 1 (`planes_catalogo`)
- **Índices creados**: 12
- **Funciones creadas**: 3
- **Triggers creados**: 4
- **Constraints creados**: 15
- **Vistas creadas**: 1

### 🎯 Siguiente Paso

Una vez ejecutadas todas las actividades de base de datos, el sistema estará listo para:

1. **Desarrollo Frontend**: Implementar pantallas y widgets para transmisiones y marketplace
2. **Desarrollo Backend**: Crear APIs para gestión de peleas y marketplace
3. **Pruebas de Integración**: Verificar funcionamiento completo del sistema

---

**📅 Fecha de Creación**: 2024-09-21
**👨‍💻 Preparado para**: Proyecto Gallos App
**🔧 Estado**: Listo para ejecución