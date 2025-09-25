# 📺 API DE TRANSMISIONES - GUÍA COMPLETA CON CURLS

Sistema completo de transmisiones de gallos con streaming de Kick.com integrado.

## 🔗 BASE URL
```
https://gallerappback-production.up.railway.app
```

## 🔐 AUTENTICACIÓN

### 1. Login y Obtener Token JWT
```bash
curl -X POST "https://gallerappback-production.up.railway.app/auth/login" \
-H "Content-Type: application/json" \
-d '{
  "email": "alancairampoma@gmail.com",
  "password": "M@tias252610"
}'
```

**Respuesta:**
```json
{
  "user": {
    "id": 25,
    "email": "alancairampoma@gmail.com",
    "es_admin": true
  },
  "token": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "token_type": "bearer"
  },
  "message": "Bienvenido Alan Cairampoma"
}
```

⚠️ **IMPORTANTE**: Guarda el `access_token` para usar en todos los endpoints siguientes.

---

## 📋 ENDPOINTS PÚBLICOS (USUARIOS NORMALES)

### 2. Listar Coliseos
```bash
curl -X GET "https://gallerappback-production.up.railway.app/api/v1/transmisiones/coliseos" \
-H "Authorization: Bearer TU_ACCESS_TOKEN"
```

**Parámetros opcionales:**
- `activo=true` - Solo coliseos activos (por defecto true)

**Respuesta:**
```json
[
  {
    "id": 1,
    "nombre": "Coliseo Los Gallos de Oro",
    "ciudad": "Lima",
    "departamento": "Lima",
    "aforo_maximo": 500,
    "tipo_coliseo": "local",
    "activo": true
  }
]
```

### 3. Listar Eventos con Paginación
```bash
curl -X GET "https://gallerappback-production.up.railway.app/api/v1/transmisiones/eventos?pagina=1&por_pagina=10" \
-H "Authorization: Bearer TU_ACCESS_TOKEN"
```

**Parámetros opcionales:**
- `pagina=1` - Número de página (por defecto 1)
- `por_pagina=10` - Eventos por página (máximo 50)
- `coliseo_id=1` - Filtrar por coliseo específico
- `fecha=2025-01-20` - Filtrar por fecha (YYYY-MM-DD)
- `estado=programado` - Filtrar por estado (programado, en_vivo, finalizado, cancelado)
- `solo_hoy=true` - Solo eventos de hoy

**Respuesta:**
```json
{
  "eventos": [
    {
      "id": 11,
      "titulo": "Evento Test API Claude",
      "descripcion": "Evento de prueba creado via API",
      "fecha_evento": "2025-12-25T19:00:00",
      "url_transmision": "https://player.kick.com/test_claude_api",
      "estado": "en_vivo",
      "tipo_evento": "local",
      "precio_entrada": "20.00",
      "es_premium": false,
      "coliseo": {
        "id": 8,
        "nombre": "Coliseo Test API Claude",
        "ciudad": "Lima"
      }
    }
  ],
  "total": 11,
  "pagina": 1,
  "por_pagina": 10,
  "total_paginas": 2
}
```

### 4. Eventos de Hoy
```bash
curl -X GET "https://gallerappback-production.up.railway.app/api/v1/transmisiones/eventos/hoy" \
-H "Authorization: Bearer TU_ACCESS_TOKEN"
```

### 5. Detalle de Evento Específico
```bash
curl -X GET "https://gallerappback-production.up.railway.app/api/v1/transmisiones/eventos/11" \
-H "Authorization: Bearer TU_ACCESS_TOKEN"
```

**Respuesta:**
```json
{
  "id": 11,
  "titulo": "Evento Test API Claude",
  "descripcion": "Evento de prueba creado via API para probar transmisiones",
  "fecha_evento": "2025-12-25T19:00:00",
  "fecha_fin_evento": "2025-12-25T22:00:00",
  "url_transmision": "https://player.kick.com/test_claude_api",
  "estado": "en_vivo",
  "tipo_evento": "local",
  "precio_entrada": "20.00",
  "es_premium": false,
  "admin_creador_id": 25,
  "coliseo": {
    "id": 8,
    "nombre": "Coliseo Test API Claude",
    "direccion": "Av. Prueba 456, San Martin de Porres",
    "ciudad": "Lima",
    "departamento": "Lima",
    "aforo_maximo": 300,
    "tipo_coliseo": "local",
    "activo": true
  }
}
```

---

## 👨‍💼 ENDPOINTS ADMIN (SOLO ADMINISTRADORES)

⚠️ **REQUIERE**: Usuario con `es_admin: true`

### 6. Crear Coliseo
```bash
curl -X POST "https://gallerappback-production.up.railway.app/api/v1/transmisiones/admin/coliseos" \
-H "Authorization: Bearer TU_ACCESS_TOKEN" \
-H "Content-Type: application/json" \
-d '{
  "nombre": "Nuevo Coliseo Ejemplo",
  "ciudad": "Lima",
  "direccion": "Av. Ejemplo 123, Distrito",
  "departamento": "Lima",
  "tipo_coliseo": "local",
  "aforo_maximo": 400,
  "descripcion": "Descripción del nuevo coliseo",
  "telefono": "123456789",
  "email": "contacto@coliseo.com"
}'
```

