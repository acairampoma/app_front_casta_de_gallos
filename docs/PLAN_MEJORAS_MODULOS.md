# 📋 Plan de Mejoras - Módulos de la App

## 🎯 Objetivos Principales

### 1. Migración a ImageKit
Cambiar de proveedor de imágenes a **ImageKit** (más económico) en los siguientes módulos:
- ✅ Transmisiones (ya usa ImageKit - referencia)
- 🔄 Peleas
- 🔄 Topes
- 🔄 Pedigri
- 🔄 Marketplace/Favoritos
- 🔄 Suscripciones

### 2. Mejorar Visor de Imágenes
Crear/mejorar componente de visor de imágenes con:
- 📸 Contador de imágenes (ej: "3/10")
- 🎠 Carrusel ordenado
- 🔍 Zoom y navegación
- 📱 Responsive para móvil
- ✨ Librería tipo PhotoView o similar

### 3. Control de Suscripciones
Mejorar el sistema de suscripciones:
- 📊 Sincronización precisa con backend
- 🔄 Tracking de movimientos en tablas
- ✅ Validación de estado de suscripción
- 🎯 Control de cuotas según plan
- 🆓 Gestión de plan gratuito

### 4. Sistema de Planes y Permisos
- 🔐 Control de acceso a Marketplace según plan
- 💎 Características diferenciadas por plan
- 📈 Estabilidad de cuotas
- ⚖️ Balance entre planes gratuitos y premium

---

## 📝 Tareas Detalladas

### FASE 1: Análisis y Preparación (Prioridad Alta)

#### Tarea 1.1: Revisar implementación actual de ImageKit en Transmisiones
**Objetivo:** Usar como referencia para otros módulos

- [ ] Revisar `lib/features/transmisiones/` 
- [ ] Documentar cómo se usa ImageKit actualmente
- [ ] Identificar servicios/helpers de ImageKit
- [ ] Crear guía de migración

**Archivos a revisar:**
- `lib/features/transmisiones/screens/`
- Buscar servicios de upload/display de imágenes

---

#### Tarea 1.2: Auditar uso actual de imágenes en módulos objetivo
**Objetivo:** Identificar todos los puntos donde se manejan imágenes

**Módulos a auditar:**

##### 📸 Peleas
- [ ] `formulario_pelea_screen.dart` - Upload de imágenes
- [ ] `peleas_screen_real.dart` - Display de imágenes
- [ ] `historial_peleas_screen.dart` - Galería de peleas
- [ ] Identificar campos de imagen en modelo de datos

##### 📸 Topes
- [ ] `formulario_tope_screen.dart` - Upload de imágenes
- [ ] `topes_screen_real.dart` - Display de imágenes
- [ ] `historial_topes_screen.dart` - Galería de topes
- [ ] Identificar campos de imagen en modelo de datos

##### 📸 Pedigri
- [ ] `add_gallo_multistep_screen.dart` - Upload múltiple
- [ ] `edit_gallo_multistep_screen.dart` - Edición de imágenes
- [ ] `pedigri_screen.dart` - Display de galería
- [ ] `genealogy_tree_screen.dart` - Fotos en árbol genealógico
- [ ] Identificar campos de imagen en modelo de datos

##### 📸 Marketplace/Favoritos
- [ ] Identificar pantallas de marketplace
- [ ] Revisar sistema de favoritos
- [ ] Auditar visor de imágenes actual
- [ ] Identificar problemas de orden en carrusel

##### 📸 Suscripciones
- [ ] `suscripcion_screen.dart` - Imágenes de planes
- [ ] `proceso_pago_screen.dart` - Comprobantes
- [ ] Identificar campos de imagen relacionados

**Entregable:** Documento con:
- Lista de archivos que usan imágenes
- Proveedores actuales (Cloudinary, local, etc.)
- Campos de BD que almacenan URLs
- Problemas identificados

---

### FASE 2: Componente de Visor de Imágenes (Prioridad Alta)

#### Tarea 2.1: Investigar y seleccionar librería de visor
**Opciones a evaluar:**

1. **photo_view** (Recomendado)
   - Zoom, pan, rotate
   - Galería integrada
   - Muy usado en Flutter

2. **carousel_slider**
   - Carrusel con indicadores
   - Autoplay opcional
   - Fácil integración

3. **flutter_swiper**
   - Múltiples layouts
   - Indicadores personalizables

**Decisión:** [ ] Seleccionar librería

---

#### Tarea 2.2: Crear componente ImageGalleryViewer
**Ubicación:** `lib/shared/widgets/image_gallery_viewer.dart`

