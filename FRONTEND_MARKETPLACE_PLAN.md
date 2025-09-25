# 🚀 PLAN FRONTEND MARKETPLACE - IMPLEMENTACIÓN COMPLETA

Implementación ordenada del módulo marketplace en Flutter siguiendo el flujo lógico del usuario.

---

## 📋 ORDEN DE IMPLEMENTACIÓN

### ✅ Estado actual (progreso)
- **Pedigrí (Add + Edit) con 4 fotos**: COMPLETADO en UI y servicio.
- **Web (Chrome)**: Soportado en Add y Edit con selección múltiple y previsualización completa (grid + carrusel).
- **Servicio de subida**: Corregido helper `_addMultipleFotosToRequest` en `lib/services/gallo_service_v2.dart` (ámbito de clase, uso en create/update).
- **Homogeneidad Add vs Edit**:
  - Add ahora muestra todas las miniaturas como Edit (Grid shrinkWrap y botones de acción consistentes).
  - Edit mejorado: grid de adicionales, carrusel fullscreen y botón “Agregar fotos” directo a selección múltiple.

> Próximos ajustes sugeridos (opcional): unificar helpers de grid/carrusel como widget compartido; fallback de selección múltiple web con `file_picker` si fuese necesario en navegadores específicos.

### 1. 🏠 HOME - ICONO WHATSAPP SOPORTE
**Prioridad**: ALTA
**Ubicación**: Home screen - Quick actions
**Cambio**: Reemplazar icono actual con WhatsApp
**Funcionalidad**:
- Icono WhatsApp en lugar del actual
- Al presionar abre WhatsApp con número: `+51 993 592 328`
- Mensaje predeterminado: "Hola, necesito soporte técnico en GalloApp"

**Archivos a modificar**:
- `lib/screens/home/home_screen.dart`
- `lib/widgets/quick_actions/quick_actions_widget.dart`

---

### 2. 📸 PEDIGREE - 4 FOTOS UPLOAD
**Prioridad**: ALTA

**Estado**: ✅ COMPLETADO (Add + Edit) con compatibilidad Web

**Ubicación**: Formulario multi-paso de pedigrí

**Cambio**: Actualizado de 1 foto a 4 fotos en “Agregar” y “Editar”

**Funcionalidad implementada**:
- Selector de hasta 4 fotos (Web y móvil), con límite y mensajes claros.
- Preview de todas las fotos seleccionadas en grid 2xN (shrinkWrap) con botón “x” por miniatura.
- Carrusel fullscreen con zoom y cierre.
- Envío al backend: foto principal + `fotos_adicionales` (archivos adicionales).
- Homogeneidad de UX entre Add y Edit (botón “Agregar fotos” llama selección múltiple directamente).

**Integración con API (existente)**:
- Uso de `GalloServiceV2.createGalloConGenealogiaEpico` y `updateGalloConExpansionEpico`.
- Helper corregido: `_addMultipleFotosToRequest` (ámbito de clase) para adjuntar `fotos_adicionales[]`.

**Archivos modificados (reales)**:
- `lib/features/pedigri/screens/add_gallo_multistep_screen.dart`
- `lib/features/pedigri/screens/edit_gallo_multistep_screen.dart`
- `lib/services/gallo_service_v2.dart`

**Notas Web**:
- En Web se usa `Image.network` con `XFile.path` para previsualización.
- Si en el futuro se requiere mayor compatibilidad multi-navegador, considerar fallback con `file_picker` (opcional).

---

### 3. 💳 PLANES - LÍMITES MARKETPLACE Y STREAMING
**Prioridad**: ALTA
**Ubicación**: Módulo de suscripciones
**Cambio**: Mostrar límites de marketplace y streaming
**Funcionalidad**:
- Card de cada plan muestra:
  - `marketplace_publicaciones_max` publicaciones
  - `duracion_semanas` semanas de streaming
  - Características visuales mejoradas
- Integración con endpoint `/suscripciones/planes`

**Archivos a modificar**:
- `lib/screens/suscripciones/planes_screen.dart`
- `lib/models/plan_model.dart`
- `lib/widgets/plan_card/plan_card_widget.dart`

---

### 4. 🛒 MARKETPLACE - MÓDULO PRINCIPAL
**Prioridad**: MÁXIMA
**Ubicación**: Nuevo módulo completo
**Estructura**: 3 pestañas principales

#### 4.1 📱 Navegación y Estructura
**Icon**: `marketplace.webp` (assets/images/modulos/)
**Ubicación**: Bottom navigation o drawer menu

**Estructura de pestañas**:
```
🛒 Marketplace
├── 📋 Todas las Publicaciones
├── ❤️ Mis Favoritos
└── 📝 Mis Publicaciones
```

