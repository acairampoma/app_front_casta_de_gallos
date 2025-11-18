# 💳 Implementación de Mercado Pago Checkout con Yape

## 📋 Resumen Ejecutivo

Se implementó el flujo de pago con **Mercado Pago Checkout** usando Yape como método de pago preferido. El sistema crea una preferencia de pago, abre el checkout (WebView en móvil, navegador en web), y actualiza la suscripción automáticamente vía webhook cuando el pago es aprobado.

---

## 🎯 Problema Original

- Usuario necesitaba pagar con Yape a través de Mercado Pago
- Flujo anterior: QR manual + subida de comprobante + verificación manual (lento)
- Nuevo flujo: Checkout automático de Mercado Pago con activación instantánea vía webhook

---

## 🔧 Solución Implementada

### **Backend (FastAPI)**

#### 1. **Endpoint de Creación de Preferencia**
**Archivo:** `app/api/v1/mercadopago.py`
**Líneas modificadas:** 142-242

**Funcionalidad:**
- Crea preferencia de Mercado Pago con Yape habilitado
- Genera `external_reference` único
- Crea suscripción pendiente en BD
- Retorna `init_point` (URL del checkout)

**Cambios clave:**
```python
@router.post("/pagar-con-yape")
async def pagar_con_yape(
    plan_codigo: str,
    current_user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    # Obtener nombre del usuario (FIX: profile es lista, no objeto)
    user_nombre = "Usuario"
    if usuario.profile and len(usuario.profile) > 0:
        user_nombre = usuario.profile[0].nombre_completo or "Usuario"
    
    # Crear preferencia con Yape
    resultado = mercadopago_service.crear_preferencia_yape(...)
    
    # Crear suscripción pendiente
    nueva_suscripcion = Suscripcion(
        status="pending",
        preference_id=resultado["preference_id"],
        payment_method="yape"
    )
```

**Fix aplicado:**
- **Líneas 181-184:** Corregir acceso a `usuario.profile` (es lista, no objeto único)

---

#### 2. **Servicio de Mercado Pago**
**Archivo:** `app/services/mercadopago_service.py`
**Método agregado:** `crear_preferencia_yape()`

**Funcionalidad:**
- Llama a API de Mercado Pago para crear preferencia
- Configura Yape como método de pago predeterminado
- Configura URLs de redirección (éxito, fallo, pendiente)
- Retorna `init_point` y `preference_id`

---

#### 3. **Webhook de Mercado Pago**
**Archivo:** `app/api/v1/mercadopago.py`
**Líneas:** 248-331

**Funcionalidad:**
- Recibe notificaciones de Mercado Pago cuando cambia estado del pago
- Valida firma del webhook (seguridad)
- Actualiza suscripción a `active` cuando pago es aprobado
- Desactiva suscripciones anteriores del usuario

---

### **Frontend (Flutter)**

#### 1. **Servicio de Mercado Pago**
**Archivo:** `lib/services/mercadopago_service.dart`
**Líneas modificadas:** 84-113

**Cambios clave:**
- **Línea 92-95:** Corregir URL del endpoint (agregar `/api/v1/`)
- Método `crearPreferenciaYape()` para llamar al backend
- Retorna `init_point` para abrir checkout

**Fix aplicado:**
```dart
// ANTES (404 Not Found):
final url = Uri.parse('$baseUrl/mercadopago/pagar-con-yape?plan_codigo=$planCodigo');

// DESPUÉS (✅ Funciona):
final url = Uri.parse('$baseUrl/api/v1/mercadopago/pagar-con-yape?plan_codigo=$planCodigo');
```

---

#### 2. **Pantalla de Proceso de Pago**
**Archivo:** `lib/features/suscripcion/screens/proceso_pago_screen.dart`
**Líneas modificadas:** 1-20, 1262-1382

