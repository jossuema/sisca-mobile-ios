import Foundation
import LocalAuthentication

/// Autenticación biométrica nativa (Face ID / Touch ID).
/// Reemplaza en iOS tanto la huella (BiometricPrompt) como el reconocimiento facial
/// (FaceNet/TFLite) del proyecto Android, por decisión de diseño del port.
enum BiometricAuth {

    /// ¿El dispositivo tiene biometría configurada y disponible?
    static func isAvailable() -> Bool {
        var error: NSError?
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    /// Tipo de biometría del dispositivo (para etiquetar la UI): .faceID, .touchID o .none.
    static func biometryType() -> LABiometryType {
        let context = LAContext()
        var error: NSError?
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        return context.biometryType
    }

    /// Lanza el prompt biométrico. El completion llega SIEMPRE en el hilo principal.
    static func authenticate(reason: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            let message = error?.localizedDescription ?? "La biometría no está disponible"
            DispatchQueue.main.async { completion(.failure(APIError(message: message))) }
            return
        }

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, evalError in
            DispatchQueue.main.async {
                if success {
                    completion(.success(()))
                } else {
                    let message = evalError?.localizedDescription ?? "Autenticación fallida"
                    completion(.failure(APIError(message: message)))
                }
            }
        }
    }
}
