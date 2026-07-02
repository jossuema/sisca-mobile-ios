import Foundation

/// Lee los secretos desde `Config.plist` (no versionado), equivalente a `BuildConfig.*` en Android.
/// Copia `Config.plist.example` a `Config.plist` y completa `API_PHKEY`.
enum AppConfig {
    /// Base URL del backend. DEBE terminar en "/".
    static let apiURL: String = value(for: "API_URL")
    /// Llave de API (pkey) que exige el backend PHP.
    static let apiPHKey: String = value(for: "API_PHKEY")

    private static func value(for key: String) -> String {
        guard let url = Bundle.main.url(forResource: "Config", withExtension: "plist"),
              let dict = NSDictionary(contentsOf: url),
              let value = dict[key] as? String,
              !value.isEmpty else {
            assertionFailure("Falta '\(key)' en Config.plist. Copia Config.plist.example y complétalo.")
            return ""
        }
        return value
    }
}