**Cambios clave:**
- **Líneas 1-20:** Agregar imports (`kIsWeb`, `checkout_webview_screen.dart`)
- **Líneas 1262-1382:** Método `_confirmarPago()` con detección de plataforma:
  - **Móvil:** Abre WebView embebido
  - **Web:** Abre en navegador externo

**Flujo implementado:**
```dart
Future<void> _confirmarPago() async {
  // 1. Crear preferencia en backend
  final resultado = await MercadoPagoService.crearPreferenciaYape(
    planCodigo: widget.plan.codigo,
  );
  
  final initPoint = resultado['init_point'];
  
  // 2. Detectar plataforma
  if (!kIsWeb) {
    // MÓVIL: WebView embebido
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutWebViewScreen(
          checkoutUrl: initPoint,
          planNombre: widget.plan.nombre,
        ),
      ),
    );
    
    // 3. Procesar resultado
    if (result['success'] && result['status'] == 'approved') {
      // Mostrar éxito y navegar
    }
  } else {
    // WEB: Navegador externo
    await launchUrl(Uri.parse(initPoint));
  }
}
```

---

#### 3. **Pantalla de WebView para Checkout**
**Archivo:** `lib/features/suscripcion/screens/checkout_webview_screen.dart`
**Líneas:** 1-165 (archivo nuevo)

**Funcionalidad:**
- WebView embebido para mostrar checkout de Mercado Pago
- Detecta redirecciones automáticamente:
  - `/pago-exitoso` → Retorna `{success: true, status: 'approved'}`
  - `/pago-fallido` → Retorna `{success: false, status: 'rejected'}`
  - `/pago-pendiente` → Retorna `{success: false, status: 'pending'}`
- Botón de cancelar con confirmación
- Loading indicator mientras carga

**Características:**
```dart
void _checkForRedirect(String url) {
  if (url.contains('/pago-exitoso')) {
    Navigator.of(context).pop({'success': true, 'status': 'approved'});
  } else if (url.contains('/pago-fallido')) {
    Navigator.of(context).pop({'success': false, 'status': 'rejected'});
  } else if (url.contains('/pago-pendiente')) {
    Navigator.of(context).pop({'success': false, 'status': 'pending'});
  }
}
```

---

## 📁 Archivos Modificados/Creados

### **Backend**
| Archivo | Ruta Completa | Cambios |
|---------|---------------|---------|
| `mercadopago.py` | `app/api/v1/mercadopago.py` | Endpoint `/pagar-con-yape` (líneas 142-242), Fix profile (líneas 181-184) |
| `mercadopago_service.py` | `app/services/mercadopago_service.py` | Método `crear_preferencia_yape()` |

### **Frontend**
| Archivo | Ruta Completa | Cambios |
|---------|---------------|---------|
| `mercadopago_service.dart` | `lib/services/mercadopago_service.dart` | Fix URL endpoint (líneas 92-95), método `crearPreferenciaYape()` (líneas 84-113) |
| `proceso_pago_screen.dart` | `lib/features/suscripcion/screens/proceso_pago_screen.dart` | Imports (líneas 1-20), método `_confirmarPago()` (líneas 1262-1382) |
| `checkout_webview_screen.dart` | `lib/features/suscripcion/screens/checkout_webview_screen.dart` | **NUEVO ARCHIVO** - WebView embebido (165 líneas) |

---

## 🐛 Bugs Corregidos

### **Bug 1: 404 Not Found**
**Causa:** URL del endpoint sin prefijo `/api/v1/`
**Archivo:** `lib/services/mercadopago_service.dart` (línea 92)
**Fix:**
```dart
// ANTES:
'$baseUrl/mercadopago/pagar-con-yape'

// DESPUÉS:
'$baseUrl/api/v1/mercadopago/pagar-con-yape'
```

### **Bug 2: 500 Internal Server Error**
**Causa:** `usuario.profile` es lista, no objeto único
**Archivo:** `app/api/v1/mercadopago.py` (línea 188)
**Fix:**
```python
# ANTES:
user_nombre = usuario.profile.nombre_completo if usuario.profile else "Usuario"

# DESPUÉS:
user_nombre = "Usuario"
if usuario.profile and len(usuario.profile) > 0:
    user_nombre = usuario.profile[0].nombre_completo or "Usuario"
```

