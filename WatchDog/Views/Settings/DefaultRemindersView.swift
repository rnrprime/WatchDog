import SwiftUI

struct DefaultRemindersView: View {
    @AppStorage("warrantyReminder90") private var warrantyReminder90 = true
    @AppStorage("warrantyReminder30") private var warrantyReminder30 = true
    @AppStorage("warrantyReminder7") private var warrantyReminder7 = true
    @AppStorage("warrantyReminder1") private var warrantyReminder1 = true

    @AppStorage("expiryReminder30") private var expiryReminder30 = true
    @AppStorage("expiryReminder7") private var expiryReminder7 = true
    @AppStorage("expiryReminder1") private var expiryReminder1 = false

    var body: some View {
        Form {
            Section {
                Toggle("90 days before", isOn: $warrantyReminder90).tint(Color.accentTeal)
                Toggle("30 days before", isOn: $warrantyReminder30).tint(Color.accentTeal)
                Toggle("7 days before", isOn: $warrantyReminder7).tint(Color.accentTeal)
                Toggle("1 day before", isOn: $warrantyReminder1).tint(Color.accentTeal)
            } header: {
                Text("Warranty reminders")
            } footer: {
                Text("Defaults applied to new warranties. Existing reminders aren't changed.")
            }

            Section {
                Toggle("30 days before", isOn: $expiryReminder30).tint(Color.accentTeal)
                Toggle("7 days before", isOn: $expiryReminder7).tint(Color.accentTeal)
                Toggle("1 day before", isOn: $expiryReminder1).tint(Color.accentTeal)
            } header: {
                Text("Expiry reminders")
            } footer: {
                Text("Defaults applied to new expiring items.")
            }
        }
        .navigationTitle("Default reminders")
        .navigationBarTitleDisplayMode(.inline)
    }
}
