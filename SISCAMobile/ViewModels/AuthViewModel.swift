import Foundation

/// Login contra el API. Port de `AuthViewModel` (Android).
@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    @Published var isLoading = false

    func login() {
        errorMessage = nil

        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
           password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Todos los campos son obligatorios"
            return
        }
        if password.count < 6 {
            errorMessage = "La contraseña debe tener al menos 6 caracteres"
            return
        }

        isLoading = true
        Task {
            let result = await APIClient.login(username: email, password: password.toMd5())
            isLoading = false
            switch result {
            case .success(let user):
                UserStore.saveUser(user)
                isAuthenticated = true
            case .failure(let error):
                isAuthenticated = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
