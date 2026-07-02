import Foundation

/// Persistencia local con UserDefaults, equivalente a las funciones de `Data.kt`
/// (SharedPreferences + Gson) en Android.
enum UserStore {
    private static let userKey = "user_data"
    private static let classroomKey = "selected_classroom"
    private static let defaults = UserDefaults.standard

    static func saveUser(_ user: UserData) { save(user, key: userKey) }
    static func getUser() -> UserData? { load(UserData.self, key: userKey) }

    static func saveSelectedClassroom(_ classroom: Classroom) { save(classroom, key: classroomKey) }
    static func getSelectedClassroom() -> Classroom? { load(Classroom.self, key: classroomKey) }

    static func clear() {
        defaults.removeObject(forKey: userKey)
        defaults.removeObject(forKey: classroomKey)
    }

    private static func save<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        }
    }

    private static func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
