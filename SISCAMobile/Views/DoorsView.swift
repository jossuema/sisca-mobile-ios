import SwiftUI

/// Lista de aulas disponibles. Port de `DoorsScreen` (Android).
struct DoorsView: View {
    @EnvironmentObject private var session: SessionStore
    @StateObject private var vm = ClassroomViewModel()
    @Binding var path: [Route]

    var body: some View {
        VStack(spacing: 0) {
            // Cabecera
            HStack {
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

            Spacer().frame(height: 10)

            Text("Aulas disponibles a las que puedes acceder:")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppColor.bodyText)

            Spacer().frame(height: 10)

            ScrollView {
                VStack(spacing: 0) {
                    if vm.isLoading {
                        ProgressView().padding()
                    } else if vm.spaces.isEmpty {
                        Text("No hay aulas disponibles.")
                            .padding()
                    } else {
                        ForEach(vm.spaces) { classroom in
                            ClassroomItem(classroom: classroom) {
                                UserStore.saveSelectedClassroom(classroom)
                                path.append(.access(classroom))
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }

            Spacer().frame(height: 20)
            Footer()
        }
        .background(Color.white)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if let user = session.user {
                vm.loadSpaces(username: user.usuario)
            } else {
                session.logout()
            }
        }
    }
}

private struct ClassroomItem: View {
    let classroom: Classroom
    let onTap: () -> Void

    var body: some View {
        HStack {
            Text(classroom.enombre)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white)
            Spacer()
            Button(action: onTap) {
                Text("ACCEDER")
                    .foregroundColor(.white)
                    .font(.system(size: 15))
                    .frame(width: 118, height: 50)
                    .background(AppColor.accessButton)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        }
        .padding(16)
        .frame(height: 80)
        .frame(maxWidth: .infinity)
        .background(AppColor.classroomCard.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.vertical, 8)
    }
}
