# 📱 CAMBIO DE NOMBRE DE LA APP

## ✅ Cambios Realizados

Se ha cambiado el nombre visible de la aplicación de **"Pedidos Frontend"** a **"La Bomba"**.

---

## 📝 Archivos Modificados

### 1️⃣ Android - AndroidManifest.xml

**Archivo**: `android/app/src/main/AndroidManifest.xml`

```xml
<!-- ANTES -->
<application
    android:label="pedidos_frontend"
    ...>

<!-- DESPUÉS -->
<application
    android:label="La Bomba"
    ...>
```

**Línea modificada**: 3

---

### 2️⃣ iOS - Info.plist

**Archivo**: `ios/Runner/Info.plist`

```xml
<!-- ANTES -->
<key>CFBundleDisplayName</key>
<string>Pedidos Frontend</string>
...
<key>CFBundleName</key>
<string>pedidos_frontend</string>

<!-- DESPUÉS -->
<key>CFBundleDisplayName</key>
<string>La Bomba</string>
...
<key>CFBundleName</key>
<string>La Bomba</string>
```

**Líneas modificadas**: 8 y 16

---

### 3️⃣ Descripción - pubspec.yaml

**Archivo**: `pubspec.yaml`

```yaml
# ANTES
description: "A new Flutter project."

# DESPUÉS
description: "La Bomba - Sistema de gestión de pedidos"
```

**Línea modificada**: 2

---

## 🚀 Cómo Aplicar los Cambios

### Opción 1: Rebuild completo (Recomendado)

```bash
cd /Users/mac/Documents/pedidos/frontend

# Limpiar build anterior
flutter clean

# Obtener dependencias
flutter pub get

# Rebuild para Android
flutter build apk
# O para correr directamente
flutter run
```

### Opción 2: Solo reinstalar la app

```bash
cd /Users/mac/Documents/pedidos/frontend

# Desinstalar la app del dispositivo
# (Hazlo manualmente desde el celular)

# Correr de nuevo
flutter run
```

---

## 📱 Resultado Esperado

Después de aplicar los cambios:

| Plataforma | Antes | Después |
|------------|-------|---------|
| **Android** | 📱 "pedidos_frontend" | 📱 "La Bomba" |
| **iOS** | 📱 "Pedidos Frontend" | 📱 "La Bomba" |
| **Launcher** | 🔵 pedidos_frontend | 🔴 La Bomba |

---

## ⚠️ Importante

### ¿Por qué no cambié el nombre del paquete?

El **nombre del paquete** (`pedidos_frontend` en `pubspec.yaml`) es diferente del **nombre visible** de la app.

- **Nombre del paquete**: Se usa internamente en el código (imports, dependencias)
- **Nombre visible**: Es lo que el usuario ve en el launcher del celular

Cambiar el nombre del paquete requiere:
- Cambiar todos los `import 'package:pedidos_frontend/...'` en todo el código
- Actualizar configuraciones de build
- Posibles conflictos con dependencias

**No es necesario** cambiar el nombre del paquete solo para cambiar el nombre visible de la app. ✅

---

## 🧪 Verificación

### En Android:

1. Compila la app: `flutter build apk`
2. Instala en tu dispositivo
3. Busca el ícono en el launcher
4. Verifica que diga **"La Bomba"** ✅

### En iOS (si usas iOS):

1. Compila la app: `flutter build ios`
2. Instala en tu dispositivo
3. Busca el ícono en la pantalla principal
4. Verifica que diga **"La Bomba"** ✅

---

## 📊 Resumen

| Cambio | Estado |
|--------|--------|
| ✅ Nombre en Android | Completado |
| ✅ Nombre en iOS | Completado |
| ✅ Descripción actualizada | Completado |
| ⚠️ Nombre del paquete | No modificado (no es necesario) |

---

## 🔄 Si Quieres Revertir los Cambios

Si por alguna razón quieres volver al nombre anterior:

```xml
<!-- AndroidManifest.xml -->
android:label="pedidos_frontend"

<!-- Info.plist -->
<string>Pedidos Frontend</string>
...
<string>pedidos_frontend</string>
```

Luego haz `flutter clean` y `flutter run`.

---

## 📞 Ayuda Adicional

Si tienes problemas:

1. **Asegúrate de hacer `flutter clean`** antes de compilar
2. **Desinstala la app vieja** del dispositivo antes de instalar la nueva
3. **Verifica que los archivos se guardaron correctamente**
4. **Revisa que no haya errores de sintaxis** en los archivos XML

---

**Fecha de cambio**: 2025-10-24
**Nombre anterior**: Pedidos Frontend / pedidos_frontend
**Nombre nuevo**: La Bomba
**Estado**: ✅ Completado
