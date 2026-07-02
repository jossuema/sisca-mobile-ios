import SwiftUI

/// Pantalla de inicio de sesión. Port de `LoginScreen` (Android).
struct LoginView: View {
    @EnvironmentObject private var session: SessionStore
    @StateObject private var vm = AuthViewModel()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppColor.loginGradientTop, .white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 50)

                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 116, height: 95)

                Spacer().frame(height: 30)
                Text("INICIAR SESIÓN")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppColor.title)

                Spacer().frame(height: 20)
                Text("Ingrese sus credenciales institucionales")
                    .font(.system(size: 10))
                    .foregroundColor(AppColor.subtitle)

                Spacer().frame(height: 10)

                InputField(placeholder: "Usuario", text: $vm.email)
                Spacer().frame(height: 10)
                InputField(placeholder: "Contraseña", text: $vm.password, isSecure: true)

                Spacer().frame(height: 20)

                if let error = vm.errorMessage, !error.isEmpty {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.system(size: 12))
                        .lineLimit(3)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                }

                Button(action: { vm.login() }) {
                    if vm.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("CONTINUAR")
                            .foregroundColor(.white)
                            .font(.system(size: 13))
                    }
                }
                .frame(width: 271, height: 40)
                .background(AppColor.primaryButton)
                .clipShape(RoundedRectangle(cornerRadius: 30))
                .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.black, lineWidth: 1))
                .disabled(vm.isLoading)

                Spacer().frame(height: 20)
                Footer()
            }
            .padding(20)
        }
        .onChange(of: vm.isAuthenticated) { authenticated in
            if authenticated, let user = UserStore.getUser() {
                session.setUser(user)
            }
        }
    }
}

/// Campo de texto con estilo (OutlinedTextField equivalente).
struct InputField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false

    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
            }
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.5), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .padding(.horizontal, 20)
    }
}