**Tipos de coliseo válidos:** `local`, `grande`, `especial`

### 7. Actualizar Coliseo
```bash
curl -X PUT "https://gallerappback-production.up.railway.app/api/v1/transmisiones/admin/coliseos/8" \
-H "Authorization: Bearer TU_ACCESS_TOKEN" \
-H "Content-Type: application/json" \
-d '{
  "nombre": "Coliseo Actualizado",
  "aforo_maximo": 500,
  "activo": true
}'
```

### 8. Crear Evento
```bash
curl -X POST "https://gallerappback-production.up.railway.app/api/v1/transmisiones/admin/eventos" \
-H "Authorization: Bearer TU_ACCESS_TOKEN" \
-H "Content-Type: application/json" \
-d '{
  "coliseo_id": 8,
  "titulo": "Nuevo Evento de Transmisión",
  "descripcion": "Descripción del evento",
  "fecha_evento": "2025-12-30T20:00:00",
  "fecha_fin_evento": "2025-12-30T23:00:00",
  "url_transmision": "https://player.kick.com/mi_canal",
  "estado": "programado",
  "tipo_evento": "local",
  "precio_entrada": 25.00,
  "es_premium": false,
  "thumbnail_url": "https://ejemplo.com/imagen.jpg"
}'
```

**Estados válidos:** `programado`, `en_vivo`, `finalizado`, `cancelado`
**Tipos de evento válidos:** `local`, `grande`, `especial`

### 9. Actualizar Evento
```bash
curl -X PUT "https://gallerappback-production.up.railway.app/api/v1/transmisiones/admin/eventos/11" \
-H "Authorization: Bearer TU_ACCESS_TOKEN" \
-H "Content-Type: application/json" \
-d '{
  "titulo": "Evento Actualizado",
  "precio_entrada": 30.00,
  "es_premium": true
}'
```

### 10. Cambiar Estado de Evento
```bash
curl -X PUT "https://gallerappback-production.up.railway.app/api/v1/transmisiones/admin/eventos/11/estado?estado=en_vivo" \
-H "Authorization: Bearer TU_ACCESS_TOKEN"
```

**Estados disponibles:**
- `programado` - Evento programado para el futuro
- `en_vivo` - Evento transmitiendo en vivo
- `finalizado` - Evento terminado
- `cancelado` - Evento cancelado

### 11. Estadísticas del Sistema
```bash
curl -X GET "https://gallerappback-production.up.railway.app/api/v1/transmisiones/admin/estadisticas" \
-H "Authorization: Bearer TU_ACCESS_TOKEN"
```

**Respuesta:**
```json
{
  "total_eventos": 11,
  "eventos_hoy": 0,
  "eventos_en_vivo": 2,
  "eventos_programados": 8,
  "total_coliseos": 8,
  "coliseos_activos": 8
}
```

---

## 🔄 FLUJOS DE TRABAJO RECOMENDADOS

### Flujo 1: Usuario Normal Viendo Transmisiones
```bash
# 1. Login
curl -X POST "https://gallerappback-production.up.railway.app/auth/login" \
-H "Content-Type: application/json" \
-d '{"email": "usuario@ejemplo.com", "password": "password"}'

# 2. Ver eventos disponibles
curl -X GET "https://gallerappback-production.up.railway.app/api/v1/transmisiones/eventos" \
-H "Authorization: Bearer TOKEN"

# 3. Ver eventos en vivo
curl -X GET "https://gallerappback-production.up.railway.app/api/v1/transmisiones/eventos?estado=en_vivo" \
-H "Authorization: Bearer TOKEN"

# 4. Ver detalle de evento específico
curl -X GET "https://gallerappback-production.up.railway.app/api/v1/transmisiones/eventos/11" \
-H "Authorization: Bearer TOKEN"
```

### Flujo 2: Admin Gestionando Eventos
```bash
# 1. Login como admin
curl -X POST "https://gallerappback-production.up.railway.app/auth/login" \
-H "Content-Type: application/json" \
-d '{"email": "admin@ejemplo.com", "password": "password"}'

# 2. Ver estadísticas
curl -X GET "https://gallerappback-production.up.railway.app/api/v1/transmisiones/admin/estadisticas" \
-H "Authorization: Bearer TOKEN"

# 3. Crear nuevo coliseo
curl -X POST "https://gallerappback-production.up.railway.app/api/v1/transmisiones/admin/coliseos" \
-H "Authorization: Bearer TOKEN" \
-H "Content-Type: application/json" \
-d '{"nombre": "Nuevo Coliseo", "ciudad": "Lima", "tipo_coliseo": "local"}'

# 4. Crear evento
curl -X POST "https://gallerappback-production.up.railway.app/api/v1/transmisiones/admin/eventos" \
-H "Authorization: Bearer TOKEN" \
-H "Content-Type: application/json" \
-d '{"coliseo_id": 1, "titulo": "Nuevo Evento", "fecha_evento": "2025-12-25T20:00:00", "url_transmision": "https://player.kick.com/canal"}'

# 5. Iniciar transmisión en vivo
curl -X PUT "https://gallerappback-production.up.railway.app/api/v1/transmisiones/admin/eventos/ID/estado?estado=en_vivo" \
-H "Authorization: Bearer TOKEN"

# 6. Finalizar evento
curl -X PUT "https://gallerappback-production.up.railway.app/api/v1/transmisiones/admin/eventos/ID/estado?estado=finalizado" \
-H "Authorization: Bearer TOKEN"
```

