# Guía OBS + Cloudinary Live Streams

Esta guía explica cómo emitir desde OBS hacia Cloudinary y cómo reproducir la señal en tu app.

Fecha: 2025-09-22

> Importante: La `Stream Key` es sensible. No la compartas públicamente y rótala si sospechas exposición.

---

## 1) Datos del stream (ejemplo de tu canal)
- **ID**: `9894a6a7a27d49b19d6850538c22b6ea`
- **RTMP URL (Server)**: `rtmp://live.cloudinary.com/streams`
- **Stream Key**: `0Be7kF5esuM89GC89e1Er5xM9RTQre`
- **HLS URL (Playback)**: `https://res.cloudinary.com/dz4czc3en/video/live/live_stream_9894a6a7a27d49b19d6850538c22b6ea_hls.m3u8`
- **HLS Public ID**: `live_stream_9894a6a7a27d49b19d6850538c22b6ea_hls`
- **Player link (embed)**: `https://player.cloudinary.com/embed/?cloud_name=dz4czc3en&public_id=live_stream_9894a6a7a27d49b19d6850538c22b6ea_hls&profile=cld-live-streaming`
- **Idle timeout**: 1 minuto
- **Max runtime**: 3 horas

> Sugerencia: Guarda estos valores en tu backend y entrega a cada organizador sólo el RTMP Server + Stream Key.

---

## 2) Prerrequisitos
- OBS Studio instalado (v29+ recomendado).
- Cuenta Cloudinary con Live Streams habilitado.
- Ancho de banda de subida suficiente (≥ 2x el bitrate de video configurado).

---

## 3) Configurar Cloudinary (revisión rápida)
1. En el dashboard: `Video → Live Streams` y abre tu stream.
2. Verifica que el estado esté listo para recibir (Idle) o presiona `Activate` si tu plan/flujo lo requiere.
3. Copia `RTMP URL` y `Stream Key`.

---

## 4) Configurar OBS
1. Abre OBS → `Ajustes` → `Emisión`.
2. En `Servicio` selecciona `Personalizado`.
3. En `Servidor` pega: `rtmp://live.cloudinary.com/streams`.
4. En `Clave de transmisión` pega: `0Be7kF5esuM89GC89e1Er5xM9RTQre`.
5. Marca `Habilitar reconexión automática` (en `Avanzado`).

### 4.1 Salida (Output)
- Modo de salida: `Avanzado`.
- Codificador: `x264` o NVENC/AMF/Apple VT si tienes GPU (recomendado por eficiencia).
- Control de tasa: `CBR`.
- Bitrate de video (orientativo, según red/hardware):
  - 720p30: 2500–4000 kbps
  - 1080p30: 4500–6500 kbps
  - 1080p60: 6000–8500 kbps
- Intervalo de fotogramas clave (Keyframe): `2` segundos.
- Perfil: `high`.
- `tune=zerolatency` (opcional en x264 si buscas menor latencia).

### 4.2 Audio
- Frecuencia de muestreo: 44.1 kHz o 48 kHz.
- Bitrate: 128–192 kbps.

### 4.3 Video
- Resolución base (lienzo): según tu captura (ej. 1920x1080).
- Resolución de salida: 1280x720 o 1920x1080.
- Filtro de escalado: Lanczos (calidad) o Bicúbico (rendimiento).
- FPS: 30 o 60 (según deporte y hardware).

---

## 5) Iniciar emisión y verificar
1. En OBS, clic `Iniciar Transmisión`.
2. En Cloudinary `Live Streams`, verifica que el estado pase de `Idle` a `Live`.
3. Abre el `Player link` para validar la reproducción web.
4. Confirma que **no** superes `Max runtime` (3h) ni dejes el stream sin señal por más de `Idle timeout` (1 min).

---

## 6) Reproducción en la app Flutter

### Opción A: Player nativo (recomendada)
Usa la `HLS URL` (`.m3u8`) con `video_player`/`better_player`.

```dart
final controller = VideoPlayerController.networkUrl(
  Uri.parse('https://res.cloudinary.com/dz4czc3en/video/live/live_stream_9894a6a7a27d49b19d6850538c22b6ea_hls.m3u8'),
);
await controller.initialize();
controller.play();
```

### Opción B: WebView con Cloudinary Player (rápida)
Usa el `Player link` de Cloudinary dentro de tu `WebView` existente.

```dart
final playerUrl = 'https://player.cloudinary.com/embed/?cloud_name=dz4czc3en&public_id=live_stream_9894a6a7a27d49b19d6850538c22b6ea_hls&profile=cld-live-streaming';
webViewController.loadRequest(Uri.parse(playerUrl));
```

> Nota: Para entornos de producción, considera URLs firmadas/tokenizadas para controlar acceso y vigencia.

---

## 7) Resolución de problemas
- `Stream not active` en Cloudinary:
  - Verifica OBS: servidor/clave correctos, conexión de red, firewall.
  - Espera ~10–30 s tras iniciar emisión; HLS necesita inicializar segmentos.
- Video con cortes o buffering:
  - Reduce bitrate o FPS.
  - Asegura ancho de banda de subida estable.
- No hay audio:
  - Fuente de audio correcta en OBS y mezclador con nivel.
- Límite de 3h alcanzado:
  - Detén y reinicia el stream con nueva sesión si el evento continúa.
- Exposición de `Stream Key`:
  - Rota la clave en Cloudinary y actualiza en OBS.

---

## 8) Operativa recomendada para eventos
- Checklist previo:
  - Prueba 24–48 h antes con la misma red y hardware.
  - Verifica latencia, audio, overlays y puntuadores.
  - Ten un plan B (bitrate más bajo, encoder alterno).
- Durante el evento:
  - Monitoriza `Live stream Health` en Cloudinary.
  - Evita cambios bruscos de bitrate/FPS.
- Seguridad/Acceso:
  - Implementa firma temporal de playback (backend) y verifica pago/acceso antes de entregar la URL al cliente.

---

## 9) Integración con tu backend
- Endpoint para provisionar stream por evento: devuelve `rtmp_url`, `stream_key`, `hls_url`.
- Endpoint para playback seguro: genera URL firmada con expiración.
- Rotación de `stream_key` y revocación en caso de fuga.

---

## 10) Referencias
- Cloudinary Live Streams: Documentación oficial.
- OBS Studio: Guía oficial de configuración de streaming.
