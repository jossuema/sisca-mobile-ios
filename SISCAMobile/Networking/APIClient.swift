import Foundation

/// Error del API con mensaje legible (equivalente a las `Exception` con mensaje en Android).
struct APIError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

/// Cliente HTTP contra `consulta.php`. Equivale a AuthService / SpaceService / TokenService
/// (Retrofit) del proyecto Android, reimplementado con URLSession + async/await.
enum APIClient {

    // MARK: - Login (invusuariosisca)

    static func login(username: String, password: String) async -> Result<UserData, Error> {
        let url = makeURL(query: [
            "funcion": "invusuariosisca",
            "user": username,
            "pass": password,
            "pkey": AppConfig.apiPHKey,
        ])
        do {
            let wrapper: ApiResponseWrapper<UserData> = try await get(url)
            // Igual que Android (data[0].email != null): un email presente pero vacío ("") es válido;
            // solo se rechaza cuando el campo email está ausente o es null.
            if wrapper.success, let user = wrapper.data.first, user.email != nil {
                return .success(user)
            }
            return .failure(APIError(message: "Usuario o contraseña incorrectos"))
        } catch let error as APIError {
            return .failure(error)
        } catch {
            return .failure(APIError(message: "No se pudo conectar a la red. Intente nuevamente"))
        }
    }

    // MARK: - Aulas del usuario (lstespaciosxpersona)

    static func getSpaces(username: String) async -> Result<[Classroom], Error> {
        let url = makeURL(query: [
            "funcion": "lstespaciosxpersona",
            "user": username,
            "pkey": AppConfig.apiPHKey,
        ])
        do {
            let wrapper: ApiResponseWrapper<Classroom> = try await get(url)
            if wrapper.success, !wrapper.data.isEmpty {
                return .success(wrapper.data)
            }
            return .failure(APIError(message: "No se encontraron espacios para el usuario"))
        } catch let error as APIError {
            return .failure(error)
        } catch {
            return .failure(APIError(message: "No hay conexión a Internet"))
        }
    }

    // MARK: - Token de acceso (gentokenesp)

    static func getToken(spaceCode: Int, user: String) async -> Result<TokenData, Error> {
        let url = makeURL(query: [
            "funcion": "gentokenesp",
            "ecodigo": String(spaceCode),
            "pkey": AppConfig.apiPHKey,
            "user": user,
        ])
        do {
            let wrapper: ApiResponseWrapper<TokenData> = try await get(url)
            if wrapper.success, let token = wrapper.data.first {
                return .success(token)
            }
            return .failure(APIError(message: "No se encontró el token"))
        } catch {
            return .failure(error)
        }
    }

    // MARK: - Helpers

    private static func makeURL(query: [String: String]) -> URL {
        // API_URL termina en "/"; el endpoint es consulta.php con parámetros en el query string.
        var components = URLComponents(string: AppConfig.apiURL + "consulta.php")
        components?.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        return components?.url ?? URL(string: AppConfig.apiURL)!
    }

    private static func get<T: Decodable>(_ url: URL) async throws -> T {
        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw APIError(message: "Error de servidor: \(http.statusCode)")
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError(message: "Respuesta inválida del servidor")
        }
    }
}