**Características:**
```dart
class ImageGalleryViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final bool showCounter;
  final bool enableZoom;
  final VoidCallback? onClose;
  
  // Callbacks
  final Function(int index)? onImageChanged;
  final Function(String url)? onImageTap;
}
```

**Features a implementar:**
- [ ] Contador de imágenes (ej: "3 de 10")
- [ ] Navegación con gestos (swipe)
- [ ] Zoom con pinch
- [ ] Botón de cerrar
- [ ] Indicadores (dots)
- [ ] Precarga de imágenes adyacentes
- [ ] Loading state
- [ ] Error handling
- [ ] Modo fullscreen

**Tests:**
- [ ] Test con 1 imagen
- [ ] Test con múltiples imágenes
- [ ] Test con URLs inválidas
- [ ] Test de navegación
- [ ] Test de zoom

---

#### Tarea 2.3: Crear componente ImageCarousel
**Ubicación:** `lib/shared/widgets/image_carousel.dart`

**Para uso en listas/cards (no fullscreen)**

**Características:**
```dart
class ImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final double height;
  final bool autoPlay;
  final Duration autoPlayInterval;
  final bool showIndicators;
  final BoxFit fit;
  final Function(int index)? onImageTap;
}
```

**Features:**
- [ ] Carrusel horizontal
- [ ] Indicadores de posición
- [ ] Auto-play opcional
- [ ] Tap para abrir en fullscreen (ImageGalleryViewer)
- [ ] Placeholder mientras carga
- [ ] Cache de imágenes

---

### FASE 3: Servicio de ImageKit (Prioridad Alta)

#### Tarea 3.1: Crear ImageKitService
**Ubicación:** `lib/services/imagekit_service.dart`

**Funcionalidades:**
```dart
class ImageKitService {
  // Configuración
  static const String endpoint = 'https://ik.imagekit.io/tu_id';
  static const String publicKey = 'public_xxx';
  static const String privateKey = 'private_xxx';
  
  // Upload
  static Future<String> uploadImage(File image, {String? folder});
  static Future<List<String>> uploadMultipleImages(List<File> images, {String? folder});
  
  // Transformaciones
  static String getOptimizedUrl(String url, {int? width, int? height, String? quality});
  static String getThumbnailUrl(String url, {int size = 200});
  
  // Delete
  static Future<bool> deleteImage(String fileId);
  static Future<bool> deleteMultipleImages(List<String> fileIds);
  
  // Utils
  static String extractFileId(String url);
  static bool isImageKitUrl(String url);
}
```

**Implementar:**
- [ ] Configuración de credenciales (env variables)
- [ ] Upload con progress callback
- [ ] Manejo de errores
- [ ] Retry logic
- [ ] Compresión antes de upload
- [ ] Generación de thumbnails
- [ ] Transformaciones on-the-fly

---

#### Tarea 3.2: Crear ImageKitUploader Widget
**Ubicación:** `lib/shared/widgets/imagekit_uploader.dart`

**UI para subir imágenes:**
```dart
class ImageKitUploader extends StatefulWidget {
  final bool multiple;
  final int maxImages;
  final Function(List<String> urls) onUploadComplete;
  final String? folder;
  final bool showPreview;
}
```

**Features:**
- [ ] Selección desde galería
- [ ] Selección desde cámara
- [ ] Preview antes de subir
- [ ] Progress bar
- [ ] Validación de tamaño/formato
- [ ] Compresión automática
- [ ] Reordenar imágenes (drag & drop)
- [ ] Eliminar imágenes

---

### FASE 4: Migración de Módulos a ImageKit (Prioridad Media)

#### Tarea 4.1: Migrar módulo PELEAS
**Archivos a modificar:**

1. **formulario_pelea_screen.dart**
   - [ ] Reemplazar upload actual por ImageKitUploader
   - [ ] Guardar URLs de ImageKit en BD
   - [ ] Migrar imágenes existentes (script)

2. **peleas_screen_real.dart**
   - [ ] Usar ImageCarousel para mostrar imágenes
   - [ ] Implementar tap para fullscreen (ImageGalleryViewer)
   - [ ] Optimizar carga con thumbnails

3. **historial_peleas_screen.dart**
   - [ ] Mostrar thumbnails optimizados
   - [ ] Lazy loading de imágenes

**Backend:**
- [ ] Actualizar modelo de datos si es necesario
- [ ] Endpoint para migración de imágenes
- [ ] Validación de URLs de ImageKit

---

