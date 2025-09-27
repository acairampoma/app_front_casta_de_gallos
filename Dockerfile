# 🌐 Dockerfile para Flutter Web - Casta de Gallos
# Optimizado para Railway deployment con Flutter 3.35.2

FROM ghcr.io/cirruslabs/flutter:3.35.2 AS build

# Establecer directorio de trabajo
WORKDIR /app

# Copiar archivos de configuración
COPY pubspec.yaml ./
COPY pubspec.lock ./

# Instalar dependencias
RUN flutter pub get

# Limpiar caché de Flutter
RUN flutter clean

# Copiar el código fuente
COPY . .

# Construir la aplicación web (sin --web-renderer, deprecated in Flutter 3.35+)
RUN flutter build web --release --base-href /

# Etapa de producción - servidor HTTP ligero
FROM python:3.11-alpine AS runtime

# http.server es built-in en Python, no necesita instalación

# Crear usuario no-root para seguridad
RUN addgroup -g 1000 flutteruser && \
    adduser -u 1000 -G flutteruser -s /bin/sh -D flutteruser

# Crear directorio para la app
RUN mkdir -p /app/web && chown -R flutteruser:flutteruser /app

# Cambiar a usuario no-root
USER flutteruser

# Copiar archivos web construidos
COPY --from=build --chown=flutteruser:flutteruser /app/build/web /app/web

# Establecer directorio de trabajo
WORKDIR /app/web

# Exponer puerto
EXPOSE 8080

# Comando para servir la aplicación
CMD ["python", "-m", "http.server", "8080", "--bind", "0.0.0.0"]