### **Bug 3: Deployment no automático**
**Causa:** Railway configurado para escuchar `main`, pero cambios en `privacy-manifest-fix`
**Fix:** Cambiar Railway para escuchar branch `privacy-manifest-fix`

---

## 🔄 Flujo Completo

```
1. Usuario selecciona plan → Click "Pagar con Yape"
   ↓
2. Frontend llama: POST /api/v1/mercadopago/pagar-con-yape?plan_codigo=basico
   ↓
3. Backend crea preferencia en Mercado Pago
   ↓
4. Backend crea suscripción pendiente en BD
   ↓
5. Backend retorna init_point (URL del checkout)
   ↓
6. Frontend detecta plataforma:
   - MÓVIL: Abre WebView embebido
   - WEB: Abre navegador externo
   ↓
7. Usuario completa pago en Mercado Pago
   ↓
8. Mercado Pago redirige a /pago-exitoso o /pago-fallido
   ↓
9. WebView detecta redirección y cierra automáticamente
   ↓
10. Mercado Pago envía webhook al backend
   ↓
11. Backend actualiza suscripción a "active"
   ↓
12. Usuario ve su suscripción activada
```

---

## ⚠️ Consideraciones Importantes

### **Yape en Sandbox vs Producción**
- ❌ **Yape NO funciona en modo TEST/SANDBOX** de Mercado Pago
- ✅ **Para testing:** Usar tarjetas de prueba de Mercado Pago
- ✅ **Para producción:** Activar cuenta de Mercado Pago en modo producción

### **Tarjetas de Prueba**
```
APROBADA:
Número: 5031 7557 3453 0604
CVV: 123
Vencimiento: 11/25
Nombre: APRO

RECHAZADA:
Número: 5031 4332 1540 6351
CVV: 123
Vencimiento: 11/25
Nombre: OTHE
```

### **Webhook**
- URL debe ser HTTPS
- Mercado Pago valida firma del webhook
- Configurar en: Mercado Pago Dashboard → Webhooks

---

## 🚀 Deployment

### **Backend**
- Branch: `main`
- Railway detecta cambios automáticamente
- Redeploy: ~2-3 minutos

### **Frontend**
- Branch: `privacy-manifest-fix`
- Railway ejecuta `flutter build web --release`
- Redeploy: ~3-5 minutos

---

## ✅ Testing

### **Web**
1. Abrir app en navegador
2. Seleccionar plan → "Pagar con Yape"
3. Se abre nueva pestaña con checkout
4. Usar tarjeta de prueba
5. Verificar redirección y activación

### **Móvil**
1. Abrir app en dispositivo/emulador
2. Seleccionar plan → "Pagar con Yape"
3. Se abre WebView embebido
4. Usar tarjeta de prueba
5. WebView se cierra automáticamente
6. Verificar mensaje de éxito y activación

---

## 📊 Estado del Proyecto

- ✅ Backend: Endpoint y webhook implementados
- ✅ Frontend: WebView embebido en móvil, navegador en web
- ✅ Bugs corregidos: URL 404, profile error
- ✅ Deployment: Configurado en Railway
- ⏳ Pendiente: Testing completo en producción con Yape real

---

## 👥 Revisión Senior

**Puntos a revisar:**
1. ¿La estructura del código es óptima?
2. ¿Hay mejores prácticas que deberíamos seguir?
3. ¿El manejo de errores es suficiente?
4. ¿La seguridad del webhook es adecuada?
5. ¿El flujo UX es el mejor para el usuario?

---

**Fecha:** 18 de Noviembre, 2025  
**Desarrollador:** Cascade AI + acairampoma  
**Estado:** ✅ Implementado y funcional en TEST