#### Tarea 4.2: Migrar módulo TOPES
**Similar a Peleas:**

1. **formulario_tope_screen.dart**
   - [ ] ImageKitUploader

2. **topes_screen_real.dart**
   - [ ] ImageCarousel + ImageGalleryViewer

3. **historial_topes_screen.dart**
   - [ ] Thumbnails optimizados

---

#### Tarea 4.3: Migrar módulo PEDIGRI
**Más complejo - múltiples imágenes por gallo:**

1. **add_gallo_multistep_screen.dart**
   - [ ] ImageKitUploader con multiple=true
   - [ ] Reordenar imágenes
   - [ ] Marcar imagen principal

2. **edit_gallo_multistep_screen.dart**
   - [ ] Editar galería existente
   - [ ] Agregar/eliminar imágenes
   - [ ] Reordenar

3. **pedigri_screen.dart**
   - [ ] ImageCarousel en cards de gallos
   - [ ] Mostrar imagen principal
   - [ ] Contador de imágenes

4. **genealogy_tree_screen.dart**
   - [ ] Thumbnails en nodos del árbol
   - [ ] Tap para ver galería completa

**Consideraciones especiales:**
- [ ] Orden de imágenes (campo `orden` en BD)
- [ ] Imagen principal/destacada
- [ ] Migración de imágenes existentes

---

#### Tarea 4.4: Migrar MARKETPLACE/FAVORITOS
**Problema actual: Carrusel desordenado**

1. **Identificar pantallas de marketplace**
   - [ ] Buscar en `lib/features/` módulo de marketplace
   - [ ] Revisar sistema de favoritos

2. **Implementar orden correcto**
   - [ ] Agregar campo `orden` si no existe
   - [ ] Ordenar por `orden` ASC
   - [ ] UI para reordenar (drag & drop)

3. **Mejorar visor**
   - [ ] ImageGalleryViewer con contador
   - [ ] Navegación fluida
   - [ ] Precarga de imágenes

---

#### Tarea 4.5: Migrar SUSCRIPCIONES
**Imágenes de planes y comprobantes:**

1. **suscripcion_screen.dart**
   - [ ] Imágenes de planes desde ImageKit
   - [ ] Optimización de carga

2. **proceso_pago_screen.dart**
   - [ ] Upload de comprobante con ImageKitUploader
   - [ ] Preview del comprobante
   - [ ] Validación de formato

---

### FASE 5: Sistema de Suscripciones (Prioridad Alta)

#### Tarea 5.1: Auditar sistema actual de suscripciones
**Objetivo:** Entender el flujo completo

- [ ] Revisar modelos de datos (User, Suscripcion, Plan)
- [ ] Revisar endpoints del backend
- [ ] Identificar tablas involucradas
- [ ] Documentar flujo actual
- [ ] Identificar problemas/bugs

**Preguntas a responder:**
- ¿Cómo se crea una suscripción?
- ¿Cómo se valida el estado?
- ¿Cómo se renueva?
- ¿Cómo se cancela?
- ¿Qué pasa cuando expira?
- ¿Cómo se controlan las cuotas?

---

#### Tarea 5.2: Mejorar tracking de suscripciones
**Backend:**

1. **Tabla de auditoría**
   ```sql
   CREATE TABLE suscripcion_movimientos (
     id SERIAL PRIMARY KEY,
     suscripcion_id INT REFERENCES suscripciones(id),
     usuario_id INT REFERENCES usuarios(id),
     tipo_movimiento VARCHAR(50), -- 'creacion', 'renovacion', 'cancelacion', 'expiracion'
     plan_anterior_id INT,
     plan_nuevo_id INT,
     fecha_movimiento TIMESTAMP DEFAULT NOW(),
     detalles JSONB,
     ip_address VARCHAR(50),
     user_agent TEXT
   );
   ```

2. **Endpoints de tracking**
   - [ ] GET `/api/suscripciones/mi-suscripcion` - Estado actual
   - [ ] GET `/api/suscripciones/historial` - Historial de movimientos
   - [ ] GET `/api/suscripciones/cuota-disponible` - Cuota restante
   - [ ] POST `/api/suscripciones/validar` - Validar acceso a feature

**Frontend:**

3. **Servicio de suscripciones**
   ```dart
   class SuscripcionService {
     static Future<Suscripcion?> getMiSuscripcion();
     static Future<List<MovimientoSuscripcion>> getHistorial();
     static Future<CuotaInfo> getCuotaDisponible();
     static Future<bool> validarAcceso(String feature);
     static Stream<Suscripcion> watchSuscripcion(); // Real-time
   }
   ```

