-- =====================================================
-- SCRIPT DE DATOS DE PRUEBA - MÓDULO TRANSMISIONES
-- =====================================================
-- Fecha: 2025-01-20
-- Propósito: Poblar tablas con datos de prueba para desarrollo

-- =====================================================
-- 1. INSERTAR COLISEOS DE PRUEBA
-- =====================================================

INSERT INTO coliseos (nombre, direccion, ciudad, departamento, aforo_maximo, descripcion, tipo_coliseo, activo) VALUES
('Coliseo Los Gallos de Oro', 'Av. Los Gallos 123, San Juan de Lurigancho', 'Lima', 'Lima', 500, 'Coliseo tradicional con excelente acústica y ambiente familiar', 'local', true),
('Arena San Juan Magnifica', 'Jr. San Juan 456, El Agustino', 'Lima', 'Lima', 800, 'Coliseo moderno con gradas cómodas y transmisión HD', 'grande', true),
('Coliseo El Campeón', 'Av. La Victoria 789, La Victoria', 'Lima', 'Lima', 300, 'Ambiente familiar y acogedor, ideal para eventos locales', 'local', true),
('Coliseo Provincial Arequipa', 'Av. Dolores 321, Cercado', 'Arequipa', 'Arequipa', 1200, 'El más grande del sur del país, eventos especiales', 'especial', true),
('Arena Trujillo Norte', 'Av. España 654, Trujillo', 'Trujillo', 'La Libertad', 600, 'Tradición norteña en peleas de gallos desde 1950', 'grande', true),
('Coliseo Chiclayo Central', 'Av. Salaverry 987, Chiclayo', 'Chiclayo', 'Lambayeque', 400, 'Centro de tradición gallística del norte', 'local', true),
('Arena Huancayo', 'Jr. Real 147, Huancayo', 'Huancayo', 'Junín', 350, 'Coliseo serrano con gran tradición', 'local', true);

-- =====================================================
-- 2. INSERTAR EVENTOS DE TRANSMISIÓN DE PRUEBA
-- =====================================================

-- Eventos de HOY (para testing inmediato)
INSERT INTO eventos_transmision (coliseo_id, titulo, descripcion, fecha_evento, fecha_fin_evento, url_transmision, estado, tipo_evento, precio_entrada, es_premium, admin_creador_id) VALUES

-- EVENTOS DE HOY - 20 de Enero 2025
(1, 'Torneo Semanal Los Gallos de Oro', 'Competencia semanal con gallos de primera categoría', '2025-01-20 15:00:00', '2025-01-20 18:00:00', 'https://player.kick.com/gallos_oro_lima', 'programado', 'local', 15.00, false, 1),

(2, 'Championship Arena San Juan - EN VIVO', 'Gran evento con gallos campeones nacionales', '2025-01-20 16:30:00', '2025-01-20 20:00:00', 'https://player.kick.com/arena_sanjuan_championship', 'en_vivo', 'grande', 25.00, true, 1),

(3, 'Pelea Nocturna El Campeón', 'Evento nocturno con gallos experimentados', '2025-01-20 19:00:00', '2025-01-20 22:00:00', 'https://player.kick.com/coliseo_campeon_noche', 'programado', 'local', 12.00, false, 1),

-- EVENTOS DE MAÑANA - 21 de Enero 2025
(4, 'Gran Final Provincial Arequipa', 'Final del campeonato sur peruano 2025', '2025-01-21 14:00:00', '2025-01-21 19:00:00', 'https://player.kick.com/arequipa_provincial_final', 'programado', 'especial', 50.00, true, 1),

(5, 'Torneo Norteño Trujillo', 'Tradición gallística liberteña en acción', '2025-01-21 15:30:00', '2025-01-21 18:30:00', 'https://player.kick.com/trujillo_norte_tradicion', 'programado', 'grande', 30.00, true, 1),

-- EVENTOS PASADOS (para testing de estados)
(1, 'Torneo Matutino Finalizado', 'Evento de la mañana ya concluido', '2025-01-20 09:00:00', '2025-01-20 12:00:00', 'https://player.kick.com/gallos_oro_matutino', 'finalizado', 'local', 10.00, false, 1),

(6, 'Evento Chiclayo Ayer', 'Competencia regional del norte', '2025-01-19 16:00:00', '2025-01-19 19:00:00', 'https://player.kick.com/chiclayo_regional', 'finalizado', 'local', 18.00, false, 1),

-- EVENTOS FUTUROS (próximos días)
(7, 'Torneo Serrano Huancayo', 'Gallos de altura en competencia', '2025-01-22 14:00:00', '2025-01-22 17:00:00', 'https://player.kick.com/huancayo_serrano', 'programado', 'local', 20.00, false, 1),

(2, 'Mega Evento Arena San Juan', 'El evento más esperado del mes', '2025-01-25 15:00:00', '2025-01-25 21:00:00', 'https://player.kick.com/arena_sanjuan_mega', 'programado', 'grande', 40.00, true, 1),

(4, 'Campeonato Nacional Arequipa', 'Final nacional de gallos peruanos', '2025-01-26 13:00:00', '2025-01-26 20:00:00', 'https://player.kick.com/campeonato_nacional_2025', 'programado', 'especial', 75.00, true, 1);

-- =====================================================
-- 3. VERIFICAR DATOS INSERTADOS
-- =====================================================

-- Consultar coliseos creados
-- SELECT id, nombre, ciudad, tipo_coliseo, activo FROM coliseos ORDER BY id;

-- Consultar eventos de hoy
-- SELECT e.titulo, c.nombre as coliseo, e.fecha_evento, e.estado, e.es_premium
-- FROM eventos_transmision e
-- JOIN coliseos c ON e.coliseo_id = c.id
-- WHERE DATE(e.fecha_evento) = CURRENT_DATE
-- ORDER BY e.fecha_evento;

-- Consultar todos los eventos
-- SELECT e.titulo, c.nombre as coliseo, e.fecha_evento, e.estado, e.tipo_evento, e.precio_entrada
-- FROM eventos_transmision e
-- JOIN coliseos c ON e.coliseo_id = c.id
-- ORDER BY e.fecha_evento DESC;

-- =====================================================
-- 4. NOTAS IMPORTANTES
-- =====================================================

/*
EVENTOS CREADOS:
- 3 eventos para HOY (20 enero) con diferentes estados
- 2 eventos para MAÑANA (21 enero)
- 2 eventos PASADOS (para testing)
- 3 eventos FUTUROS (próximos días)

COLISEOS:
- 7 coliseos en diferentes ciudades
- Mix de tipos: local, grande, especial
- Aforos diversos para diferentes eventos

URLs DE KICK.COM:
- Todas las URLs siguen el formato: https://player.kick.com/[canal]
- Son URLs de ejemplo, deberás reemplazarlas con tus canales reales

TIPOS DE EVENTOS:
- local: Eventos pequeños (S/10-20)
- grande: Eventos medianos (S/25-40)
- especial: Eventos grandes (S/50-75)

EVENTOS PREMIUM:
- Requieren plan 2S o 4S para acceder
- Precios más altos y mejor calidad
*/