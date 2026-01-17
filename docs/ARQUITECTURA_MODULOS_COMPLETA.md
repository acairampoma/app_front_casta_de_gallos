# 🏗️ Arquitectura Completa de Módulos - GalloApp

## 📋 Índice

1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Estructura General](#estructura-general)
3. [Módulos por Feature](#módulos-por-feature)
4. [Servicios Globales](#servicios-globales)
5. [Modelos Globales](#modelos-globales)
6. [Componentes Compartidos](#componentes-compartidos)

---

## 📊 Resumen Ejecutivo

**Total de Módulos**: 14 features principales
**Total de Screens**: 58 pantallas
**Total de Servicios**: 40+ servicios
**Total de Modelos**: 9 modelos principales
**Arquitectura**: Clean Architecture con Feature-First

---

## 🎯 Estructura General

```
lib/
├── features/              # 14 módulos principales
├── services/              # 40+ servicios globales
├── models/                # 9 modelos compartidos
├── shared/                # Componentes compartidos
│   ├── widgets/          # Widgets reutilizables
│   ├── theme/            # Temas y estilos
│   ├── constants/        # Constantes globales
│   └── services/         # Servicios compartidos
├── config/               # Configuraciones
├── core/                 # Funcionalidades core
└── utils/                # Utilidades
```

---

## 🎨 Módulos por Feature

### 1. 🔐 AUTH (Autenticación)

**Estructura**:
```
features/auth/
└── screens/ (5 pantallas)
    ├── login_screen.dart
    ├── email_verification_screen.dart
    ├── forgot_password_screen.dart
    ├── verify_code_screen.dart
    └── reset_password_screen.dart
```

**Servicios**: auth_service, firebase_notification_service
**Modelos**: usuario
**Funcionalidades**: Login, registro, recuperación de contraseña

---

### 2. 🏠 HOME (Inicio)

**Estructura**:
```
features/home/
└── screens/ (1 pantalla)
    └── home_screen.dart
```

**Servicios**: connection_service, auth_service, suscripcion_service
**Funcionalidades**: Dashboard principal, navegación a módulos

---

### 3. 🐓 PEDIGRI (Genealogía)

**Estructura**:
```
features/pedigri/
├── screens/ (4 pantallas)
│   ├── pedigri_screen.dart
│   ├── add_gallo_multistep_screen.dart
│   ├── edit_gallo_multistep_screen.dart
│   └── genealogy_tree_screen.dart
└── widgets/ (3 widgets)
    ├── add_gallo_dialog.dart
    ├── add_gallo_simple_dialog.dart
    └── edit_gallo_dialog.dart
```

**Servicios**: gallo_service_v2, foto_service, cloudinary_service
**Modelos**: gallo
**Funcionalidades**: CRUD gallos, 4 fotos, árbol genealógico

---

### 4. 🥊 PELEAS (Combates)

**Estructura**:
```
features/peleas/
└── screens/ (5 pantallas)
    ├── peleas_gallos_screen.dart
    ├── peleas_screen.dart
    ├── peleas_screen_real.dart
    ├── formulario_pelea_screen.dart
    └── historial_peleas_screen.dart
```

**Servicios**: peleas_service, gallo_service
**Modelos**: pelea
**Funcionalidades**: Registro peleas, estadísticas, win rate

---

### 5. 🏋️ TOPES (Entrenamientos)

**Estructura**:
```
features/topes/
└── screens/ (5 pantallas)
    ├── topes_gallos_screen.dart
    ├── topes_screen.dart
    ├── topes_screen_real.dart
    ├── formulario_tope_screen.dart
    └── historial_topes_screen.dart
```

**Servicios**: topes_service, gallo_service
**Modelos**: tope
**Funcionalidades**: Registro entrenamientos, peso, progreso

---

### 6. 💉 VACUNAS (Salud)

**Estructura**:
```
features/vacunas/
├── screens/ (4 pantallas)
│   ├── vacunas_screen.dart
│   ├── vacunas_screen_real.dart
│   ├── formulario_vacuna_screen.dart
│   └── historial_vacunas_screen.dart
└── widgets/ (1 widget)
    └── registro_rapido_dialog.dart
```

**Servicios**: vacunas_service, gallo_service
**Modelos**: vacuna, vacuna_model
**Funcionalidades**: Control vacunas, calendario, alertas

---

### 7. 💰 INVERSIONES (Finanzas)

**Estructura**:
```
features/inversiones/
├── screens/ (1 pantalla)
│   └── inversiones_screen.dart
└── widgets/ (2 widgets)
    ├── inversion_form_card.dart
    └── mes_selector_widget.dart
```

**Servicios**: inversion_service, gallo_service
**Funcionalidades**: Control gastos, reportes mensuales

---

### 8. 📊 REPORTES (Análisis)

**Estructura**:
```
features/reportes/
├── screens/ (1 pantalla)
│   └── reportes_screen.dart
├── widgets/ (5 widgets)
│   ├── dashboard_tab.dart
│   ├── rankings_tab.dart
│   ├── documentos_tab.dart
│   ├── filtros_widget.dart
│   └── filtros_simple_widget.dart
├── models/ (3 modelos)
│   ├── dashboard_model.dart
│   ├── rankings_model.dart
│   └── documentos_model.dart
└── services/ (1 servicio)
    └── reportes_service.dart
```

**Funcionalidades**: Dashboard, rankings, PDFs, exportación

---

### 9. 💳 PLANES (Suscripciones)

**Estructura**:
```
features/planes/
├── screens/ (1 pantalla)
│   └── planes_screen.dart
└── widgets/ (2 widgets)
    ├── plan_card.dart
    └── limite_progress_widget.dart
```

**Servicios**: suscripcion_service, pago_service
**Modelos**: suscripcion_models
**Funcionalidades**: Visualización planes, límites, upgrade

---

### 10. 💳 SUSCRIPCION (Pagos)

**Estructura**:
```
features/suscripcion/
└── screens/ (5 pantallas)
    ├── suscripcion_screen.dart
    ├── seleccion_metodo_pago_screen.dart
    ├── proceso_pago_screen.dart
    ├── proceso_pago_mercadopago_screen.dart
    └── checkout_webview_screen.dart
```

**Servicios**: suscripcion_service, pago_service, mercadopago_service
**Modelos**: suscripcion_models, pago_models
**Funcionalidades**: Proceso pago, MercadoPago, historial

---

### 11. 📺 TRANSMISIONES (Streaming)

**Estructura**:
```
features/transmisiones/
└── screens/ (3 pantallas)
    ├── transmisiones_screen.dart
    ├── transmision_en_vivo_screen.dart
    └── videoteca_peleas_screen.dart
```

**Servicios**: api_service
**Funcionalidades**: Streaming en vivo, videoteca

---

### 12. 🛒 MARKETPLACE (Compra/Venta)

**Estructura**:
```
features/marketplace/
├── screens/ (6 pantallas)
│   ├── marketplace_screen.dart
│   ├── publicaciones_tab.dart
│   ├── favoritos_tab.dart
│   ├── mis_publicaciones_tab.dart
│   ├── crear_publicacion_screen.dart
│   └── detalle_publicacion_screen.dart
├── widgets/ (2 widgets)
│   ├── publicacion_card.dart
│   └── foto_carousel.dart
├── services/ (1 servicio)
│   └── marketplace_service.dart
└── providers/ (1 provider)
    └── marketplace_provider.dart
```

**Servicios**: marketplace_service, whatsapp_service
**Modelos**: publicacion_model
**Funcionalidades**: Publicar, comprar, favoritos, contacto

---

### 13. 👤 PERFIL (Usuario)

**Estructura**:
```
features/perfil/
└── screens/ (2 pantallas)
    ├── perfil_screen.dart
    └── perfil_screen_real.dart
```

**Servicios**: auth_service, api_service
**Modelos**: usuario
**Funcionalidades**: Gestión perfil, configuración

---

### 14. 👨‍💼 ADMIN (Administración)

**Estructura**:
```
features/admin/
├── screens/ (6 pantallas)
│   ├── admin_dashboard_screen.dart
│   ├── admin_dashboard_screen_epic.dart
│   ├── admin_transmisiones_screen.dart
│   ├── formulario_coliseo_screen.dart
│   ├── formulario_evento_screen.dart
│   └── gestion_peleas_evento_screen.dart
└── widgets/ (2 widgets)
    ├── cloudinary_image_viewer.dart
    └── pago_detail_card.dart
```

**Servicios**: admin_service, admin_notification_service, pago_service
**Modelos**: pago_models
**Funcionalidades**: Panel admin, usuarios, pagos, eventos

---

## 🔧 Servicios Globales (40+ servicios)

### Autenticación
- auth_service.dart
- firebase_notification_service.dart

### API y Conexión
- api_service.dart
- connection_service.dart
- offline_queue_service.dart

### Gallos
- gallo_service.dart
- gallo_service_v2.dart

### Registros
- peleas_service.dart
- topes_service.dart
- vacunas_service.dart

### Finanzas
- inversion_service.dart
- pago_service.dart
- mercadopago_service.dart
- suscripcion_service.dart

### Archivos y Media
- foto_service.dart
- cloudinary_service.dart
- file_upload_service.dart
- pdf_download_service.dart
- pdf_viewer_service.dart

### Plataforma
- platform_service.dart
- device_service.dart (mobile, web, stub)
- share_service.dart (mobile, web, stub)
- whatsapp_service.dart

---

## 📦 Modelos Globales

```
models/
├── gallo.dart
├── pelea.dart
├── tope.dart
├── vacuna.dart
├── vacuna_model.dart
├── usuario.dart
├── publicacion_model.dart
├── suscripcion_models.dart
└── pago_models.dart
```

---

## 🎨 Componentes Compartidos

### Widgets (15+)
- adaptive_layout_builder.dart
- loading_widget.dart
- error_widget.dart
- limite_interceptor.dart
- video_player_widget.dart
- upgrade_dialog.dart
- gallo_icon.dart
- quick_nav_fab.dart

### Tema
- app_colors.dart
- app_theme.dart

---

## 📊 Estadísticas

- **Screens**: 58 pantallas
- **Widgets Específicos**: 15+
- **Widgets Compartidos**: 15+
- **Servicios**: 40+
- **Modelos**: 12 (9 globales + 3 reportes)
- **Providers**: 1

---

**Documento generado**: 18 de Noviembre, 2025