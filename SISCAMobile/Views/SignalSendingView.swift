import SwiftUI

/// Envío de la señal a la cerradura por BLE y visualización del veredicto real.
/// Port de `SignalSendingScreen` (Android).
struct SignalSendingView: View {
    @Binding var path: [Route]
    @StateObject private var vm = SignalViewModel()

    var body: some View {
        Group {
            switch vm.state {
            case .checking:
                centered { ProgressView() }

            case .useBluetooth:
                centered { Text("Enviando señal por Bluetooth...") }

            case .signalSent:
                TerminalState(
                    message: "✅ Acceso concedido: la cerradura se abrió",
                    onRetry: nil,
                    onBack: goBack
                )

            case .accessDenied(let message):
                TerminalState(
                    message: "🚫 \(message)",
                    onRetry: { vm.retry() },
                    onBack: goBack
                )

            case .error(let message):
                TerminalState(
                    message: "❌ Error: \(message)",
                    onRetry: { vm.retry() },
                    onBack: goBack
                )
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { vm.startIfNeeded() }
    }

    private func goBack() {
        if !path.isEmpty { path.removeLast() }
    }

    private func centered<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack { content() }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Estado final con mensaje y acciones (Reintentar opcional + Volver).
private struct TerminalState: View {
    let message: String
    let onRetry: (() -> Void)?
    let onBack: () -> Void

    var body: some View {
        VStack {
            Spacer()
            Text(message)
                .multilineTextAlignment(.center)
            if let onRetry {
                Button(action: onRetry) { Text("Reintentar") }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 24)
            }
            Button(action: onBack) { Text("Volver") }
                .buttonStyle(.bordered)
                .padding(.top, 8)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}
