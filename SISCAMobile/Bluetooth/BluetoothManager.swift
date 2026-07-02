import Foundation
import CoreBluetooth

/// Resultado de extremo a extremo del envío de la señal a la cerradura.
/// Igual que en Android: NO se reporta "éxito" por la mera escritura BLE; se espera el veredicto real del ESP.
enum EspSignalResult {
    /// El ESP validó el token y abrió la cerradura ({"valido":1}).
    case opened
    /// El ESP rechazó el token o no pudo validarlo ({"valido":0}); `reason` es legible.
    case denied(reason: String)
    /// Fallo de transporte: sin dispositivo, sin conexión, timeout, etc.
    case error(message: String)
}

/// Envío de señal a la cerradura por BLE (GATT central) con ACK de extremo a extremo.
///
/// Port de `BluetoothUtilsBLE` (Android) a CoreBluetooth. El firmware del ESP32 (NimBLE) expone el
/// servicio FFE0 con la característica FFE1 (WRITE+NOTIFY). Flujo: escanear (filtrando por SERVICE_UUID
/// y eligiendo por nombre el aula) -> conectar -> descubrir servicios -> habilitar notificaciones
/// (CoreBluetooth escribe el CCCD automáticamente) -> escribir el JSON {user,token} -> ESPERAR la
/// notificación con el veredicto ({"valido":1|0}) y reportarlo. `completion` se invoca EXACTAMENTE una vez.
final class BluetoothManager: NSObject {

    static let shared = BluetoothManager()

    // Perfil GATT del firmware ESP32 (ble_server.cpp / config.h: FFE0 / FFE1).
    private let serviceUUID = CBUUID(string: "FFE0")
    private let characteristicUUID = CBUUID(string: "FFE1")

    private let scanTimeout: TimeInterval = 12
    private let connectTimeout: TimeInterval = 10
    private let gattTimeout: TimeInterval = 10       // cubre descubrimiento + notify + escritura
    private let responseTimeout: TimeInterval = 10

    private let queue = DispatchQueue(label: "com.example.siscamobile.ble")
    private var central: CBCentralManager!

    // Estado del flujo en curso.
    private var targetName = ""
    private var payload = Data()
    private var completion: ((EspSignalResult) -> Void)?
    private var reported = false
    private var pendingStart = false

    private var peripheral: CBPeripheral?
    private var writeCharacteristic: CBCharacteristic?

