import SwiftUI

/// Raíz de la UI: muestra Login o el flujo principal según la sesión.
struct RootView: View {
    @StateObject private var session = SessionStore()

    var body: some View {
        Group {
            if session.isLoggedIn {
                MainNavigation()
            } else {
                LoginView()
            }
        }
        .environmentObject(session)
    }
}
