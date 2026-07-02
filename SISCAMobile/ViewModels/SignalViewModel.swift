import Foundation

/// Genera el token y envía la señal a la cerradura por BLE, esperando el veredicto real del ESP.
/// Port de `SignalViewModel` + `CommUiState` (Android).
@MainActor
final class SignalViewModel: ObservableObject {

    enum State: Equatable {
        case checking
        case useBluetooth                 // enviando por BLE
        case signalSent                   // ESP validó y abrió la cerradura
        case accessDenied(String)         // ESP rechazó el token
        case error(String)                // fallo de transporte/conexión
    }

    @Published var state: State = .checking

    private var started = false

    /// Arranca el flujo una sola vez (al aparecer la pantalla).
    func startIfNeeded() {
        guard !started else { return }
        started = true
        run()
    }

    /// Reintenta el flujo desde cero (botón "Reintentar" en estados terminales).
    func retry() {
        run()
    }

    private func run() {
        state = .checking
        Task { await sendSignal() }
    }

    private func sendSignal() async {
        guard let user = UserStore.getUser() else {
            state = .error("No se encontraron datos de usuario.")
            return
        }
        guard let classroom = UserStore.getSelectedClassroom() else {
            state = .error("No se encontró el aula seleccionada.")
            return
        }

        let tokenResult = await APIClient.getToken(spaceCode: classroom.ecodigo, user: user.usuario)
        guard case .success(let tokenData) = tokenResult, !tokenData.token.isEmpty else {
            state = .error("No se pudo obtener el token de acceso.")
            return
        }

        state = .useBluetooth

        let deviceName = "ESP32_SPP_SERVER_\(classroom.ecodigo)"
        let json = "{\"user\":\"\(user.usuario)\", \"token\":\"\(tokenData.token)\"}"

        // Espera el VEREDICTO real del ESP (no solo la escritura) antes de actualizar la UI.
        let result = await withCheckedContinuation { (continuation: CheckedContinuation<EspSignalResult, Never>) in
            BluetoothManager.shared.sendToESP(name: deviceName, json: json) { result in
                continuation.resume(returning: result)
            }
        }

        switch result {
        case .opened:
            state = .signalSent
        case .denied(let reason):
            state = .accessDenied(reason)
        case .error(let message):
            state = .error(message)
        }
    }
}