    private var scanTimer: DispatchSourceTimer?
    private var connectTimer: DispatchSourceTimer?
    private var gattTimer: DispatchSourceTimer?
    private var responseTimer: DispatchSourceTimer?

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: queue)
    }

    /// Escanea, se conecta, escribe el JSON y espera el veredicto del ESP.
    /// Llama a `completion` EXACTAMENTE una vez (en el hilo principal).
    func sendToESP(name: String, json: String, completion: @escaping (EspSignalResult) -> Void) {
        queue.async {
            // Cierra cualquier flujo previo antes de empezar uno nuevo (p.ej. tras "Reintentar").
            self.cleanupConnection()
            self.targetName = name
            self.payload = Data(json.utf8)
            self.completion = completion
            self.reported = false
            self.pendingStart = false

            switch self.central.state {
            case .poweredOn:
                self.startScan()
            case .poweredOff:
                self.report(.error(message: "Bluetooth no disponible o desactivado"))
            case .unauthorized:
                self.report(.error(message: "La app no tiene permiso de Bluetooth"))
            case .unsupported:
                self.report(.error(message: "Bluetooth LE no está disponible en este dispositivo"))
            default:
                // .unknown / .resetting: esperamos a centralManagerDidUpdateState.
                self.pendingStart = true
            }
        }
    }

    // MARK: - Escaneo

    private func startScan() {
        // Filtra por Service UUID: solo las cerraduras SISCA (que anuncian FFE0) aparecen;
        // entre ellas se elige por nombre el aula correcta.
        central.scanForPeripherals(withServices: [serviceUUID], options: nil)
        scanTimer = makeTimer(after: scanTimeout) { [weak self] in
            guard let self else { return }
            self.central.stopScan()
            self.report(.error(message: "No se encontró la cerradura '\(self.targetName)'"))
        }
    }

    // MARK: - Timers

    private func makeTimer(after seconds: TimeInterval, _ handler: @escaping () -> Void) -> DispatchSourceTimer {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + seconds)
        timer.setEventHandler(handler: handler)
        timer.resume()
        return timer
    }

    private func cancelTimers() {
        scanTimer?.cancel(); scanTimer = nil
        connectTimer?.cancel(); connectTimer = nil
        gattTimer?.cancel(); gattTimer = nil
        responseTimer?.cancel(); responseTimer = nil
    }

    // MARK: - Reporte único + limpieza

    /// Garantiza que `completion` se invoque una sola vez (equivalente al AtomicBoolean de Android).
    private func report(_ result: EspSignalResult) {
        guard !reported else { return }
        reported = true
        let callback = completion
        cleanupConnection()
        DispatchQueue.main.async { callback?(result) }
    }

    private func cleanupConnection() {
        cancelTimers()
        if central?.state == .poweredOn {
            central.stopScan()
        }
        if let peripheral {
            central?.cancelPeripheralConnection(peripheral)
        }
        peripheral = nil
        writeCharacteristic = nil
    }

    // MARK: - Veredicto

    /// Traduce el JSON de veredicto del ESP a un `EspSignalResult`.
    private func parseVerdict(_ payload: String) -> EspSignalResult {
        guard let data = payload.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return .error(message: "Respuesta inválida de la cerradura")
        }
        let valido = (object["valido"] as? Int) ?? Int("\(object["valido"] ?? "")") ?? 0
        if valido == 1 {
            return .opened
        }
        let code = (object["error"] as? String) ?? ""
        return .denied(reason: reason(for: code))
    }

    private func reason(for code: String) -> String {
        switch code {
        case "replay":  return "Este código ya fue utilizado. Genera uno nuevo."
        case "sin_red": return "La cerradura no tiene conexión a Internet."
        case "formato": return "Error de formato en el mensaje enviado."
        default:        return "Acceso denegado: token inválido o expirado."
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension BluetoothManager: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard pendingStart else { return }
        switch central.state {
        case .poweredOn:
            pendingStart = false
            startScan()
        case .poweredOff:
            pendingStart = false
            report(.error(message: "Bluetooth no disponible o desactivado"))
        case .unauthorized:
            pendingStart = false
            report(.error(message: "La app no tiene permiso de Bluetooth"))
        case .unsupported:
            pendingStart = false
            report(.error(message: "Bluetooth LE no está disponible en este dispositivo"))
        default:
            break // seguimos esperando
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        let advertisedName = (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ?? peripheral.name
        // Elige el aula correcta por nombre; garantiza una sola conexión.
        guard advertisedName == targetName, self.peripheral == nil else { return }

        self.peripheral = peripheral
        peripheral.delegate = self
        central.stopScan()
        scanTimer?.cancel(); scanTimer = nil

        connectTimer = makeTimer(after: connectTimeout) { [weak self] in
            self?.report(.error(message: "No se pudo conectar a la cerradura"))
        }
        central.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectTimer?.cancel(); connectTimer = nil
        // Cubre descubrimiento de servicios/característica + activación de notificaciones + escritura.
        // Sin esto, si esas fases se estancan (iOS no genera didDisconnect si la conexión sigue viva),
        // completion nunca se llamaría y la UI quedaría cargando para siempre.
        gattTimer = makeTimer(after: gattTimeout) { [weak self] in
            self?.report(.error(message: "No se pudo preparar la cerradura a tiempo"))
        }
        peripheral.discoverServices([serviceUUID])
    }

    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        report(.error(message: "No se pudo conectar a la cerradura"))
    }

    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        // no-op si ya se reportó un veredicto; cubre desconexiones inesperadas.
        report(.error(message: "Se perdió la conexión con la cerradura"))
    }
}

// MARK: - CBPeripheralDelegate

extension BluetoothManager: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil, let service = peripheral.services?.first(where: { $0.uuid == serviceUUID }) else {
            report(.error(message: "No se pudo descubrir el servicio BLE"))
            return
        }
        peripheral.discoverCharacteristics([characteristicUUID], for: service)
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        guard error == nil,
              let characteristic = service.characteristics?.first(where: { $0.uuid == characteristicUUID }) else {
            report(.error(message: "La cerradura no expone la característica esperada"))
            return
        }
        writeCharacteristic = characteristic
        // Habilita notificaciones ANTES de escribir, para no perder el veredicto.
        // CoreBluetooth escribe el CCCD (0x2902) automáticamente.
        peripheral.setNotifyValue(true, for: characteristic)
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateNotificationStateFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard error == nil, characteristic.isNotifying, let payload = safePayload() else {
            report(.error(message: "No se pudo preparar la respuesta de la cerradura"))
            return
        }
        // Escritura CON respuesta: se dispara didWriteValueFor.
        peripheral.writeValue(payload, for: characteristic, type: .withResponse)
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didWriteValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        if error != nil {
            report(.error(message: "No se pudo enviar la señal a la cerradura"))
            return
        }
        // Preparación completa (descubrimiento + notify + escritura): cancela su timeout.
        gattTimer?.cancel(); gattTimer = nil
        // Token enviado: ahora ESPERAMOS el veredicto por notificación, con timeout.
        responseTimer = makeTimer(after: responseTimeout) { [weak self] in
            self?.report(.error(message: "La cerradura no respondió a tiempo"))
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard characteristic.uuid == characteristicUUID else { return }
        responseTimer?.cancel(); responseTimer = nil
        let text = characteristic.value.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        report(parseVerdict(text))
    }

    /// Devuelve el payload a escribir (nil solo si el flujo ya fue limpiado).
    private func safePayload() -> Data? {
        payload.isEmpty ? nil : payload
    }
}
