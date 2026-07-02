import Foundation

/// El backend PHP a veces devuelve números o booleanos como strings ("1", "true").
/// Estas ayudas hacen la decodificación tolerante, igual que Gson en Android.
extension KeyedDecodingContainer {
    func flexibleInt(_ key: Key) throws -> Int {
        if let i = try? decode(Int.self, forKey: key) { return i }
        if let d = try? decode(Double.self, forKey: key) { return Int(d) }
        if let s = try? decode(String.self, forKey: key), let i = Int(s) { return i }
        throw DecodingError.dataCorruptedError(
            forKey: key, in: self,
            debugDescription: "Se esperaba un entero para '\(key.stringValue)'"
        )
    }

    func flexibleBool(_ key: Key) throws -> Bool {
        if let b = try? decode(Bool.self, forKey: key) { return b }
        if let i = try? decode(Int.self, forKey: key) { return i != 0 }
        if let s = try? decode(String.self, forKey: key) {
            return s == "1" || s.lowercased() == "true"
        }
        throw DecodingError.dataCorruptedError(
            forKey: key, in: self,
            debugDescription: "Se esperaba un booleano para '\(key.stringValue)'"
        )
    }
}
