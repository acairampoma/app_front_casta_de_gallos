# 🔗 Matriz de Dependencias entre Módulos

## 📊 Tabla de Dependencias Completa

| Módulo | Screens | Widgets | Servicios Propios | Servicios Externos | Modelos | Providers |
|--------|---------|---------|-------------------|-------------------|---------|-----------|
| **Auth** | 5 | 0 | 0 | auth_service, firebase_notification_service | usuario | 0 |
| **Home** | 1 | 0 | 0 | connection_service, auth_service, suscripcion_service | usuario, suscripcion_models | 0 |
| **Pedigri** | 4 | 3 | 0 | gallo_service_v2, foto_service, cloudinary_service | gallo | 0 |
| **Peleas** | 5 | 0 | 0 | peleas_service, gallo_service | pelea, gallo | 0 |
| **Topes** | 5 | 0 | 0 | topes_service, gallo_service | tope, gallo | 0 |
| **Vacunas** | 4 | 1 | 0 | vacunas_service, gallo_service | vacuna, gallo | 0 |
| **Inversiones** | 1 | 2 | 0 | inversion_service, gallo_service | gallo | 0 |
| **Reportes** | 1 | 5 | reportes_service | pdf_download_service, pdf_viewer_service | dashboard_model, rankings_model, documentos_model | 0 |
| **Planes** | 1 | 2 | 0 | suscripcion_service, pago_service | suscripcion_models | 0 |
| **Suscripcion** | 5 | 0 | 0 | suscripcion_service, pago_service, mercadopago_service | suscripcion_models, pago_models | 0 |
| **Transmisiones** | 3 | 0 | 0 | api_service | - | 0 |
| **Marketplace** | 6 | 2 | marketplace_service | whatsapp_service, gallo_service | publicacion_model, gallo | marketplace_provider |
| **Perfil** | 2 | 0 | 0 | auth_service, api_service | usuario | 0 |
| **Admin** | 6 | 2 | 0 | admin_service, admin_notification_service, pago_service | pago_models | 0 |

---

## 🔄 Flujo de Dependencias por Capa

### Capa de Servicios

```
Servicios Core (Usados por múltiples módulos):
├── auth_service.dart → [Auth, Home, Perfil]
├── gallo_service.dart → [Pedigri, Peleas, Topes, Vacunas, Inversiones, Marketplace]
├── api_service.dart → [Transmisiones, Perfil, Admin]
├── connection_service.dart → [Home]
└── suscripcion_service.dart → [Home, Planes, Suscripcion]

Servicios Específicos (Usados por un módulo):
├── peleas_service.dart → [Peleas]
├── topes_service.dart → [Topes]
├── vacunas_service.dart → [Vacunas]
├── inversion_service.dart → [Inversiones]
├── reportes_service.dart → [Reportes]
├── marketplace_service.dart → [Marketplace]
├── admin_service.dart → [Admin]
├── pago_service.dart → [Planes, Suscripcion, Admin]
└── mercadopago_service.dart → [Suscripcion]

Servicios de Soporte:
├── foto_service.dart → [Pedigri]
├── cloudinary_service.dart → [Pedigri, Admin]
├── whatsapp_service.dart → [Marketplace]
├── pdf_download_service.dart → [Reportes]
├── pdf_viewer_service.dart → [Reportes]
└── firebase_notification_service.dart → [Auth, Admin]
```

### Capa de Modelos

```
Modelos Compartidos:
├── usuario.dart → [Auth, Home, Perfil]
├── gallo.dart → [Pedigri, Peleas, Topes, Vacunas, Inversiones, Marketplace]
├── suscripcion_models.dart → [Home, Planes, Suscripcion]
└── pago_models.dart → [Suscripcion, Admin]

Modelos Específicos:
├── pelea.dart → [Peleas]
├── tope.dart → [Topes]
├── vacuna.dart → [Vacunas]
├── publicacion_model.dart → [Marketplace]
├── dashboard_model.dart → [Reportes]
├── rankings_model.dart → [Reportes]
└── documentos_model.dart → [Reportes]
```

---

## 🎯 Análisis de Acoplamiento

### Módulos con BAJO Acoplamiento (Independientes)
- **Auth**: Solo depende de servicios de autenticación
- **Transmisiones**: Solo usa api_service
- **Perfil**: Mínimas dependencias

### Módulos con MEDIO Acoplamiento
- **Home**: Depende de varios servicios pero no de otros módulos
- **Planes**: Depende de servicios de suscripción
- **Suscripcion**: Depende de servicios de pago
- **Admin**: Depende de servicios admin y pago

### Módulos con ALTO Acoplamiento (Dependen de Gallos)
- **Pedigri**: Core del sistema
- **Peleas**: Depende fuertemente de gallos
- **Topes**: Depende fuertemente de gallos
- **Vacunas**: Depende fuertemente de gallos
- **Inversiones**: Depende de gallos
- **Marketplace**: Depende de gallos y sus datos

