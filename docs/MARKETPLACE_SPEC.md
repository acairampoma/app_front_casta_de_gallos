# 🛒 Marketplace Frontend Spec

## ✅ Estado actual
- Publicaciones, Favoritos y Mis Publicaciones integradas a APIs reales.
- Modelo `Publicacion` extendido con detalles del gallo y datos del vendedor.
- Detalle de publicación con carrusel y características clave.
- Contacto por WhatsApp conectado cuando hay teléfono.

## 📂 Estructura relevante
- `lib/screens/marketplace/marketplace_screen.dart`
- `lib/screens/marketplace/publicaciones_tab.dart`
- `lib/screens/marketplace/favoritos_tab.dart`
- `lib/screens/marketplace/mis_publicaciones_tab.dart`
- `lib/screens/marketplace/detalle_publicacion_screen.dart`
- `lib/widgets/marketplace/publicacion_card.dart`
- `lib/widgets/marketplace/foto_carousel.dart`
- `lib/models/publicacion_model.dart`
- `lib/services/marketplace_service.dart`
- `lib/services/whatsapp_service.dart`

## 🧱 Estructura completa creada/modificada

```
lib/
├── screens/
│   └── marketplace/
│       ├── marketplace_screen.dart           # Pantalla contenedora con TabBar (Publicaciones, Favoritos, Mis Publicaciones)
│       ├── publicaciones_tab.dart            # Lista de todas las publicaciones (API real + búsqueda)
│       ├── favoritos_tab.dart                # Lista de favoritos (API real)
│       ├── mis_publicaciones_tab.dart        # Lista de mis publicaciones (API real + FAB Publicar)
│       └── detalle_publicacion_screen.dart   # Detalle con carrusel, características y contacto
│
├── widgets/
│   └── marketplace/
│       ├── publicacion_card.dart             # Card reutilizable con navegación al detalle y botón WhatsApp
│       └── foto_carousel.dart                # Carrusel de fotos con PageView + InteractiveViewer
│
├── models/
│   └── publicacion_model.dart                # Modelo Publicacion (datos del gallo + vendedor)
│
├── services/
│   ├── marketplace_service.dart              # Servicio API con Bearer + filtros/paginación
│   └── whatsapp_service.dart                 # Abrir chat de WhatsApp de forma segura
│
└── providers/
    └── marketplace_provider.dart             # (Stub inicial) Ejemplo de proveedor de estado
```

### Responsabilidades por archivo
- `marketplace_screen.dart`: orquesta tabs con `TabBar` y `TabBarView`.
- `publicaciones_tab.dart`: carga publicaciones vía `MarketplaceService.getPublicaciones`, soporta búsqueda `buscar`.
- `favoritos_tab.dart`: consume `getFavoritos` con `FutureBuilder`.
- `mis_publicaciones_tab.dart`: consume `getMisPublicaciones` con `FutureBuilder`, incluye FAB "Publicar" (placeholder).
- `detalle_publicacion_screen.dart`: muestra carrusel, características (peso/altura/colores), observaciones, información del vendedor (nombre/teléfono/email) y botón WhatsApp.
- `publicacion_card.dart`: renderiza foto, nombre, "raza • peso • altura", precio; navega al detalle; habilita Contactar (WhatsApp) si hay teléfono.
- `foto_carousel.dart`: carrusel simple con `PageView` e `InteractiveViewer`.
- `publicacion_model.dart`: parser robusto tolerante a `gallo.{...}` o plano; expone campos del gallo y vendedor.
- `marketplace_service.dart`: construye URIs con `Constants.baseApiUrl`, agrega `Authorization: Bearer <token>`, soporta `filtros`, `page`, `page_size`, y extrae listas desde `data`/`items`.
- `whatsapp_service.dart`: abre `https://wa.me/<phone>?text=<msg>` usando `url_launcher`.

### Endpoints usados
- `GET /marketplace/publicaciones?buscar=<q>&page=<n>&page_size=<m>`
- `GET /marketplace/mis-favoritos?page=<n>&page_size=<m>`
- `GET /marketplace/mis-publicaciones?page=<n>&page_size=<m>`

