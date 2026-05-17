import SwiftUI

struct ConfirmDeleteDialog: ViewModifier {
    @Binding var isPresented: Bool
    let itemName: String
    let onConfirm: () -> Void

    func body(content: Content) -> some View {
        content.confirmationDialog(
            "Delete \(itemName)?",
            isPresented: $isPresented,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { onConfirm() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This can't be undone.")
        }
    }
}

extension View {
    func confirmDelete(
        isPresented: Binding<Bool>,
        itemName: String,
        onConfirm: @escaping () -> Void
    ) -> some View {
        modifier(ConfirmDeleteDialog(
            isPresented: isPresented,
            itemName: itemName,
            onConfirm: onConfirm
        ))
    }
}