#### 4.2 📋 PESTAÑA: "Todas las Publicaciones"
**Funcionalidad**:
- Grid/List de todas las publicaciones disponibles
- Filtros por precio, raza, estado
- Búsqueda por nombre de gallo
- Infinite scroll con paginación
- Tap para abrir detalle

**Integración API**:
- Endpoint: `/marketplace/publicaciones`
- Filtros: precio_min, precio_max, raza_id, buscar

#### 4.3 ❤️ PESTAÑA: "Mis Favoritos"
**Funcionalidad**:
- Lista de publicaciones marcadas como favoritas
- Botón para remover de favoritos
- Estado vacío cuando no hay favoritos
- Tap para abrir detalle

**Integración API**:
- Endpoint: `/marketplace/mis-favoritos` (a implementar)
- Acciones: agregar/quitar favoritos

#### 4.4 📝 PESTAÑA: "Mis Publicaciones"
**Funcionalidad**:
- Lista de publicaciones propias
- Estados: venta, vendido, pausado
- Botón "+ Publicar" para crear nueva
- Gestión: editar precio, pausar, eliminar
- Estadísticas: favoritos, vistas

**Integración API**:
- Endpoint: `/marketplace/mis-publicaciones`
- CRUD: crear, editar, eliminar publicaciones

---

### 5. 🔍 DETALLE DE PUBLICACIÓN - ÉPICO
**Prioridad**: MÁXIMA
**Ubicación**: Pantalla de detalle (modal o nueva pantalla)

#### 5.1 📸 Carrusel de Fotos
**Funcionalidad**:
- Carrusel horizontal con indicadores
- Zoom en fotos
- Navegación swipe/botones
- Hero animation desde lista

#### 5.2 📊 Información del Gallo
**Datos principales**:
- Nombre, código, raza, edad
- Peso, altura, color
- Precio y estado de venta
- Icono personalizado del gallo

#### 5.3 📈 Resumen de Historial (ÉPICO)
**Reutilización de data de pedigrí**:

**Sección Peleas** 🥊:
- Total de peleas
- Victorias/derrotas
- Última pelea
- Win rate %

**Sección Topes** 🏋️:
- Total de entrenamientos
- Último tope
- Peso registrado
- Progreso

**Sección Vacunas** 💉:
- Vacunas al día
- Próxima vacuna
- Estado de salud
- Historial médico

#### 5.4 👤 Información del Vendedor
**Datos del propietario**:
- Nombre, teléfono, ubicación
- Otros gallos del mismo vendedor
- Botón para contactar WhatsApp

#### 5.5 ❤️ Acciones
- Botón agregar/quitar favorito
- Botón contactar vendedor
- Botón compartir publicación

---

## 🎨 DISEÑO Y UX

### Paleta de Colores Marketplace
```dart
// Colores específicos del marketplace
static const Color marketplaceGreen = Color(0xFF2E8B57);
static const Color favoritePink = Color(0xFFE91E63);
static const Color soldGray = Color(0xFF9E9E9E);
```

### Iconografía
- 🛒 Marketplace principal
- 📋 Todas las publicaciones
- ❤️ Favoritos
- 📝 Mis publicaciones
- 🔍 Buscar/filtrar
- 💰 Precio
- 📸 Fotos
- 📊 Estadísticas

---

## 🔧 IMPLEMENTACIÓN TÉCNICA

### Servicios Requeridos
```dart
// lib/services/marketplace_service.dart
class MarketplaceService {
  Future<List<Publicacion>> getPublicaciones({filtros});
  Future<List<Publicacion>> getMisPublicaciones();
  Future<List<Publicacion>> getFavoritos();
  Future<Publicacion> crearPublicacion(data);
  Future<void> agregarFavorito(id);
  Future<void> quitarFavorito(id);
}
```

### Modelos Requeridos
```dart
// lib/models/publicacion_model.dart
class Publicacion {
  final int id;
  final GalloInfo gallo;
  final VendedorInfo vendedor;
  final double precio;
  final String estado;
  final DateTime fechaPublicacion;
  final bool esFavorito;
  final int totalFavoritos;
}

class GalloInfo {
  final int id;
  final String nombre;
  final String raza;
  final List<FotoGallo> fotos;
  final HistorialGallo historial;
}
```

### Estados con Provider/Riverpod
```dart
// lib/providers/marketplace_provider.dart
class MarketplaceProvider extends ChangeNotifier {
  List<Publicacion> _publicaciones = [];
  List<Publicacion> _favoritos = [];
  List<Publicacion> _misPublicaciones = [];
  bool _loading = false;

  // Métodos para manejar estado
}
```

---

## 📱 WIREFRAMES Y FLUJO

