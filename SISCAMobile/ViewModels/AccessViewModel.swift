import Foundation
import LocalAuthentication

/// Selección de aula + autenticación biométrica. Port de `AccessViewModel` (Android),
/// donde en iOS la biometría (Face ID / Touch ID) reemplaza tanto la huella como el
/// reconocimiento facial.
@MainActor
final class AccessViewModel: ObservableObject {

    var isBiometricAvailable: Bool { BiometricAuth.isAvailable() }

    /// Etiqueta del método biométrico del dispositivo (para la UI).
    var biometricLabel: String {
        switch BiometricAuth.biometryType() {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        default: return "Biometría"
        }
    }

    /// Icono acorde al método biométrico del dispositivo.
    var biometricIconName: String {
        switch BiometricAuth.biometryType() {
        case .faceID: return "face_recognition_icon"
        default: return "fingerprint_icon"
        }
    }

    func authenticateBiometric(completion: @escaping (Result<Void, Error>) -> Void) {
        BiometricAuth.authenticate(
            reason: "Verifica tu identidad para abrir el aula",
            completion: completion
        )
    }
}
