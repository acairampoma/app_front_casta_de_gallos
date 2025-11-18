# 📋 PLAN DE ACCIÓN - FIXES SISTEMA CASTA DE GALLOS

**Fecha:** 18 de Noviembre 2025  
**Objetivo:** Identificar archivos y APIs para implementar todas las correcciones solicitadas

---

## ✅ 1. MÓDULO DE LOGIN (COMPLETADO)

### 1.1. Título "Casta de Gallos" en registro

**Estado:** ✅ COMPLETADO

**Archivos modificados:**
- `lib/features/auth/screens/login_screen.dart` (línea 1148)

**Cambio realizado:**
```dart
// ANTES: 'Únete a Casta de Reyes'
// AHORA: 'Únete a Casta de Gallos'
```

---

## 🔧 2. MÓDULO DE PEDIGRÍ

### 2.1. Fix múltiples fotos padre/madre en Genealogía

**Problema:** Solo se guarda una foto cuando se seleccionan varias

**Archivos a revisar:**
- ✅ `lib/features/pedigri/screens/edit_gallo_multistep_screen.dart`
- ✅ `lib/features/pedigri/widgets/edit_gallo_dialog.dart`
- ✅ `lib/services/gallo_service.dart`

**APIs Backend a verificar:**
- `PUT /api/v1/gallos/{id}` - Actualizar gallo
- `POST /api/v1/gallos/{id}/fotos` - Subir múltiples fotos
- `PUT /api/v1/gallos/{id}/genealogia` - Actualizar genealogía

**Pasos:**
1. [ ] Buscar función de selección de fotos para padre/madre
2. [ ] Verificar que se envíen todas las fotos seleccionadas al backend
3. [ ] Confirmar que el backend guarda todas las fotos
4. [ ] Probar flujo completo

---

### 2.2. Botón genealogía padre/madre no visible

**Problema:** Botón para activar genealogía no se ve

**Archivos a revisar:**
- ✅ `lib/features/pedigri/screens/edit_gallo_multistep_screen.dart`
- ✅ `lib/features/pedigri/widgets/edit_gallo_dialog.dart`

**Pasos:**
1. [ ] Localizar botón/switch de activación de genealogía
2. [ ] Mejorar contraste y visibilidad (color, tamaño)
3. [ ] Probar en modo claro/oscuro
4. [ ] Verificar responsive mobile/desktop

---

### 2.3. Botón "Mostrar solo gallos principales"

**Problema:** Botón no se visualiza bien (poco contraste)

**Archivos a revisar:**
- ✅ `lib/features/pedigri/screens/pedigri_screen.dart`

**Pasos:**
1. [ ] Localizar botón "Mostrar solo gallos principales"
2. [ ] Mejorar estilo (color, borde, sombra)
3. [ ] Agregar hover/focus states
4. [ ] Probar en diferentes dispositivos

---

### 2.4. Eliminar campo "Propietario actual" en formulario

**Problema:** Campo innecesario en página 2 del formulario de nuevo gallo

**Archivos a revisar:**
- ✅ `lib/features/pedigri/screens/add_gallo_multistep_screen.dart`

**Pasos:**
1. [ ] Localizar página 2 del formulario multistep
2. [ ] Eliminar campo "Propietario actual" del UI
3. [ ] Eliminar validaciones relacionadas
4. [ ] Mantener solo campo "Criador"
5. [ ] Probar flujo de registro completo

---

### 2.5. Cambiar imágenes árbol genealógico

**Problema:** Imágenes de árbol deben reemplazarse

**Archivos a revisar:**
- ✅ `lib/features/pedigri/screens/genealogy_tree_screen.dart`
- ✅ `lib/features/pedigri/screens/pedigri_screen.dart`

**Cambios requeridos:**
1. **Árbol genealógico:** Reemplazar imagen de árbol por imagen de "Padres"
2. **Panel Pedigrí:** Reemplazar imagen de árbol por foto de gallo

**Pasos:**
1. [ ] Localizar assets de imágenes actuales
2. [ ] Identificar imagen usada en sección "Padres"
3. [ ] Reemplazar en genealogy_tree_screen.dart
4. [ ] Agregar/seleccionar imagen de gallo para panel principal
5. [ ] Actualizar referencias en pedigri_screen.dart
6. [ ] Probar carga de imágenes

---

## ⚔️ 3. MÓDULO DE PELEAS

### 3.1. Campo "Dueño" dinámico

**Problema:** Campo viene por defecto con "alan cairampona"

