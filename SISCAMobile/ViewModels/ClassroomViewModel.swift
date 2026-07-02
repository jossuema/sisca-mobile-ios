import Foundation

/// Carga las aulas del usuario. Port de `ClassroomViewModel` (Android).
@MainActor
final class ClassroomViewModel: ObservableObject {
    @Published var spaces: [Classroom] = []
    @Published var isLoading = false

    func loadSpaces(username: String) {
        isLoading = true
        Task {
            let result = await APIClient.getSpaces(username: username)
            isLoading = false
            switch result {
            case .success(let spaces): self.spaces = spaces
            case .failure: self.spaces = []
            }
        }
    }
}
