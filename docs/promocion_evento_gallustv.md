# Plan 360° para promocionar tu evento en gallustv.com

Fecha: 2025-09-23
Objetivo: Maximizar awareness, intención de compra y audiencia conectada al live de Cloudinary (HLS) del evento.

---

## 1) Checklist de activos
- Landing específica del evento (URL corta): `https://gallustv.com/<slug-evento>`
- Arte hero (1200x630, 1080x1920), logo, patrocinadores
- Trailer/teaser (15–30s) y highlight (6–10s)
- Links principales:
  - Player/App: HLS nativo en app o `player link` protegido
  - Compra/acceso (si aplica)
  - Términos y horario oficial (zona horaria)
- Código de descuento temporal (opcional)
- Pixel y analytics: GA4, Meta Pixel, TikTok Pixel

---

## 2) Landing SEO + Conversion
Estructura recomendada de `https://gallustv.com/<slug-evento>`:
- Hero con CTA “Conéctate en vivo” + contador regresivo
- Detalle: fecha, hora (GMT-5), sede/coliseo, cartel, premios
- Precios y medios de pago (si aplica)
- Preguntas frecuentes (device support, reembolsos, soporte)
- Testimonios / garantías / confianza

### 2.1 Open Graph y Twitter Cards
Agrega en `<head>`:
```html
<!-- Open Graph -->
<meta property="og:title" content="[Nombre del Evento] | GALLUS TV" />
<meta property="og:description" content="Vive en vivo el [evento] desde [ciudad]. Fecha [dd/mm],  [hora GMT-5]." />
<meta property="og:image" content="https://gallustv.com/assets/eventos/<slug>/og-1200x630.jpg" />
<meta property="og:url" content="https://gallustv.com/<slug-evento>" />
<meta property="og:type" content="event" />
<meta property="og:site_name" content="GALLUS TV" />

<!-- Twitter -->
<meta name="twitter:card" content="summary_large_image" />
<meta name="twitter:title" content="[Nombre del Evento] | GALLUS TV" />
<meta name="twitter:description" content="Conéctate al vivo en GALLUS TV" />
<meta name="twitter:image" content="https://gallustv.com/assets/eventos/<slug>/og-1200x630.jpg" />
```

### 2.2 Datos estructurados (JSON-LD Event)
```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "SportsEvent",
  "name": "[Nombre del Evento]",
  "startDate": "2025-10-05T19:00:00-05:00",
  "endDate": "2025-10-05T23:00:00-05:00",
  "eventAttendanceMode": "https://schema.org/OnlineEventAttendanceMode",
  "eventStatus": "https://schema.org/EventScheduled",
  "location": {
    "@type": "VirtualLocation",
    "url": "https://gallustv.com/<slug-evento>"
  },
  "image": [
    "https://gallustv.com/assets/eventos/<slug>/og-1200x630.jpg"
  ],
  "description": "Transmisión en vivo del evento [nombre], desde [coliseo/ciudad].",
  "organizer": {
    "@type": "Organization",
    "name": "GALLUS TV",
    "url": "https://gallustv.com/"
  },
  "offers": {
    "@type": "Offer",
    "url": "https://gallustv.com/<slug-evento>",
    "price": "[precio]",
    "priceCurrency": "PEN",
    "availability": "https://schema.org/InStock",
    "validFrom": "2025-09-25T00:00:00-05:00"
  }
}
</script>
```

---

## 3) Pauta y medición
- GA4: evento `begin_checkout`, `purchase`, `stream_start`, `stream_minutes`
- UTM por canal: `utm_source`, `utm_medium`, `utm_campaign=evento-<slug>-<fecha>`
- Meta Ads: conversion API si es posible; audiencia lookalike (visitantes previos y compradores)
- TikTok Ads: video corto (9–15s), objetivo “Traffic” o “Conversion”
- Google Ads: Search (marca + términos "gallos en vivo"), YouTube in‑stream skippable