### Datos mostrados por pestaña
- Publicaciones: foto, nombre, raza, peso, altura, precio; acciones: detalle, WhatsApp (si hay teléfono), favorito (pendiente toggle).
- Favoritos: mismo layout que Publicaciones, consumiendo favoritos del usuario.
- Mis Publicaciones: foto, nombre, raza, peso, altura, precio; acciones próximas (gestión); botón Publicar.
- Detalle: carrusel, características (peso, altura, color, color patas, color plumaje), observaciones, info vendedor (nombre/teléfono/email), WhatsApp.

## ▶️ Cómo probar rápidamente
1) Abre `MarketplaceScreen` desde tu navegación/bottom bar.
2) En la pestaña Publicaciones:
   - Verifica que se carguen las cards (si no, revisa token JWT en `SharedPreferences` y `Constants.baseApiUrl`).
   - Usa búsqueda (enter o botón Filtros) para filtrar por nombre (`buscar`).
   - Toca una card para entrar al detalle.
3) En el detalle:
   - Revisa carrusel, características y observaciones.
   - Verifica sección "Información del Vendedor".
   - Si hay teléfono, prueba el botón "Contactar" (abre WhatsApp).
4) Revisa Favoritos y Mis Publicaciones: deben cargar sus listas respectivamente con loaders y errores manejados.

## 📦 Modelo: Publicacion
```dart
class Publicacion {
  int id;
  String nombre;
  String raza;
  double precio;
  bool esFavorito;
  List<String> fotos;
  double? peso;
  int? altura;
  String? color;
  String? colorPatas;
  String? colorPlumaje;
  String? observaciones;
  String? vendedorNombre;
  String? vendedorTelefono;
  String? vendedorEmail;
}
```
- Parser robusto: acepta estructuras bajo `gallo.{...}` o planas.
- Datos de vendedor: de `vendedor` | `propietario` o claves planas.

## 🔌 Servicios: MarketplaceService
- Base: `Constants.baseApiUrl` + Bearer desde `SharedPreferences`.
- Métodos:
  - `getPublicaciones({filtros, page, page_size})`
  - `getFavoritos({page, page_size})`
  - `getMisPublicaciones({page, page_size})`
- Manejo de payloads `data` | `items` | lista directa.

## 🧭 Reglas de visualización
- Publicaciones (Todas):
  - Card: foto, nombre, "raza • peso • altura", precio.
  - Acciones: Ver detalle, Contactar (WhatsApp si hay teléfono), Favorito (toggle: pendiente integrar endpoint).
  - Detalle: Carrusel, características (peso/altura/color/patas/plumaje), Observaciones, Información del Vendedor (nombre/teléfono/email), botón Contactar.
- Mis Publicaciones:
  - Card: foto, nombre, "raza • peso • altura", precio.
  - Acciones próximas: Editar, Pausar/Activar, Eliminar, Ver.
  - Detalle: igual a Publicaciones; contacto visible pero principalmente informativo.
- Favoritos: lista de cards como Publicaciones.

## 🧩 Navegación
- `PublicacionCard` → `DetallePublicacionScreen(pub)` al tap.

## 📱 WhatsApp
- `WhatsappService.openChat(phone, message)`.
- Botón deshabilitado si no hay `vendedorTelefono`.

## ▶️ Flujos
- PublicacionesTab: búsqueda `buscar` y render con `FutureBuilder`.
- Favoritos/Mis Publicaciones: carga con `FutureBuilder`, estados: loading/error/empty.

## 🔜 Pendientes/Mejoras
- Toggle Favorito (endpoints agregar/quitar) y refrescar listas.
- Filtros avanzados: `precio_min`, `precio_max`, `raza_id`, `estado`.
- Paginación: infinite scroll con `page`/`page_size`.
- Gestión Mis Publicaciones: crear/editar/pausar/eliminar.
- Theming y constantes de color del Marketplace.

## ✅ QA Checklist
- Publicaciones carga y muestra cards con datos reales.
- Detalle muestra raza, peso, altura, colores, observaciones.
- Contactar deshabilitado cuando no hay teléfono; abre WhatsApp cuando hay.
- Favoritos/Mis Publicaciones cargan con estados correctos.
- Búsqueda por `buscar` devuelve resultados filtrados.
