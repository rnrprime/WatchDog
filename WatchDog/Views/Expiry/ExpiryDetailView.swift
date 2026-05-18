import SwiftUI
import SwiftData
import UIKit
import PhotosUI

struct ExpiryDetailView: View {
    let item: ExpiryItem

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var documents: [Document]

    @State private var showRenewSheet = false
    @State private var showDeleteConfirm = false
    @State private var showRenewedToast = false
    @State private var remind30: Bool = true
    @State private var remind7: Bool = true
    @State private var remind1: Bool = true

    @State private var showAddDocSheet = false
    @State private var showCamera = false
    @State private var showPhotosPicker = false
    @State private var showPDFPicker = false
    @State private var photoItem: PhotosPickerItem? = nil
    @State private var selectedDocument: Document? = nil

    init(item: ExpiryItem) {
        self.item = item
        let entityId = item.id
        let predicate = #Predicate<Document> {
            $0.entityType == "expiry" && $0.entityId == entityId
        }
        _documents = Query(filter: predicate, sort: \.uploadedAt, order: .reverse)
    }

    private var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: .now, to: item.expiryDate).day ?? 0
    }

    private var isExpired: Bool { item.expiryDate < .now }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerCard
                countdownCard
                detailsSection
                documentsSection
                remindersSection
                renewalHistorySection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(Color(.systemBackground))
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        DebugLog("[ExpiryDetail] Edit")
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(Color.accentTeal)
                }
            }
        }
        .confirmDelete(isPresented: $showDeleteConfirm, itemName: item.name) {
            let supabaseId = item.supabaseId
            let entityId = item.id
            modelContext.delete(item)
            try? modelContext.save()
            NotificationService.shared.cancelReminders(entityId: entityId)
            if let id = supabaseId {
                Task {
                    await SyncService.shared.deleteFromCloud(
                        entityType: "expiry_items", supabaseId: id
                    )
                }
            }
            dismiss()
        }
        .sheet(isPresented: $showRenewSheet) {
            RenewExpiryView(item: item) { _ in
                showToast()
            }
        }
        .overlay(alignment: .top) {
            UploadProgressOverlay()
        }
        .overlay(alignment: .top) {
            if showRenewedToast {
                Text("Renewed! Reminders updated.")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.black.opacity(0.85)))
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .confirmationDialog("Add document", isPresented: $showAddDocSheet, titleVisibility: .visible) {
            Button("Take photo") { showCamera = true }
            Button("Choose from library") { showPhotosPicker = true }
            Button("Pick a file (PDF)") { showPDFPicker = true }
            Button("Cancel", role: .cancel) {}
        }
        .photosPicker(isPresented: $showPhotosPicker, selection: $photoItem, matching: .images)
        .onChange(of: photoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    uploadImage(image, docType: .photo)
                }
                photoItem = nil
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in
                if let image { uploadImage(image, docType: .photo) }
                showCamera = false
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showPDFPicker) {
            PDFFilePicker { url in
                if let url, let data = try? Data(contentsOf: url) {
                    uploadPDF(data, fileName: url.lastPathComponent)
                }
            }
        }
        .navigationDestination(item: $selectedDocument) { doc in
            DocumentViewerView(document: doc) {
                selectedDocument = nil
            }
        }
    }

    private var documentsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader("Documents", action: {
                showAddDocSheet = true
            }, actionLabel: "+ Add")

            if documents.isEmpty {
                Button {
                    showAddDocSheet = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "doc.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.secondary)
                        Text("No documents yet — tap + to add")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.accentTeal)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemBackground))
                    )
                }
                .buttonStyle(.plain)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(documents) { doc in
                            DocumentThumbnail(
                                document: doc,
                                onTap: { selectedDocument = doc },
                                onDelete: { deleteDocument(doc) }
                            )
                        }
                    }
                }
                .scrollClipDisabled()
            }
        }
    }

    private func deleteDocument(_ doc: Document) {
        Task {
            try? await StorageService.shared.deleteDocument(doc)
        }
    }

    private func uploadImage(_ image: UIImage, docType: DocType) {
        let id = item.id
        Task {
            _ = try? await StorageService.shared.uploadImage(
                image, entityType: "expiry", entityId: id, docType: docType
            )
        }
    }

    private func uploadPDF(_ data: Data, fileName: String) {
        let id = item.id
        Task {
            _ = try? await StorageService.shared.uploadPDF(
                data, fileName: fileName,
                entityType: "expiry", entityId: id, docType: .other
            )
        }
    }

    private var headerCard: some View {
        HStack(alignment: .top, spacing: 16) {
            ExpiryCategoryIconView(category: item.category, size: 80)
            VStack(alignment: .leading, spacing: 8) {
                Text(item.name)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Color(.label))
                    .multilineTextAlignment(.leading)
                Text(categoryDisplayName(item.category))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.accentTeal)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.accentTealLight))
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var countdownCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            DaysCountdownView(endDate: item.expiryDate, style: .full)
                .font(.system(size: 48, weight: .semibold))

            Text(isExpired
                ? "Expired on \(formattedDate)"
                : "Expires on \(formattedDate)")
                .font(.system(size: 17))
                .foregroundStyle(.secondary)

            PrimaryButton(title: "Renew") {
                showRenewSheet = true
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(countdownBackground)
        )
    }

    private var countdownBackground: Color {
        if isExpired { return Color.statusExpired.opacity(0.1) }
        if daysRemaining <= 7 { return Color.orange.opacity(0.1) }
        if daysRemaining <= 30 { return Color(red: 1.0, green: 0.75, blue: 0.0).opacity(0.1) }
        return Color.accentTealLight
    }

    @ViewBuilder
    private var detailsSection: some View {
        if hasDetails {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader("Details")
                VStack(alignment: .leading, spacing: 12) {
                    if let notes = item.notes, !notes.isEmpty {
                        detailRow(label: "Notes", value: notes)
                    }
                    if item.isRecurring, let days = item.recurrenceIntervalDays {
                        detailRow(label: "Recurs every", value: "\(days) days")
                    }
                    if let quantity = item.quantity {
                        let qtyText = "\(quantity)\(item.unit.map { " \($0)" } ?? "")"
                        detailRow(label: "Quantity", value: qtyText)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                )
            }
        }
    }

    private var hasDetails: Bool {
        (item.notes?.isEmpty == false) || item.isRecurring || item.quantity != nil
    }

    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader("Reminders")
            VStack(spacing: 0) {
                reminderToggle(label: "30 days before", binding: $remind30)
                divider
                reminderToggle(label: "7 days before", binding: $remind7)
                divider
                reminderToggle(label: "1 day before", binding: $remind1)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }

    private var renewalHistorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader("Renewal history")
            Text("No renewals yet")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                )
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 16))
                .foregroundStyle(Color(.label))
        }
    }

    private func reminderToggle(label: String, binding: Binding<Bool>) -> some View {
        Toggle(isOn: binding) {
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(Color(.label))
        }
        .tint(Color.accentTeal)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color(.separator))
            .frame(height: 0.5)
            .padding(.leading, 16)
    }

    private var formattedDate: String {
        item.expiryDate.formatted(.dateTime.month(.wide).day().year())
    }

    private func categoryDisplayName(_ c: ExpiryCategory) -> String {
        switch c {
        case .document: "Document"
        case .medication: "Medication"
        case .food: "Food"
        case .subscription: "Subscription"
        case .insurance: "Insurance"
        case .vehicle: "Vehicle"
        case .other: "Other"
        }
    }

    private func showToast() {
        withAnimation(.spring(duration: 0.3)) { showRenewedToast = true }
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            withAnimation(.spring(duration: 0.3)) { showRenewedToast = false }
        }
    }
}
