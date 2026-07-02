import SwiftUI

/// Elección del método de verificación. Port de `AccessScreen` (Android).
/// En iOS la huella y el reconocimiento facial se resuelven ambos con biometría nativa.
struct AccessView: View {
    let classroom: Classroom
    @Binding var path: [Route]

    @EnvironmentObject private var session: SessionStore
    @StateObject private var vm = AccessViewModel()
    @State private var alertMessage: String?
    @State private var authenticating = false

    var body: some View {
        VStack(spacing: 0) {
            // Cabecera con botón atrás
            HStack {
                Button(action: { if !path.isEmpty { path.removeLast() } }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.white)
                }
                Spacer()
                Text(session.user?.apenom ?? "Usuario no encontrado")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Image("utmach_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .background(AppColor.header)

            // Barra roja con el aula
            Text("\(classroom.enombre) - \(classroom.ecodigo)")
                .font(.system(size: 19, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(AppColor.redBar.opacity(0.9))

            Spacer().frame(height: 16)

            Image("facultad_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 250, height: 250)

            Spacer().frame(height: 16)

            Text("La Universidad del futuro pensando en ti!")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppColor.bodyText)

            Spacer().frame(height: 24)

            // En iOS la biometría nativa reemplaza tanto la huella como el reconocimiento facial:
            // se muestra un único método biométrico, etiquetado según el hardware del dispositivo.
            HStack {
                Spacer()
                AccessOption(title: vm.biometricLabel, imageName: vm.biometricIconName) {
                    authenticate()
                }
                Spacer()
                AccessOption(title: "PIN/Codigo", imageName: "pin_icon") { }
                Spacer()
            }

            Spacer()
            Footer()
        }
        .background(Color.white)
        .toolbar(.hidden, for: .navigationBar)
        .alert("Aviso", isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private func authenticate() {
        guard !authenticating else { return }   // evita apilar varias rutas .signal
        authenticating = true
        vm.authenticateBiometric { result in
            authenticating = false
            switch result {
            case .success:
                UserStore.saveSelectedClassroom(classroom)
                path.append(.signal)
            case .failure(let error):
                alertMessage = error.localizedDescription
            }
        }
    }
}

private struct AccessOption: View {
    let title: String
    let imageName: String
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Button(action: onTap) {
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white)
                        .shadow(radius: 4)
                        .frame(width: 100, height: 100)
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                }
            }
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.black)
        }
    }
}