### Flujo Principal
```
Home Screen
    ↓ (Tap Marketplace)
Marketplace Screen (3 tabs)
    ↓ (Tap publicación)
Detalle Publicación
    ↓ (Carrusel + Info + Historial)
Acciones (Favorito/Contactar/Compartir)
```

### Flujo Crear Publicación
```
Mis Publicaciones Tab
    ↓ (Tap "+")
Seleccionar Gallo
    ↓
Configurar Precio/Estado
    ↓
Confirmar Publicación
    ↓
Publicación Creada ✅
```

---

## 📦 ARCHIVOS Y ESTRUCTURA

```
lib/
├── screens/
│   ├── marketplace/
│   │   ├── marketplace_screen.dart          # Pantalla principal con tabs
│   │   ├── publicaciones_tab.dart           # Tab todas las publicaciones
│   │   ├── favoritos_tab.dart               # Tab favoritos
│   │   ├── mis_publicaciones_tab.dart       # Tab mis publicaciones
│   │   ├── detalle_publicacion_screen.dart  # Detalle épico
│   │   └── crear_publicacion_screen.dart    # Crear nueva publicación
│   └── home/
│       └── home_screen.dart                 # Actualizar WhatsApp
├── widgets/
│   ├── marketplace/
│   │   ├── publicacion_card.dart            # Card de publicación
│   │   ├── foto_carousel.dart               # Carrusel de fotos
│   │   ├── gallo_historial_summary.dart     # Resumen épico del historial
│   │   ├── vendedor_info.dart               # Info del vendedor
│   │   └── filtros_marketplace.dart         # Filtros y búsqueda
│   └── common/
│       ├── whatsapp_button.dart             # Botón WhatsApp reutilizable
│       └── multiple_photo_picker.dart       # Selector 4 fotos
├── services/
│   ├── marketplace_service.dart             # API marketplace
│   └── whatsapp_service.dart                # Integración WhatsApp
├── models/
│   ├── publicacion_model.dart               # Modelo publicación
│   └── marketplace_filter_model.dart        # Modelo filtros
├── providers/
│   └── marketplace_provider.dart            # Estado global marketplace
└── assets/
    └── images/
        └── modulos/
            └── marketplace.webp             # Icono del módulo
```

---

## 🚀 CRONOGRAMA DE DESARROLLO

### Semana 1: Bases
- ✅ Backend marketplace funcionando
- 🔄 Actualizar home con WhatsApp
- ✅ Actualizar pedigrí para 4 fotos (Add + Edit, Web incluido)
- 🔄 Actualizar módulo de planes

### Semana 2: Marketplace Core
- 🔄 Estructura básica con 3 tabs
- 🔄 Lista de publicaciones
- 🔄 Integración con APIs
- 🔄 Navegación y routing

### Semana 3: Detalle Épico
- 🔄 Detalle de publicación completo
- 🔄 Carrusel de fotos
- 🔄 Historial del gallo reutilizando pedigrí
- 🔄 Info vendedor y acciones

### Semana 4: Funcionalidades Avanzadas
- 🔄 Favoritos completo
- 🔄 Mis publicaciones con gestión
- 🔄 Filtros y búsqueda
- 🔄 Optimizaciones y testing

---

## 📊 MÉTRICAS Y OBJETIVOS

### KPIs del Marketplace
- **Publicaciones Activas**: Meta 50+ publicaciones
- **Usuarios Activos**: Meta 80% usuarios interactúan
- **Conversiones**: Meta 20% contactan vendedores
- **Retención**: Meta 70% usuarios regresan

### Performance
- **Carga inicial**: < 2 segundos
- **Navegación**: < 500ms entre pantallas
- **Imágenes**: Lazy loading con cache
- **Offline**: Cache básico de favoritos

---

## 🎯 CASOS DE USO PRINCIPALES

### Usuario Comprador
1. **Descubrimiento**: Ve todas las publicaciones, filtra por precio/raza
2. **Evaluación**: Revisa fotos, historial del gallo, info vendedor
3. **Interés**: Agrega a favoritos, contacta vendedor vía WhatsApp
4. **Seguimiento**: Revisa sus favoritos, ve nuevas publicaciones

### Usuario Vendedor
1. **Publicación**: Selecciona gallo, configura precio, publica
2. **Gestión**: Ve sus publicaciones, edita precios, pausa/reactiva
3. **Métricas**: Ve favoritos, contactos, estadísticas
4. **Límites**: Controla cuántas publicaciones puede crear según plan

---

**🚀 MARKETPLACE FRONTEND - LISTO PARA IMPLEMENTAR**

**Orden de desarrollo**:
1. WhatsApp en Home ← **EMPEZAR AQUÍ**
2. 4 fotos en Pedigrí
3. Límites en Planes
4. Marketplace módulo completo
5. Detalle épico con historial

**¿Empezamos con el WhatsApp en Home, cumpa?** 📱✨