**Archivos a revisar:**
- ✅ `lib/features/peleas/screens/formulario_pelea_screen.dart`
- ✅ `lib/features/peleas/screens/peleas_gallos_screen.dart`

**Pasos:**
1. [ ] Localizar card de datos del gallo en formulario de pelea
2. [ ] Buscar campo "Dueño" hardcodeado
3. [ ] Reemplazar por dato dinámico del galpón/usuario
4. [ ] Si no hay dueño, dejar campo vacío
5. [ ] Probar con diferentes gallos

---

### 3.2. Layout "Mi gallo VS Gallo oponente"

**Problema:** Layout no está organizado claramente

**Archivos a revisar:**
- ✅ `lib/features/peleas/screens/formulario_pelea_screen.dart`

**Diseño esperado:**
```
┌─────────────────────┐
│   MI GALLO (card)   │
│    (horizontal)     │
└─────────────────────┘
         VS
┌─────────────────────┐
│ GALLO OPONENTE      │
│     (card)          │
└─────────────────────┘
```

**Pasos:**
1. [ ] Localizar sección de selección de gallos
2. [ ] Reorganizar layout: Mi gallo arriba, VS centro, Oponente abajo
3. [ ] Ajustar responsive para mobile/desktop
4. [ ] Probar visualmente

---

### 3.3. Campo "Duración" visible

**Problema:** Palabra "minutos" dentro del input, número no se ve

**Archivos a revisar:**
- ✅ `lib/features/peleas/screens/formulario_pelea_screen.dart`

**Pasos:**
1. [ ] Localizar campo "Duración" en resultado del combate
2. [ ] Eliminar texto "minutos" del placeholder/input
3. [ ] Mejorar contraste del valor numérico
4. [ ] Agregar label/sufijo fuera del input si es necesario
5. [ ] Probar ingreso de valores

---

## 💳 4. MÓDULO DE SUSCRIPCIÓN

### 4.1. Botón cancelar suscripción pendiente

**Problema:** No hay forma de cancelar cuando está en estado "pendiente"

**Archivos a revisar:**
- ✅ `lib/features/planes/screens/planes_screen.dart`
- ✅ `lib/features/suscripcion/screens/proceso_pago_screen.dart`
- ✅ `lib/services/suscripcion_service.dart`

**APIs Backend a crear/verificar:**
- `POST /api/v1/suscripciones/{id}/cancelar` - Cancelar suscripción pendiente

**Pasos:**
1. [ ] Localizar widget de suscripción pendiente
2. [ ] Agregar botón "Cancelar suscripción"
3. [ ] Crear/verificar endpoint backend para cancelación
4. [ ] Actualizar estado a "cancelado por usuario"
5. [ ] Actualizar UI después de cancelar
6. [ ] Probar flujo completo

---

## 🛒 5. MÓDULO DE MARKETPLACE (NUEVO)

**Nota:** No se encontró carpeta `marketplace` en features. Posible ubicación alternativa o módulo por crear.

### 5.1. Reorganizar botones favoritos

**Problema:** Botones y chat de favoritos no están bien ordenados

**Archivos a buscar:**
- ❓ `lib/features/marketplace/` (no existe)
- ❓ Posible en `lib/features/inversiones/`

**Pasos:**
1. [ ] Localizar módulo de marketplace/favoritos
2. [ ] Identificar botones de editar y favoritos
3. [ ] Reorganizar layout para mejor UX
4. [ ] Probar en mobile/desktop

---

### 5.2. Quitar info de card al editar

**Problema:** Card muestra demasiada información al editar

**Pasos:**
1. [ ] Localizar card de edición
2. [ ] Identificar información innecesaria
3. [ ] Simplificar card manteniendo solo lo esencial
4. [ ] Probar visualmente

---

## 👨‍💼 6. MÓDULO DE ADMIN

### 6.1. Indicadores por tipo de usuario

**Problema:** Solo muestra 3 tipos, faltan indicadores para:
- Gratuito
- Básico
- Premium
- Profesional

**Archivos a revisar:**
- ✅ `lib/features/admin/screens/admin_dashboard_screen.dart`
- ✅ `lib/features/admin/screens/admin_dashboard_screen_epic.dart`

**APIs Backend a verificar:**
- `GET /api/v1/admin/usuarios/estadisticas` - Estadísticas por tipo de plan

**Pasos:**
1. [ ] Localizar sección de usuarios en admin dashboard
2. [ ] Verificar endpoint que retorna estadísticas
3. [ ] Agregar indicadores para los 4 tipos de plan
4. [ ] Mostrar contadores: Gratuito, Básico, Premium, Profesional
5. [ ] Agregar gráficos/visualización
6. [ ] Probar con datos reales

