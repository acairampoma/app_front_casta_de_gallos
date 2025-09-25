# 🚀 ESTRATEGIA DE DEPLOYMENT MULTIPLATAFORMA
## Casta de Gallos - iOS vs Android

### 📱 ARCHIVOS DE CONFIGURACIÓN POR PLATAFORMA:

```
proyecto/
├── pubspec_ios.yaml          # ✅ Minimalista para iOS
├── pubspec_android.yaml      # 🤖 Completo para Android
├── pubspec.yaml              # 👆 Activo según plataforma
├── main_ios.dart             # ✅ Sin Firebase/video
├── main_android.dart         # 🤖 Completo con todo
└── lib/main.dart             # 👆 Activo según plataforma
```

### 🔄 COMANDO DE CAMBIO RÁPIDO:

**Para iOS:**
```bash
npm run ios-mode    # Cambia a configuración iOS
```

**Para Android:**
```bash
npm run android-mode    # Cambia a configuración Android
```

### 📋 CHECKLIST ANTES DE DEPLOY:

**iOS Deploy:**
- [ ] `npm run ios-mode`
- [ ] `flutter clean && flutter pub get`
- [ ] Verificar version: `1.1.x+8xx`
- [ ] Build: `flutter build ios --release`

**Android Deploy:**
- [ ] `npm run android-mode`
- [ ] `flutter clean && flutter pub get`
- [ ] Verificar version: `1.1.x+8xx`
- [ ] Build: `flutter build apk --release`