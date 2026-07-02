import Foundation

/// Estado de sesión de la app. Determina si se muestra Login o el flujo principal
/// (equivalente al popUpTo("login") { inclusive } de Android tras autenticar).
@MainActor
final class SessionStore: ObservableObject {
    @Published var user: UserData?

    var isLoggedIn: Bool { user != nil }

    init() {
        user = UserStore.getUser()
    }

    func setUser(_ user: UserData) {
        UserStore.saveUser(user)
        self.user = user
    }

    func logout() {
        UserStore.clear()
        user = nil
    }
}
