# 🗃️ SCRIPTS DE BASE DE DATOS - MARKETPLACE

## ORDEN DE EJECUCIÓN

### 1. VERIFICAR ESTRUCTURA ACTUAL

```sql
-- Verificar si ya existe la tabla marketplace_publicaciones
SELECT table_name FROM information_schema.tables WHERE table_name = 'marketplace_publicaciones';

-- Verificar estructura actual de tabla gallos
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'gallos'
ORDER BY ordinal_position;

-- Verificar estructura actual de planes_catalogo
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'planes_catalogo'
ORDER BY ordinal_position;
```

### 2. CREAR TABLA MARKETPLACE_PUBLICACIONES

```sql
-- Crear tabla marketplace_publicaciones (estructura completa)
CREATE TABLE public.marketplace_publicaciones (
    id serial4 NOT NULL,
    user_id int4 NOT NULL, -- Usuario que publica (propietario)
    gallo_id int4 NOT NULL, -- Gallo que se publica
    precio numeric(10, 2) NOT NULL,
    estado varchar(50) DEFAULT 'venta'::character varying NOT NULL,
    fecha_publicacion timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    icono_ejemplo varchar(100) DEFAULT '🐓' NULL, -- Ícono de ejemplo para la publicación
    -- Campos de auditoría
    created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by int4 NOT NULL, -- Usuario que creó el registro
    updated_by int4 NOT NULL, -- Usuario que actualizó el registro
    -- Constraints
    CONSTRAINT marketplace_publicaciones_pkey PRIMARY KEY (id),
    CONSTRAINT marketplace_publicaciones_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE,
    CONSTRAINT marketplace_publicaciones_gallo_id_fkey FOREIGN KEY (gallo_id) REFERENCES public.gallos(id) ON DELETE CASCADE,
    CONSTRAINT marketplace_publicaciones_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE CASCADE,
    CONSTRAINT marketplace_publicaciones_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id) ON DELETE CASCADE,
    CONSTRAINT check_estado_valido CHECK (estado IN ('venta', 'vendido', 'pausado')),
    CONSTRAINT check_precio_positivo CHECK (precio > 0)
);
```

### 3. CREAR TABLA DE FAVORITOS

```sql
-- Crear tabla marketplace_favoritos
CREATE TABLE public.marketplace_favoritos (
    id serial4 NOT NULL,
    user_id int4 NOT NULL, -- Usuario que marca como favorito
    publicacion_id int4 NOT NULL, -- Publicación marcada como favorita
    created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    -- Constraints
    CONSTRAINT marketplace_favoritos_pkey PRIMARY KEY (id),
    CONSTRAINT marketplace_favoritos_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE,
    CONSTRAINT marketplace_favoritos_publicacion_id_fkey FOREIGN KEY (publicacion_id) REFERENCES public.marketplace_publicaciones(id) ON DELETE CASCADE,
    CONSTRAINT uk_favoritos_user_publicacion UNIQUE (user_id, publicacion_id) -- No duplicar favoritos
);
```

### 4. CREAR ÍNDICES PARA OPTIMIZACIÓN

```sql
-- Índices para marketplace_publicaciones
CREATE INDEX idx_marketplace_user ON public.marketplace_publicaciones USING btree (user_id);
CREATE INDEX idx_marketplace_gallo ON public.marketplace_publicaciones USING btree (gallo_id);
CREATE INDEX idx_marketplace_estado ON public.marketplace_publicaciones USING btree (estado);
CREATE INDEX idx_marketplace_precio ON public.marketplace_publicaciones USING btree (precio);
CREATE INDEX idx_marketplace_fecha_pub ON public.marketplace_publicaciones USING btree (fecha_publicacion);
CREATE INDEX idx_marketplace_created_by ON public.marketplace_publicaciones USING btree (created_by);

-- Índices para marketplace_favoritos
CREATE INDEX idx_favoritos_user ON public.marketplace_favoritos USING btree (user_id);
CREATE INDEX idx_favoritos_publicacion ON public.marketplace_favoritos USING btree (publicacion_id);
```

### 5. VERIFICAR Y ACTUALIZAR TABLA GALLOS PARA IMÁGENES

```sql
-- Verificar campos actuales de imágenes en gallos
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'gallos'
AND column_name IN ('fotos_adicionales', 'foto_principal_url', 'url_foto_cloudinary');

-- Si no existe fotos_adicionales como JSON, crearlo
-- (Según verificación previa ya existe como JSONB, pero por si acaso)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'gallos' AND column_name = 'fotos_adicionales'
    ) THEN
        ALTER TABLE public.gallos ADD COLUMN fotos_adicionales jsonb DEFAULT '[]'::jsonb;
    END IF;
END
$$;

-- Asegurar que photo_principal_url existe y tiene tipo correcto
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'gallos' AND column_name = 'foto_principal_url'
    ) THEN
        ALTER TABLE public.gallos ADD COLUMN foto_principal_url text;
    END IF;
END
$$;

-- Crear índice para búsquedas en JSON (si no existe)
CREATE INDEX IF NOT EXISTS idx_gallos_fotos_adicionales ON public.gallos USING gin (fotos_adicionales);
```

### 6. VERIFICAR MARKETPLACE LIMITS EN PLANES_CATALOGO

```sql
-- Verificar que existe marketplace_publicaciones_max
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'planes_catalogo'
AND column_name = 'marketplace_publicaciones_max';

-- Si no existe, agregarlo (parece que ya existe según verificación previa)
-- ALTER TABLE public.planes_catalogo
-- ADD COLUMN marketplace_publicaciones_max int4 DEFAULT 0;
```