4. **Widget de estado de suscripción**
   - [ ] Mostrar plan actual
   - [ ] Mostrar fecha de vencimiento
   - [ ] Mostrar cuota usada/disponible
   - [ ] Alertas de vencimiento próximo
   - [ ] Botón de renovar/mejorar plan

---

#### Tarea 5.3: Control de cuotas por plan
**Objetivo:** Limitar acciones según plan

**Definir límites por plan:**
```dart
class PlanLimits {
  final int maxGallos;
  final int maxPeleas;
  final int maxTopes;
  final int maxImagenesPorGallo;
  final bool accesoMarketplace;
  final bool accesoTransmisiones;
  final bool accesoReportes;
  final int maxFavoritos;
}
```

**Implementar validaciones:**
- [ ] Antes de crear gallo: validar cuota
- [ ] Antes de subir imagen: validar cuota
- [ ] Antes de acceder a marketplace: validar plan
- [ ] Mostrar mensajes claros cuando se alcanza límite
- [ ] Sugerir upgrade de plan

**UI/UX:**
- [ ] Progress bar de cuota usada
- [ ] Badges de plan en perfil
- [ ] Modales de "Mejora tu plan"
- [ ] Comparativa de planes

---

#### Tarea 5.4: Plan gratuito
**Características del plan gratuito:**

- [ ] Definir límites claros
- [ ] Período de prueba (ej: 30 días)
- [ ] Funcionalidades básicas
- [ ] Watermark en imágenes (opcional)
- [ ] Ads (opcional)

**Implementar:**
- [ ] Auto-asignación de plan gratuito en registro
- [ ] Validación de límites
- [ ] Mensajes de upgrade
- [ ] Proceso de upgrade simplificado

---

### FASE 6: Control de Acceso a Marketplace (Prioridad Media)

#### Tarea 6.1: Implementar guard de acceso
**Objetivo:** Solo usuarios con plan adecuado pueden acceder

**Middleware/Guard:**
```dart
class MarketplaceGuard {
  static Future<bool> canAccess() async {
    final suscripcion = await SuscripcionService.getMiSuscripcion();
    return suscripcion?.plan.accesoMarketplace ?? false;
  }
  
  static void showUpgradeDialog(BuildContext context) {
    // Modal para mejorar plan
  }
}
```

**Implementar en:**
- [ ] Navegación a marketplace
- [ ] Publicar en marketplace
- [ ] Ver detalles de publicaciones
- [ ] Agregar a favoritos

---

#### Tarea 6.2: Características diferenciadas por plan
**Matriz de features:**

| Feature | Gratuito | Básico | Premium | VIP |
|---------|----------|--------|---------|-----|
| Max Gallos | 5 | 20 | 50 | ∞ |
| Max Peleas/Mes | 10 | 50 | 200 | ∞ |
| Marketplace | ❌ | ✅ | ✅ | ✅ |
| Transmisiones | ❌ | ❌ | ✅ | ✅ |
| Reportes Avanzados | ❌ | ❌ | ✅ | ✅ |
| Soporte Prioritario | ❌ | ❌ | ❌ | ✅ |
| Imágenes/Gallo | 3 | 5 | 10 | ∞ |

**Implementar:**
- [ ] Tabla de comparación visual
- [ ] Validaciones en cada módulo
- [ ] Mensajes personalizados por feature
- [ ] Tracking de uso de features

---

### FASE 7: Testing y Optimización (Prioridad Baja)

#### Tarea 7.1: Tests unitarios
- [ ] ImageKitService
- [ ] SuscripcionService
- [ ] Validaciones de cuotas
- [ ] Guards de acceso

#### Tarea 7.2: Tests de integración
- [ ] Flujo completo de suscripción
- [ ] Upload de imágenes a ImageKit
- [ ] Visor de galería
- [ ] Control de cuotas

#### Tarea 7.3: Tests de UI
- [ ] ImageGalleryViewer
- [ ] ImageCarousel
- [ ] ImageKitUploader
- [ ] Widgets de suscripción

#### Tarea 7.4: Optimización de rendimiento
- [ ] Lazy loading de imágenes
- [ ] Cache de imágenes
- [ ] Precarga inteligente
- [ ] Compresión de imágenes
- [ ] CDN de ImageKit

---

## 📊 Priorización de Tareas

