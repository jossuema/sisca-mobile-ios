# SISCA · App móvil (iOS)

Port a **iOS (Swift + SwiftUI)** de la [app Android de SISCA](https://github.com/jossuema/sisca-mobile) (control de
acceso de la UTMACH). El usuario inicia sesión, elige un aula, se autentica con **biometría (Face ID / Touch ID)**
y la app **abre la cerradura** del aula enviando un token por **Bluetooth Low Energy (BLE)** al
[firmware ESP32](https://github.com/jossuema/sisca-esp-platformIO).

Hecha con **Swift + SwiftUI**, arquitectura **MVVM**, **URLSession** (API), **LocalAuthentication** (biometría)
y **CoreBluetooth** (cerradura). **Sin dependencias externas** (no usa CocoaPods ni SPM).

---

## 1. Equivalencias con la app Android

| Android (Kotlin) | iOS (Swift) |
|---|---|
| Jetpack Compose | SwiftUI |
| ViewModel + StateFlow | `ObservableObject` + `@Published` |
| Navigation Compose (NavHost) | `NavigationStack` + rutas |
| Retrofit + Gson | `URLSession` + `Codable` |
| BLE GATT (`BluetoothGatt`) | `CoreBluetooth` (`CBCentralManager`) |
| BiometricPrompt (huella) | `LocalAuthentication` (Face ID / Touch ID) |
| **FaceNet TFLite + ML Kit** (rostro) | **`LocalAuthentication`** (biometría nativa) † |
| SharedPreferences + Gson | `UserDefaults` + `Codable` |
| MD5 (`MessageDigest`) | `CryptoKit` (`Insecure.MD5`) |
| `BuildConfig` (local.properties) | `Config.plist` (no versionado) |

† **Decisión de diseño del port:** en iOS el reconocimiento facial y la huella se resuelven ambos con la
biometría nativa del dispositivo. No se porta el modelo FaceNet de 90 MB ni la cámara. Esto cambia la semántica:
la biometría valida al **dueño del iPhone**, no compara contra la foto institucional del servidor como en Android.

---

## 2. Flujo de la app

```
Login (invusuariosisca)
  └─> Doors (lista de aulas — lstespaciosxpersona)
        └─> Access (elige método: biometría / PIN)
              └─> [Face ID / Touch ID]
                    └─> Signal (genera token gentokenesp + BLE) ──> ESP32 abre
```

| Pantalla | Función |
|---|---|
| **Login** | Autenticación contra la API (usuario + contraseña MD5). |
| **Doors** | Lista de aulas a las que el usuario tiene acceso; selecciona una. |
| **Access** | Elige el método de verificación (biometría o PIN). |
| **Signal** | Genera el token del aula y lo envía al ESP por BLE; muestra el resultado real. |

---

## 3. Comunicación BLE (cómo abre la cerradura)

`SignalSendingView` → `SignalViewModel` → `BluetoothManager.sendToESP()`:

1. Genera el token con la API (`gentokenesp`) para el aula seleccionada.
2. **Escanea** filtrando por **Service UUID FFE0** y elige el dispositivo `ESP32_SPP_SERVER_<ecodigo>` por nombre.
3. **Conecta**, descubre servicios y **habilita notificaciones** (CoreBluetooth escribe el CCCD automáticamente).
4. **Escribe** `{"user","token"}` en la característica **FFE1** (escritura con respuesta).
5. **Espera el veredicto** del ESP por notificación (`{"valido":1|0}`) — con timeout — y lo traduce a
   acceso concedido / denegado (con causa) / error de transporte.

Igual que en Android, la app **no** declara "enviado" por la sola escritura: espera el ACK de extremo a extremo.

---

## 4. Estructura del proyecto

```
sisca-mobile-ios/
├── gen_project.rb              # genera SISCAMobile.xcodeproj (gema `xcodeproj`)
├── SISCAMobile.xcodeproj       # (generado)
└── SISCAMobile/
    ├── App/                    # @main, AppConfig, SessionStore
    ├── Models/                 # ApiModels, DecodingHelpers
    ├── Networking/             # APIClient (login / spaces / token)
    ├── Bluetooth/              # BluetoothManager (CoreBluetooth) + EspSignalResult
    ├── Auth/                   # BiometricAuth (LocalAuthentication)
    ├── Persistence/            # UserStore (UserDefaults)
    ├── Utils/                  # MD5
    ├── ViewModels/             # Auth, Classroom, Access, Signal
    ├── Views/                  # Login, Doors, Access, SignalSending, Root, Nav, Components
    ├── Theme/                  # Color+Hex + paleta
    ├── Assets.xcassets/        # imágenes + AppIcon
    ├── Info.plist
    ├── Config.plist            # secretos (NO versionado)
    └── Config.plist.example
```

---

## 5. Requisitos

- **Xcode 16+** (probado con 16.4) y **Swift 5+**.
- **iOS 16+** (deployment target).
- Para BLE y biometría reales se necesita un **iPhone físico** (el simulador no tiene Bluetooth y
  la cámara/biometría es simulada). El simulador sirve para la UI y el login.
- La gema **`xcodeproj`** (viene con **CocoaPods**) solo si quieres regenerar el `.xcodeproj`.

---

## 6. Configuración (secretos)

Los secretos van en `Config.plist` (**no versionado**), equivalente al `local.properties` de Android:

```bash
cp SISCAMobile/Config.plist.example SISCAMobile/Config.plist
```

Rellena `API_PHKEY` (cópialo del `local.properties` del proyecto Android). `API_URL` ya viene con el valor
público (`https://www.utmachala.edu.ec/querys/`) y **debe terminar en `/`**.

---

## 7. Generar el proyecto, compilar y ejecutar

```bash
# (Re)generar el .xcodeproj a partir de los archivos en SISCAMobile/
ruby gen_project.rb

# Compilar para el simulador
xcodebuild -project SISCAMobile.xcodeproj -scheme SISCAMobile \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build

# O abre el proyecto en Xcode y pulsa Run:
open SISCAMobile.xcodeproj
```

Para correr en un **iPhone físico**: abre en Xcode, selecciona tu equipo de firma (Signing & Capabilities)
con tu Apple ID y ejecuta en el dispositivo.

---

## 8. Permisos (Info.plist)

| Clave | Para qué |
|---|---|
| `NSBluetoothAlwaysUsageDescription` | Escanear/conectar a la cerradura BLE. |
| `NSFaceIDUsageDescription` | Autenticación con Face ID. |

CoreBluetooth y LocalAuthentication piden permiso al usuario automáticamente en el primer uso.

---

## 9. Contrato con la API y el ESP

| Acción | Quién | Endpoint / canal |
|---|---|---|
| Login | App | `consulta.php?funcion=invusuariosisca&user&pass&pkey` |
| Aulas del usuario | App | `consulta.php?funcion=lstespaciosxpersona&user&pkey` |
| Generar token | App | `consulta.php?funcion=gentokenesp&user&ecodigo&pkey` |
| Verificar token | **ESP** | `consulta.php?funcion=valtokenesp&user&ecodigo&token&pkey` |
| Enviar token a la cerradura | App → ESP | BLE: servicio **FFE0**, característica **FFE1** |

---

## 10. Notas del port

- El proyecto **no** trae dependencias externas; el `.xcodeproj` se genera por script (`gen_project.rb`)
  usando la gema `xcodeproj`, así que el repo no versiona un `project.pbxproj` gigante a mano.
- Se corrigió un detalle del flujo Android: aquí el **aula seleccionada se persiste siempre** antes de ir a
  Signal (en Android el camino de huella no la persistía).
- Los decodificadores JSON toleran números/booleanos como string (`"1"`, `"true"`), como hacía Gson.
