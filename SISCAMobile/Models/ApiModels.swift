import Foundation

/// Envoltura estándar de las respuestas del API (`{ success, status, data:[...] }`).
struct ApiResponseWrapper<T: Decodable>: Decodable {
    let success: Bool
    let status: Int
    let data: [T]

    enum CodingKeys: String, CodingKey { case success, status, data }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.success = (try? c.flexibleBool(.success)) ?? false
        self.status = (try? c.flexibleInt(.status)) ?? 0
        self.data = (try? c.decode([T].self, forKey: .data)) ?? []
    }
}

/// Datos del usuario autenticado. Se persiste en UserDefaults (Codable).
struct UserData: Codable, Equatable {
    let usuario: String
    let apenom: String
    let email: String?
    let documento: String?
    let foto: String?
    let docplectivo: String?
    let estplectivo: String?
    let valido: Int

    enum CodingKeys: String, CodingKey {
        case usuario, apenom, email, documento, foto, docplectivo, estplectivo, valido
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.usuario = (try? c.decode(String.self, forKey: .usuario)) ?? ""
        self.apenom = (try? c.decode(String.self, forKey: .apenom)) ?? ""
        self.email = try? c.decode(String.self, forKey: .email)
        self.documento = try? c.decode(String.self, forKey: .documento)
        self.foto = try? c.decode(String.self, forKey: .foto)
        self.docplectivo = try? c.decode(String.self, forKey: .docplectivo)
        self.estplectivo = try? c.decode(String.self, forKey: .estplectivo)
        self.valido = (try? c.flexibleInt(.valido)) ?? 0
    }
}

/// Aula/espacio al que el usuario tiene acceso. Codable (se persiste) y Hashable (ruta de navegación).
struct Classroom: Codable, Equatable, Hashable, Identifiable {
    let ecodigo: Int
    let enombre: String

    var id: Int { ecodigo }

    enum CodingKeys: String, CodingKey { case ecodigo, enombre }

    init(ecodigo: Int, enombre: String) {
        self.ecodigo = ecodigo
        self.enombre = enombre
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        // Default 0 (como Gson) para que una fila malformada no tumbe la lista completa de aulas.
        self.ecodigo = (try? c.flexibleInt(.ecodigo)) ?? 0
        self.enombre = (try? c.decode(String.self, forKey: .enombre)) ?? ""
    }
}

/// Token de acceso generado por el API (`gentokenesp`).
struct TokenData: Decodable {
    let user: String
    let ecodigo: Int
    let token: String
    let fcaduca: String

    enum CodingKeys: String, CodingKey { case user, ecodigo, token, fcaduca }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.user = (try? c.decode(String.self, forKey: .user)) ?? ""
        self.ecodigo = (try? c.flexibleInt(.ecodigo)) ?? 0
        self.token = (try? c.decode(String.self, forKey: .token)) ?? ""
        self.fcaduca = (try? c.decode(String.self, forKey: .fcaduca)) ?? ""
    }
}