---

## 📊 RESUMEN DE ARCHIVOS IDENTIFICADOS

### Frontend (Flutter)

**Auth:**
- ✅ `lib/features/auth/screens/login_screen.dart`

**Pedigrí:**
- ✅ `lib/features/pedigri/screens/pedigri_screen.dart`
- ✅ `lib/features/pedigri/screens/add_gallo_multistep_screen.dart`
- ✅ `lib/features/pedigri/screens/edit_gallo_multistep_screen.dart`
- ✅ `lib/features/pedigri/screens/genealogy_tree_screen.dart`
- ✅ `lib/features/pedigri/widgets/edit_gallo_dialog.dart`

**Peleas:**
- ✅ `lib/features/peleas/screens/formulario_pelea_screen.dart`
- ✅ `lib/features/peleas/screens/peleas_gallos_screen.dart`

**Suscripción:**
- ✅ `lib/features/planes/screens/planes_screen.dart`
- ✅ `lib/features/suscripcion/screens/proceso_pago_screen.dart`

**Admin:**
- ✅ `lib/features/admin/screens/admin_dashboard_screen.dart`
- ✅ `lib/features/admin/screens/admin_dashboard_screen_epic.dart`

**Services:**
- ✅ `lib/services/gallo_service.dart`
- ✅ `lib/services/suscripcion_service.dart`

### Backend (APIs a verificar)

**Gallos:**
- `PUT /api/v1/gallos/{id}` - Actualizar gallo
- `POST /api/v1/gallos/{id}/fotos` - Subir múltiples fotos
- `PUT /api/v1/gallos/{id}/genealogia` - Actualizar genealogía

**Suscripciones:**
- `POST /api/v1/suscripciones/{id}/cancelar` - Cancelar suscripción

**Admin:**
- `GET /api/v1/admin/usuarios/estadisticas` - Estadísticas por tipo de plan

---

## 🎯 ORDEN DE IMPLEMENTACIÓN SUGERIDO

### Prioridad ALTA (Crítico)
1. ✅ **1.1** Login: Título corregido (COMPLETADO)
2. **2.1** Pedigrí: Fix múltiples fotos padre/madre
3. **3.1** Peleas: Campo Dueño dinámico
4. **4.1** Suscripción: Botón cancelar pendiente

### Prioridad MEDIA (Importante)
5. **2.4** Pedigrí: Eliminar campo Propietario actual
6. **3.2** Peleas: Layout Mi gallo VS Oponente
7. **3.3** Peleas: Campo Duración visible
8. **6.1** Admin: Indicadores por tipo de usuario

### Prioridad BAJA (Mejoras UX)
9. **2.2** Pedigrí: Botón genealogía visible
10. **2.3** Pedigrí: Botón "Mostrar solo principales"
11. **2.5** Pedigrí: Cambiar imágenes árbol
12. **5.1** Marketplace: Reorganizar botones favoritos
13. **5.2** Marketplace: Quitar info de card editar

---

## ✅ CHECKLIST DE PROGRESO

- [x] 1.1 Login: Título "Casta de Gallos"
- [ ] 2.1 Pedigrí: Fix múltiples fotos padre/madre
- [ ] 2.2 Pedigrí: Botón genealogía visible
- [ ] 2.3 Pedigrí: Botón "Mostrar solo principales"
- [ ] 2.4 Pedigrí: Eliminar campo "Propietario actual"
- [ ] 2.5 Pedigrí: Cambiar imágenes árbol genealógico
- [ ] 3.1 Peleas: Campo Dueño dinámico
- [ ] 3.2 Peleas: Layout Mi gallo VS Oponente
- [ ] 3.3 Peleas: Campo Duración visible
- [ ] 4.1 Suscripción: Botón cancelar pendiente
- [ ] 5.1 Marketplace: Reorganizar botones favoritos
- [ ] 5.2 Marketplace: Quitar info de card editar
- [ ] 6.1 Admin: Indicadores por tipo de usuario
- [ ] Testing completo
- [ ] Documentación actualizada

---

## 📝 NOTAS IMPORTANTES

1. **Marketplace:** No se encontró carpeta específica. Verificar si está en otro módulo.
2. **Backend:** Algunas APIs pueden necesitar crearse o modificarse.
3. **Testing:** Probar cada fix en mobile y desktop.
4. **Commits:** Hacer commits pequeños por cada fix completado.

---

**Última actualización:** 18/11/2025
