import Foundation
import CryptoKit

extension String {
    /// MD5 en hexadecimal minúscula. Equivalente a `String.toMd5()` en Android.
    /// La API exige la contraseña en MD5 por diseño del backend.
    func toMd5() -> String {
        let digest = Insecure.MD5.hash(data: Data(self.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
