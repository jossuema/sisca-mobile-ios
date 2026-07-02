import SwiftUI

/// Rutas del stack principal. La clase (Classroom) viaja como valor de ruta.
enum Route: Hashable {
    case access(Classroom)
    case signal
}

/// NavHost equivalente: doors (raíz) -> access -> signal.
struct MainNavigation: View {
    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            DoorsView(path: $path)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .access(let classroom):
                        AccessView(classroom: classroom, path: $path)
                    case .signal:
                        SignalSendingView(path: $path)
                    }
                }
        }
    }
}