### Flujo 3: Búsqueda y Filtrado
```bash
# Eventos de un coliseo específico
curl -X GET "https://gallerappback-production.up.railway.app/api/v1/transmisiones/eventos?coliseo_id=1" \
-H "Authorization: Bearer TOKEN"

# Eventos de una fecha específica
curl -X GET "https://gallerappback-production.up.railway.app/api/v1/transmisiones/eventos?fecha=2025-12-25" \
-H "Authorization: Bearer TOKEN"

# Solo eventos premium
curl -X GET "https://gallerappback-production.up.railway.app/api/v1/transmisiones/eventos" \
-H "Authorization: Bearer TOKEN" \
| jq '.eventos[] | select(.es_premium == true)'

# Eventos por tipo de coliseo
curl -X GET "https://gallerappback-production.up.railway.app/api/v1/transmisiones/coliseos" \
-H "Authorization: Bearer TOKEN" \
| jq '.[] | select(.tipo_coliseo == "especial")'
```

---

## 🎯 CÓDIGOS DE RESPUESTA

| Código | Descripción | Cuándo ocurre |
|--------|-------------|---------------|
| 200 | OK | Operación exitosa |
| 201 | Created | Recurso creado exitosamente |
| 400 | Bad Request | Datos inválidos o faltantes |
| 401 | Unauthorized | Token JWT inválido o expirado |
| 403 | Forbidden | Sin permisos de admin |
| 404 | Not Found | Recurso no encontrado |
| 422 | Validation Error | Error de validación Pydantic |
| 500 | Internal Server Error | Error del servidor |

---

## 🔧 CASOS DE USO ESPECÍFICOS

### Integración con Kick.com
```bash
# Crear evento con URL de Kick.com válida
curl -X POST "https://gallerappback-production.up.railway.app/api/v1/transmisiones/admin/eventos" \
-H "Authorization: Bearer TOKEN" \
-H "Content-Type: application/json" \
-d '{
  "coliseo_id": 1,
  "titulo": "Transmisión en Vivo Kick.com",
  "fecha_evento": "2025-12-25T20:00:00",
  "url_transmision": "https://player.kick.com/tu_canal_real",
  "estado": "programado"
}'
```

### Eventos Premium vs Gratuitos
```bash
# Evento gratuito
-d '{"es_premium": false, "precio_entrada": 0}'

# Evento premium
-d '{"es_premium": true, "precio_entrada": 50.00}'
```

### Manejo de Estados en Tiempo Real
```bash
# Secuencia típica de estados de un evento:
# programado → en_vivo → finalizado

# 1. Crear como programado
curl -X POST "..." -d '{"estado": "programado"}'

# 2. Iniciar transmisión
curl -X PUT ".../eventos/ID/estado?estado=en_vivo"

# 3. Finalizar evento
curl -X PUT ".../eventos/ID/estado?estado=finalizado"
```

---

## 🚨 ERRORES COMUNES

### Error 403: Acceso Denegado
```json
{"detail": "Acceso denegado. Solo administradores."}
```
**Solución**: Verificar que el usuario tenga `es_admin: true`

### Error 400: Coliseo No Encontrado
```json
{"detail": "Coliseo no encontrado"}
```
**Solución**: Verificar que el `coliseo_id` existe y está activo

### Error 422: Estado Inválido
```json
{"detail": "Estado debe ser uno de: ['programado', 'en_vivo', 'finalizado', 'cancelado']"}
```
**Solución**: Usar solo estados válidos

---

## 📱 INTEGRACIÓN FRONTEND

### Flutter WebView para Kick.com
```dart
// Usar la URL del evento directamente en WebView
WebView(
  initialUrl: evento.urlTransmision, // https://player.kick.com/canal
  javascriptMode: JavascriptMode.unrestricted,
)
```

### Control de Acceso por Suscripción
```dart
if (evento.esPremium && !usuario.esPremium) {
  // Mostrar mensaje de upgrade a premium
  return PantallaSuscripcion();
} else {
  // Mostrar transmisión
  return PantallaTransmision(evento);
}
```

---

**🎉 Sistema de Transmisiones Completamente Funcional**
- ✅ CRUD completo de coliseos y eventos
- ✅ Autenticación y autorización
- ✅ Integración con Kick.com
- ✅ Estados de eventos en tiempo real
- ✅ Control de acceso premium
- ✅ Paginación y filtros
- ✅ Validaciones robustas

**Creado por Alan & Claude - Los Máximos del API Design** 🚀