### 🔴 CRÍTICO (Hacer primero)
1. Tarea 1.1: Revisar implementación de ImageKit en Transmisiones
2. Tarea 2.1-2.3: Crear componentes de visor de imágenes
3. Tarea 3.1-3.2: Crear servicio de ImageKit
4. Tarea 5.1-5.2: Auditar y mejorar tracking de suscripciones

### 🟡 IMPORTANTE (Hacer después)
5. Tarea 4.3: Migrar Pedigri (más complejo)
6. Tarea 5.3-5.4: Control de cuotas y plan gratuito
7. Tarea 4.1-4.2: Migrar Peleas y Topes
8. Tarea 6.1-6.2: Control de acceso a Marketplace

### 🟢 OPCIONAL (Cuando haya tiempo)
9. Tarea 4.4-4.5: Migrar Marketplace y Suscripciones
10. Tarea 7.1-7.4: Testing y optimización

---

## 📅 Estimación de Tiempo

| Fase | Tareas | Tiempo Estimado |
|------|--------|-----------------|
| Fase 1 | Análisis | 2-3 días |
| Fase 2 | Visor de Imágenes | 3-4 días |
| Fase 3 | Servicio ImageKit | 2-3 días |
| Fase 4 | Migración Módulos | 5-7 días |
| Fase 5 | Sistema Suscripciones | 4-5 días |
| Fase 6 | Control Marketplace | 2-3 días |
| Fase 7 | Testing | 3-4 días |
| **TOTAL** | | **21-29 días** |

---

## 🎯 Entregables por Fase

### Fase 1
- [ ] Documento de análisis de ImageKit actual
- [ ] Auditoría de uso de imágenes en módulos
- [ ] Lista de archivos a modificar

### Fase 2
- [ ] Widget `ImageGalleryViewer`
- [ ] Widget `ImageCarousel`
- [ ] Documentación de uso
- [ ] Ejemplos de implementación

### Fase 3
- [ ] Servicio `ImageKitService`
- [ ] Widget `ImageKitUploader`
- [ ] Variables de entorno configuradas
- [ ] Guía de migración

### Fase 4
- [ ] Módulos migrados a ImageKit
- [ ] Script de migración de imágenes existentes
- [ ] Validación de funcionamiento

### Fase 5
- [ ] Sistema de tracking de suscripciones
- [ ] Endpoints de backend
- [ ] Servicio de suscripciones en frontend
- [ ] Widgets de estado de suscripción

### Fase 6
- [ ] Guards de acceso implementados
- [ ] Matriz de features por plan
- [ ] UI de comparación de planes
- [ ] Flujo de upgrade

### Fase 7
- [ ] Suite de tests
- [ ] Reporte de rendimiento
- [ ] Documentación final

---

## 📝 Notas Importantes

### Migración de Imágenes Existentes
- Crear script para migrar imágenes de proveedor actual a ImageKit
- Mantener URLs antiguas como fallback temporalmente
- Validar que todas las imágenes se migraron correctamente
- Actualizar BD con nuevas URLs

### Orden de Imágenes en Carrusel
- Agregar campo `orden` en tabla de imágenes si no existe
- Permitir reordenar con drag & drop en UI
- Guardar orden en BD
- Ordenar por `orden ASC` al cargar

### Compatibilidad con Planes Existentes
- Migrar usuarios existentes a plan correspondiente
- Respetar suscripciones activas
- Notificar cambios a usuarios
- Período de gracia para adaptación

### Variables de Entorno
```env
IMAGEKIT_PUBLIC_KEY=public_xxx
IMAGEKIT_PRIVATE_KEY=private_xxx
IMAGEKIT_URL_ENDPOINT=https://ik.imagekit.io/tu_id
```

---

## 🚀 Próximos Pasos Inmediatos

1. **Revisar este plan** y ajustar prioridades
2. **Comenzar con Fase 1** - Análisis
3. **Crear branch** `feature/imagekit-migration`
4. **Configurar ImageKit** en proyecto
5. **Implementar componentes base** (Fase 2)

---

## ❓ Preguntas Pendientes

1. ¿Cuál es el proveedor actual de imágenes? (Cloudinary, S3, etc.)
2. ¿Cuántas imágenes aproximadas hay que migrar?
3. ¿Ya tienes cuenta de ImageKit configurada?
4. ¿Cuáles son los planes de suscripción actuales?
5. ¿Hay usuarios con suscripciones activas?
6. ¿El backend ya tiene endpoints de suscripciones?
7. ¿Qué librería de visor de imágenes prefieres?

---

**Documento creado:** 2025-11-14
**Última actualización:** 2025-11-14
**Estado:** 📋 Planificación
