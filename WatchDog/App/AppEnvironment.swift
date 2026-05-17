import SwiftUI

private struct SupabaseServiceKey: EnvironmentKey {
    @MainActor
    static var defaultValue: SupabaseService { .shared }
}

extension EnvironmentValues {
    var supabase: SupabaseService {
        get { self[SupabaseServiceKey.self] }
        set { self[SupabaseServiceKey.self] = newValue }
    }
}
