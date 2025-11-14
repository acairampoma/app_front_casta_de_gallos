# 📧 Email Verification Flow - Testing Guide

## Overview
Este documento describe cómo probar el flujo completo de verificación de email en la aplicación Casta de Gallos.

## Flujo Esperado

```
1. Usuario se registra
   ↓
2. Backend crea usuario y envía email con código
   ↓
3. Frontend navega a EmailVerificationScreen
   ↓
4. Usuario ingresa código de 6 dígitos
   ↓
5. Backend verifica código
   ↓
6. Frontend hace auto-login
   ↓
7. Usuario ve HomeScreen
```

## Test Cases

### Test 1: Registro Exitoso
**Objetivo:** Verificar que el registro funciona y navega a la pantalla de verificación

**Pasos:**
1. Abre el frontend en `http://localhost:59713` o Railway
2. Haz clic en "Crear Cuenta"
3. Completa el formulario:
   - **Email:** `test@jsinnovatech.com`
   - **Nombre Completo:** `Test User`
   - **Contraseña:** `Test123!@`
   - **Confirmar Contraseña:** `Test123!@`
4. Haz clic en "Crear Cuenta"

**Resultado Esperado:**
- ✅ Se muestra SnackBar: "✅ ¡Cuenta creada exitosamente!"
- ✅ Se navega a `EmailVerificationScreen`
- ✅ Se muestra mensaje: "Verifica tu email: test@jsinnovatech.com"

**Si falla:**
- Revisa la consola del navegador (F12)
- Busca el error exacto
- Verifica que el backend está corriendo

---

### Test 2: Email Recibido
**Objetivo:** Verificar que el email llega correctamente

**Pasos:**
1. Después de registrarse, revisa tu email en `test@jsinnovatech.com`
2. Busca un email de "noreply@jsinnovatech.com" o similar
3. Copia el código de 6 dígitos

**Resultado Esperado:**
- ✅ Email recibido en menos de 30 segundos
- ✅ Contiene un código de 6 dígitos
- ✅ Formato: "Tu código de verificación es: XXXXXX"

**Si no llega:**
- Revisa spam/junk
- Verifica que el SMTP está configurado en el backend
- Revisa los logs del backend

---

### Test 3: Verificación de Código
**Objetivo:** Verificar que el código se valida correctamente

**Pasos:**
1. En `EmailVerificationScreen`, ingresa el código de 6 dígitos
2. Los campos se llenan automáticamente
3. Haz clic en "Verificar Email"

**Resultado Esperado:**
- ✅ Se muestra loading mientras se verifica
- ✅ Si el código es correcto: Se hace auto-login
- ✅ Se navega a `HomeScreen`
- ✅ Se muestra el usuario logueado

**Si falla:**
- Verifica que ingresaste el código correcto
- Intenta reenviar el código (botón "Reenviar Código")
- Revisa los logs del backend

---

### Test 4: Reenviar Código
**Objetivo:** Verificar que se puede reenviar el código

**Pasos:**
1. En `EmailVerificationScreen`, haz clic en "Reenviar Código"
2. Espera a que se complete (debería mostrar un timer de 2 minutos)
3. Revisa tu email nuevamente

**Resultado Esperado:**
- ✅ Se muestra mensaje: "Código reenviado exitosamente"
- ✅ Llega un nuevo email con un nuevo código
- ✅ El nuevo código funciona para verificar

**Si falla:**
- Espera a que expire el timer de 2 minutos
- Revisa los logs del backend

---

### Test 5: Código Inválido
**Objetivo:** Verificar que se rechaza un código incorrecto

**Pasos:**
1. En `EmailVerificationScreen`, ingresa un código incorrecto (ej: 000000)
2. Haz clic en "Verificar Email"

**Resultado Esperado:**
- ✅ Se muestra error: "Código inválido o expirado"
- ✅ Se anima el error (shake animation)
- ✅ Los campos se limpian
- ✅ Se puede intentar nuevamente

**Si falla:**
- Verifica que el backend rechaza códigos inválidos
- Revisa los logs

---

### Test 6: Timeout de Código
**Objetivo:** Verificar que el código expira después de cierto tiempo

**Pasos:**
1. Registra un usuario
2. Espera 15 minutos sin verificar
3. Intenta verificar con el código original

**Resultado Esperado:**
- ✅ Se muestra error: "Código inválido o expirado"
- ✅ Se puede reenviar el código

**Nota:** Este test es opcional y toma mucho tiempo

---

## Validaciones del Frontend

### Email Validator
```dart
// Validaciones implementadas:
- ✅ Email no vacío
- ✅ Longitud mínima (5 caracteres)
- ✅ Longitud máxima (254 caracteres)
- ✅ Formato válido (regex RFC 5322)
- ✅ Sin espacios
- ✅ Sin puntos consecutivos
```

### Código Validator
```dart
// Validaciones implementadas:
- ✅ Exactamente 6 dígitos
- ✅ Solo números
- ✅ No vacío
```

---

## Endpoints Utilizados

### Backend
```
POST /auth/register
  - Body: { email, password, nombreCompleto, telefono?, nombreGalpon? }
  - Response: { success, user, token }

POST /auth/verify-email
  - Body: { email, code }
  - Response: { success, message }

POST /auth/resend-verification
  - Body: { email }
  - Response: { success, message }

POST /auth/login
  - Body: { email, password }
  - Response: { success, user, token }
```

---

## Debugging

### Ver logs del frontend
1. Abre DevTools (F12)
2. Ve a la pestaña "Console"
3. Busca logs con emojis (🚀, ✅, ❌, 📧)

### Ver logs del backend
1. Ve a Railway dashboard
2. Selecciona el proyecto del backend
3. Ve a "Deployments" → "Logs"

### Limpiar estado
```dart
// Si algo queda en mal estado:
1. Limpia caché del navegador (Ctrl+Shift+Delete)
2. Cierra y reabre el navegador
3. Intenta nuevamente
```

---

## Checklist Final

- [ ] Registro funciona
- [ ] Email llega correctamente
- [ ] Código se verifica correctamente
- [ ] Auto-login funciona
- [ ] Usuario ve HomeScreen
- [ ] Reenviar código funciona
- [ ] Código inválido muestra error
- [ ] Validaciones de email funcionan
- [ ] Validaciones de código funcionan

---

## Notas

- El código expira después de 15 minutos (configurable en backend)
- El timer de reenvío es de 2 minutos
- Los emails se envían desde `noreply@jsinnovatech.com`
- El frontend está optimizado para web y móvil

---

**Última actualización:** 14/11/2025
**Versión:** 1.0