### Módulos Complejos (Múltiples Dependencias)
- **Reportes**: Usa datos de múltiples módulos
- **Marketplace**: Integra gallos + publicaciones + comunicación

---

## 📈 Dependencias de Widgets Compartidos

```
Widgets Compartidos más usados:

loading_widget.dart → [Todos los módulos]
error_widget.dart → [Todos los módulos]
adaptive_layout_builder.dart → [Home, Pedigri, Reportes]
limite_interceptor.dart → [Peleas, Topes, Vacunas, Marketplace]
gallo_icon.dart → [Home, Pedigri, Peleas, Topes, Vacunas]
video_player_widget.dart → [Transmisiones]
upgrade_dialog.dart → [Planes, Suscripcion]
```

---

## 🔑 Módulos Críticos (Core del Sistema)

### 1. **Pedigri** (Más crítico)
- Base de todo el sistema
- Todos los módulos de registros dependen de él
- Gestiona la entidad principal: Gallo

### 2. **Auth** (Crítico)
- Punto de entrada al sistema
- Gestiona seguridad y acceso

### 3. **Suscripcion/Planes** (Crítico)
- Controla límites de uso
- Afecta funcionalidad de todos los módulos

### 4. **Home** (Importante)
- Hub de navegación
- Punto central de acceso

---

## 🛠️ Recomendaciones de Arquitectura

### ✅ Buenas Prácticas Actuales
1. **Feature-First**: Módulos bien organizados en features/
2. **Separación de Concerns**: Screens, widgets, services separados
3. **Servicios Compartidos**: Servicios globales reutilizables
4. **Modelos Compartidos**: Modelos accesibles desde cualquier módulo

### 🔄 Mejoras Sugeridas

#### 1. Mover Servicios Específicos a Features
```
Actual:
services/peleas_service.dart

Sugerido:
features/peleas/services/peleas_service.dart
```

**Beneficios**:
- Mayor cohesión
- Más fácil de mantener
- Mejor encapsulación

**Aplicar a**:
- peleas_service → features/peleas/services/
- topes_service → features/topes/services/
- vacunas_service → features/vacunas/services/
- inversion_service → features/inversiones/services/

#### 2. Crear Providers por Módulo
```
Sugerido:
features/peleas/providers/peleas_provider.dart
features/topes/providers/topes_provider.dart
features/vacunas/providers/vacunas_provider.dart
```

**Beneficios**:
- Mejor gestión de estado
- Menos props drilling
- Estado reactivo

#### 3. Mover Modelos Específicos a Features
```
Actual:
models/pelea.dart

Sugerido:
features/peleas/models/pelea_model.dart
```

**Aplicar a**:
- pelea → features/peleas/models/
- tope → features/topes/models/
- vacuna → features/vacunas/models/

**Mantener Globales**:
- gallo.dart (usado por muchos módulos)
- usuario.dart (usado por muchos módulos)
- suscripcion_models.dart (usado por muchos módulos)

---

## 📊 Impacto de Cambios

### Si se modifica GALLO
**Módulos Afectados**: 6 módulos
- Pedigri ⚠️ Alto impacto
- Peleas ⚠️ Alto impacto
- Topes ⚠️ Alto impacto
- Vacunas ⚠️ Alto impacto
- Inversiones ⚠️ Medio impacto
- Marketplace ⚠️ Alto impacto

### Si se modifica USUARIO
**Módulos Afectados**: 3 módulos
- Auth ⚠️ Alto impacto
- Home ⚠️ Medio impacto
- Perfil ⚠️ Alto impacto

### Si se modifica SUSCRIPCION
**Módulos Afectados**: 3 módulos + límites en todos
- Home ⚠️ Medio impacto
- Planes ⚠️ Alto impacto
- Suscripcion ⚠️ Alto impacto
- Todos los módulos (límites) ⚠️ Bajo impacto

---

## 🎯 Conclusiones

### Fortalezas
✅ Arquitectura clara y organizada
✅ Separación de responsabilidades
✅ Reutilización de componentes
✅ Marketplace bien estructurado (ejemplo a seguir)

### Áreas de Mejora
🔄 Mover servicios específicos a features
🔄 Implementar providers por módulo
🔄 Reducir acoplamiento con gallo.dart
🔄 Documentar APIs de servicios

### Prioridades
1. **Alta**: Mantener estructura actual de Marketplace como estándar
2. **Media**: Migrar servicios específicos a features
3. **Baja**: Crear providers adicionales según necesidad

---

**Documento generado**: 18 de Noviembre, 2025
**Última actualización**: Reorganización de Marketplace completada
