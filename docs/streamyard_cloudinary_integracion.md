# Guía StreamYard + Cloudinary Live Streams

Esta guía explica cómo emitir desde StreamYard hacia Cloudinary (RTMP personalizado) y cómo reproducir la señal en tu app.

Fecha: 2025-09-23

---

## 1) Requisitos
- Cuenta Cloudinary con Live Streams habilitado.
- Un stream creado en Cloudinary (ID/`public_id`) con:
  - RTMP URL (servidor): `rtmp://live.cloudinary.com/streams`
  - Stream Key (clave): provista por Cloudinary para ese stream
  - HLS URL (playback): `https://res.cloudinary.com/<cloud_name>/video/live/<public_id>.m3u8`
- Cuenta de StreamYard (plan que permita RTMP personalizado).

> Nota de seguridad: La `Stream Key` es sensible. No la publiques. Rótala si se filtra.

---

## 2) Configurar destino RTMP en StreamYard
1. En StreamYard, ve a `Destinations` → `Add a destination`.
2. Elige `Custom RTMP`.
3. Completa los campos:
   - `RTMP Server URL`: `rtmp://live.cloudinary.com/streams`
   - `Stream Key`: la clave de tu stream de Cloudinary (ej.: `0Be7kF5esuM89GC89e1Er5xM9RTQre`).
4. Guarda el destino.

> Si usas varios eventos, crea un destino RTMP por evento/stream para evitar confusiones.

---

## 3) Crear un broadcast y seleccionar el RTMP
1. Crea un `Broadcast` en StreamYard.
2. En `Destinations`, selecciona el destino RTMP personalizado que apunta a Cloudinary.
3. Añade tus fuentes: cámara, pantalla, overlays, banners.
4. Inicia el broadcast.

Cloudinary comenzará a recibir la señal RTMP y publicará el HLS del stream. La inicialización puede tardar unos segundos (segmentos HLS).

---

## 4) Verificar en Cloudinary
1. En `Video → Live Streams`, abre tu stream y verifica que el estado cambie a `Live`.
2. Usa el `Player link` de Cloudinary para validar la reproducción web rápidamente.
3. Comprueba límites operativos (Idle timeout y Max runtime) según tu configuración.

---

## 5) Reproducción en la app Flutter

### Opción A: Player nativo (recomendada)
Usa la `HLS URL` (`.m3u8`) con `video_player`/`better_player`.

```dart
final controller = VideoPlayerController.networkUrl(
  Uri.parse('https://res.cloudinary.com/<cloud_name>/video/live/<public_id>.m3u8'),
);
await controller.initialize();
controller.play();
```

### Opción B: WebView con Cloudinary Player (rápida)
Carga el `Player link` en tu `WebView` existente.

```dart
final playerUrl = 'https://player.cloudinary.com/embed/?cloud_name=<cloud_name>&public_id=<public_id>&profile=cld-live-streaming';
webViewController.loadRequest(Uri.parse(playerUrl));
```

> Producción: considera URLs firmadas/tokenizadas desde tu backend para controlar el acceso y vigencia.

---

## 6) Consideraciones sobre "baneos" y bloqueos
- StreamYard actúa como estudio/encoder en la nube. Al usar RTMP personalizado a Cloudinary, tu distribución no depende de plataformas con políticas de contenido más restrictivas (YouTube, Facebook, etc.).
- Aun así, debes:
  - Cumplir los Términos de Servicio de Cloudinary y leyes locales.
  - Proteger el playback con firmas/token si hay contenido de pago o restringido.
  - Evitar publicar la `HLS URL` sin control de acceso.

---

## 7) Latencia y calidad
- La latencia típica de HLS es 6–12 s. LL‑HLS puede bajar a ~2–5 s si lo habilitas y es compatible con tu player/CDN.
- Ajusta la calidad en StreamYard acorde al ancho de banda y a los perfiles de transcodificación de Cloudinary.

---

## 8) Checklist de operación
- Antes del evento:
  - Prueba 24–48 h antes con la misma red.
  - Verifica audio, overlays, gráficos, marcadores.
  - Ten un plan B de bitrate más bajo.
- Durante el evento:
  - Monitorea el estado del stream en Cloudinary y cualquier alerta en StreamYard.
  - Evita cambiar resolución/FPS a mitad de transmisión.
- Fin del evento:
  - Detén el broadcast en StreamYard.
  - Verifica que Cloudinary regrese a `Idle`.

---

## 9) Backend y seguridad
- Entrega la `HLS URL` a la app sólo tras validar pago/acceso.
- Usa firmas con expiración o tokens para el playback.
- Rota la `Stream Key` periódicamente o tras compartirla con terceros.

---

## 10) URLs de ejemplo (los tuyos)
- RTMP Server: `rtmp://live.cloudinary.com/streams`
- Stream Key: `0Be7kF5esuM89GC89e1Er5xM9RTQre`
- HLS URL: `https://res.cloudinary.com/dz4czc3en/video/live/live_stream_9894a6a7a27d49b19d6850538c22b6ea_hls.m3u8`
- Player link: `https://player.cloudinary.com/embed/?cloud_name=dz4czc3en&public_id=live_stream_9894a6a7a27d49b19d6850538c22b6ea_hls&profile=cld-live-streaming`

---

## 11) Resolución de problemas
- No se ve en Cloudinary:
  - Confirma que el broadcast está en vivo en StreamYard y que el destino RTMP es el correcto.
  - Revisa si la `Stream Key` coincide y si hay restricciones de red.
- Lag o buffering:
  - Reduce calidad en StreamYard.
  - Verifica el estado del transcodificador/egreso en Cloudinary.
- Acceso no autorizado a la HLS URL:
  - Implementa firma/token en tu backend y entrega URLs temporales.