### 7. CONFIGURAR LÍMITES POR PLAN (SI ES NECESARIO)

```sql
-- Actualizar límites por plan si están en 0
UPDATE public.planes_catalogo SET marketplace_publicaciones_max = 0 WHERE codigo = 'gratuito' AND marketplace_publicaciones_max = 0;
UPDATE public.planes_catalogo SET marketplace_publicaciones_max = 3 WHERE codigo = 'basico' AND marketplace_publicaciones_max = 0;
UPDATE public.planes_catalogo SET marketplace_publicaciones_max = 5 WHERE codigo = 'premium' AND marketplace_publicaciones_max = 0;
UPDATE public.planes_catalogo SET marketplace_publicaciones_max = 10 WHERE codigo = 'profesional' AND marketplace_publicaciones_max = 0;
```

### 8. DATOS DE EJEMPLO PARA FOTOS EN TABLA GALLOS

```sql
-- Actualizar algunos gallos con fotos de ejemplo (OPCIONAL - SOLO PARA DESARROLLO)
-- Estructura JSON esperada para fotos_adicionales:
/*
[
  {
    "url": "https://res.cloudinary.com/tu-cloud/image/upload/v123456/gallo1_foto1.jpg",
    "orden": 1,
    "es_principal": true,
    "descripcion": "Foto frontal"
  },
  {
    "url": "https://res.cloudinary.com/tu-cloud/image/upload/v123456/gallo1_foto2.jpg",
    "orden": 2,
    "es_principal": false,
    "descripcion": "Foto lateral"
  }
]
*/

-- Ejemplo de actualización (reemplazar IDs y URLs reales):
/*
UPDATE public.gallos
SET fotos_adicionales = '[
  {
    "url": "https://example.com/gallo1_foto1.jpg",
    "orden": 1,
    "es_principal": true,
    "descripcion": "Foto principal"
  },
  {
    "url": "https://example.com/gallo1_foto2.jpg",
    "orden": 2,
    "es_principal": false,
    "descripcion": "Foto lateral"
  }
]'::jsonb
WHERE id = 1;
*/
```

## SCRIPTS DE VERIFICACIÓN FINAL

```sql
-- Verificar que todo está creado correctamente
SELECT
    'marketplace_publicaciones' as tabla,
    COUNT(*) as existe
FROM information_schema.tables
WHERE table_name = 'marketplace_publicaciones'

UNION ALL

SELECT
    'indices_creados',
    COUNT(*)
FROM information_schema.statistics
WHERE table_name = 'marketplace_publicaciones';

-- Verificar constraints
SELECT
    constraint_name,
    constraint_type
FROM information_schema.table_constraints
WHERE table_name = 'marketplace_publicaciones';

-- Verificar foreign keys
SELECT
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.key_column_usage AS kcu
JOIN information_schema.constraint_column_usage AS ccu
ON kcu.constraint_name = ccu.constraint_name
WHERE kcu.table_name = 'marketplace_publicaciones'
AND kcu.constraint_name LIKE '%_fkey';
```

## DATOS DE PRUEBA (OPCIONAL)

```sql
-- Insertar datos de prueba para marketplace_publicaciones (SOLO PARA DESARROLLO)
-- NOTA: Reemplazar los IDs con valores reales de tu BD
/*
INSERT INTO public.marketplace_publicaciones (user_id, gallo_id, precio, estado, icono_ejemplo, created_by, updated_by)
VALUES
(1, 1, 150.00, 'venta', '🐓', 1, 1),
(1, 2, 200.50, 'venta', '🦅', 1, 1),
(2, 3, 300.00, 'pausado', '🐔', 2, 2),
(2, 4, 180.75, 'venta', '🐓', 2, 2);
*/

-- Insertar datos de prueba para favoritos (SOLO PARA DESARROLLO)
/*
INSERT INTO public.marketplace_favoritos (user_id, publicacion_id)
VALUES
(1, 3), -- Usuario 1 marca como favorito la publicación 3
(1, 4), -- Usuario 1 marca como favorito la publicación 4
(2, 1); -- Usuario 2 marca como favorito la publicación 1
*/
```

## ROLLBACK (EN CASO DE ERROR)

```sql
-- SOLO EN CASO DE NECESITAR DESHACER CAMBIOS
/*
-- Eliminar datos de prueba
DELETE FROM public.marketplace_favoritos;
DELETE FROM public.marketplace_publicaciones;

-- Eliminar tablas (en orden de dependencias)
DROP TABLE IF EXISTS public.marketplace_favoritos CASCADE;
DROP TABLE IF EXISTS public.marketplace_publicaciones CASCADE;

-- Remover columnas agregadas (si se agregaron)
-- ALTER TABLE public.gallos DROP COLUMN IF EXISTS fotos_adicionales;
-- ALTER TABLE public.planes_catalogo DROP COLUMN IF EXISTS marketplace_publicaciones_max;
*/
```

---

**NOTAS IMPORTANTES:**
1. **Ejecutar estos scripts en orden secuencial**
2. **Verificar cada paso antes de continuar al siguiente**
3. **Los datos de prueba son opcionales**
4. **Mantener backup de la BD antes de ejecutar scripts**
5. **La tabla gallos ya tiene los campos JSON necesarios para fotos**

**CAMPOS PRINCIPALES AGREGADOS:**
- ✅ `user_id` en marketplace_publicaciones (quien publica)
- ✅ `icono_ejemplo` para identificación visual
- ✅ Tabla `marketplace_favoritos` para usuarios
- ✅ ALTER TABLE para asegurar campos JSON en gallos
- ✅ Índices optimizados para todas las consultas

**PRÓXIMO PASO:** Ejecutar estos scripts y luego proceder con Backend