Plantilla UTM:
```
https://gallustv.com/<slug-evento>?utm_source=instagram&utm_medium=social&utm_campaign=evento-<slug>-2025-10
```

---

## 4) Social Media – Copys y formatos
- Instagram Feed/Reels (1080x1350 / 1080x1920)
  - Copy:
    - "Este [fecha] desde [ciudad], ¡vívelo en vivo en GALLUS TV! 🎥🐔\n⏰ [hora GMT‑5] | 🔗 Link en bio\n#Gallos #Gallistica #EnVivo #Perú"
  - CTA: link en bio, sticker de cuenta regresiva en Stories
- Facebook
  - Evento en Facebook con link UTM a la landing.
  - Copy:
    - "Entradas/acceso ya disponible. Conéctate desde tu celular o TV."
- TikTok
  - 6–10s highlights, texto en pantalla, cierre con URL corta.
- WhatsApp/Telegram (difusión)
  - Texto:
    - "[NOMBRE DEL EVENTO] – en vivo este [fecha], [hora GMT‑5]. Mira aquí: https://gallustv.com/<slug-evento>"
- YouTube (Shorts)
  - Teaser 15s, link en descripción y comentario fijado.

Calendario sugerido (semana del evento):
- D‑7: Anuncio oficial (trailer) + página en vivo
- D‑5: Presentación de coliseo/organizador
- D‑3: Teaser de cartel + recordatorio
- D‑1: Cuenta regresiva, prueba técnica
- D: Post de inicio + Stories cada hora + link directo
- D+1: Highlights y agradecimiento

---

## 5) Influencers y comunidades
- Identifica 5–10 microinfluencers locales (gallística/deportes) en Perú
- Ofrece códigos de descuento personalizados (UTM + cupón)
- Comunidades/foros locales y grupos de Facebook/WhatsApp del rubro

---

## 6) Email/SMS/Push (si tienes base)
- Email 1 (D‑5): anuncio + beneficios + CTA
- Email 2 (D‑1): recordatorio + horario + dispositivos compatibles
- Email 3 (D): “En vivo ahora” con link directo
- SMS/Push: recordatorio D‑0 con URL corta

---

## 7) Material para partners/coliseos
- Paquete ZIP: artes, copy, QR a landing (vCard opcional)
- Lineamientos de marca y hashtags

---

## 8) Soporte y postventa
- Página de ayuda: cómo ver (móvil/TV), soluciones comunes
- Canal de soporte en WhatsApp/Telegram el día del evento
- Encuesta de satisfacción post‑evento + incentivo (cupón próxima fecha)

---

## 9) Métricas clave (KPI)
- CTR por canal (Meta/TikTok/Google/Orgánico)
- CPA (costo por compra/acceso) y ROAS
- Tasa de inicio de stream vs. compras
- Concurrencia pico, minutos vistos, abandono

---

## 10) Apéndice – Snippets útiles

### 10.1 QR a la landing
Usa un generador de QR con URL UTM por canal. Ejemplo (texto para memo):
```
URL: https://gallustv.com/<slug-evento>?utm_source=flyer&utm_medium=offline&utm_campaign=evento-<slug>-2025-10
```

### 10.2 Botón CTA (HTML)
```html
<a class="btn btn-primary btn-lg" href="https://gallustv.com/<slug-evento>" rel="nofollow">Conéctate al Vivo</a>
```

### 10.3 Avisos legales
Incluye aviso de derechos, términos y restricciones geográficas si aplica.

---

## 11) Paso a producción
1. Publica la landing con OG, JSON‑LD y pixels.
2. Revisa en Rich Results Test (Google) y depurador de Facebook (Sharing Debugger).
3. Activa campañas con UTMs y presupuesto escalonado.
4. Haz prueba técnica (señal + player) el D‑1.
5. Operativa en vivo con monitoreo de Cloudinary y analytics.

---

¿Deseas que preparemos artes base (plantillas) y copies con el nombre real del evento y fecha? También puedo crear un `slug` recomendado y los enlaces UTM por cada canal para copiar/pegar.
