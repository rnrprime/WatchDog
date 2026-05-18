import SwiftUI
import SwiftData
import UIKit
import PhotosUI

struct ApplianceDetailView: View {
    let appliance: Appliance

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var documents: [Document]

    @State private var showCopiedToast = false
    @State private var showEditSheet = false
    @State private var showDeleteConfirm = false

    @State private var remind90: Bool = true
    @State private var remind30: Bool = true
    @State private var remind7: Bool = true

    @State private var showAddDocSheet = false
    @State private var showCamera = false
    @State private var showPhotosPicker = false
    @State private var showPDFPicker = false
    @State private var photoItem: PhotosPickerItem? = nil
    @State private var selectedDocument: Document? = nil

    init(appliance: Appliance) {
        self.appliance = appliance
        let entityId = appliance.id
        let predicate = #Predicate<Document> {
            $0.entityType == "appliance" && $0.entityId == entityId
        }
        _documents = Query(filter: predicate, sort: \.uploadedAt, order: .reverse)
    }

    private var primaryWarranty: Warranty? {
        appliance.warranties.max(by: { $0.endDate < $1.endDate })
    }

    private var categoryLabel: String {
        switch appliance.category {
        case .kitchen: "Kitchen"
        case .laundry: "Laundry"
        case .electronics: "Electronics"
        case .hvac: "HVAC"
        case .outdoor: "Outdoor"
        case .other: "Other"
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerCard
                warrantyCard
                detailsSection
                documentsSection
                remindersSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(Color(.systemBackground))
        .navigationTitle(appliance.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            AnalyticsService.shared.track(.applianceDetailViewed)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showEditSheet = true
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
        .confirmDelete(
            isPresented: $showDeleteConfirm,
            itemName: appliance.name
        ) {
            let supabaseId = appliance.supabaseId
            let warrantyIds = appliance.warranties.map(\.id)
            let warrantySupabaseIds = appliance.warranties.compactMap(\.supabaseId)

            modelContext.delete(appliance)
            try? modelContext.save()

            NotificationService.shared.cancelReminders(entityId: appliance.id)
            for id in warrantyIds {
                NotificationService.shared.cancelReminders(entityId: id)
            }

            if let id = supabaseId {
                Task {
                    await SyncService.shared.deleteFromCloud(
                        entityType: "appliances", supabaseId: id
                    )
                }
            }
            for id in warrantySupabaseIds {
                Task {
                    await SyncService.shared.deleteFromCloud(
                        entityType: "warranties", supabaseId: id
                    )
                }
            }

            dismiss()
        }
        .overlay(alignment: .top) {
            UploadProgressOverlay()
        }
        .overlay(alignment: .top) {
            if showCopiedToast {
                Text("Copied!")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.black.opacity(0.8)))
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

    private var headerCard: some View {
        HStack(alignment: .top, spacing: 16) {
            CategoryIconView(category: appliance.category, size: 80)

            VStack(alignment: .leading, spacing: 8) {
                Text(appliance.name)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Color(.label))
                    .multilineTextAlignment(.leading)

                FlexibleChipsRow(items: brandModelChips, categoryChip: categoryLabel)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var brandModelChips: [String] {
        var chips: [String] = []
        if let brand = appliance.brand, !brand.isEmpty { chips.append(brand) }
        if let model = appliance.model, !model.isEmpty { chips.append(model) }
        return chips
    }

    @ViewBuilder
    private var warrantyCard: some View {
        if let warranty = primaryWarranty {
            let days = Calendar.current
                .dateComponents([.day], from: .now, to: warranty.endDate)
                .day ?? 0
            if days >= 0 {
                activeWarrantyCard(warranty: warranty, days: days)
            } else {
                expiredWarrantyCard(days: days)
            }
        } else {
            noWarrantyCard
        }
    }

    private func activeWarrantyCard(warranty: Warranty, days: Int) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("WARRANTY STATUS")
                .font(.system(size: 13, weight: .semibold))
                .tracking(0.05)
                .foregroundStyle(Color.accentTeal.opacity(0.8))

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(days)")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(Color.accentTeal)
                Text(days == 1 ? "day remaining" : "days remaining")
                    .font(.system(size: 17))
                    .foregroundStyle(Color.accentTeal.opacity(0.8))
            }

            ProgressView(value: warrantyProgress(warranty: warranty))
                .tint(Color.accentTeal)

            HStack {
                dateBlock(label: "Started", date: warranty.startDate)
                Spacer()
                dateBlock(label: "Ends", date: warranty.endDate)
            }

            if let provider = warranty.provider, !provider.isEmpty {
                Text("Provider: \(provider)")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.accentTeal.opacity(0.7))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20).fill(Color.accentTealLight)
        )
    }

    private func expiredWarrantyCard(days: Int) -> some View {
        let absDays = abs(days)
        return VStack(alignment: .leading, spacing: 14) {
            Text("WARRANTY EXPIRED")
                .font(.system(size: 13, weight: .semibold))
                .tracking(0.05)
                .foregroundStyle(Color.statusExpired.opacity(0.85))

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(absDays)")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(Color.statusExpired)
                Text(absDays == 1 ? "day ago" : "days ago")
                    .font(.system(size: 17))
                    .foregroundStyle(Color.statusExpired.opacity(0.8))
            }

            PrimaryButton(title: "Add extended warranty") {
                DebugLog("[Detail] Add extended warranty")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.statusExpired.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.statusExpired.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private var noWarrantyCard: some View {
        VStack(spacing: 12) {
            Text("No warranty added")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
            SecondaryButton(title: "+ Add warranty") {
                DebugLog("[Detail] Add warranty")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func dateBlock(label: String, date: Date) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Color.accentTeal.opacity(0.7))
            Text(date, format: .dateTime.month(.abbreviated).day().year())
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.accentTeal)
        }
    }

    private func warrantyProgress(warranty: Warranty) -> Double {
        let total = warranty.endDate.timeIntervalSince(warranty.startDate)
        let elapsed = Date.now.timeIntervalSince(warranty.startDate)
        guard total > 0 else { return 0 }
        return min(1.0, max(0.0, elapsed / total))
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader("Details")
            VStack(spacing: 0) {
                DetailRow(
                    label: "Serial number",
                    value: appliance.serialNumber,
                    systemImage: "barcode",
                    isCopyable: true,
                    onCopy: { _ in showToast() }
                )
                DetailRow(
                    label: "Purchase date",
                    value: appliance.purchaseDate.map { formatted($0) },
                    systemImage: "calendar"
                )
                DetailRow(
                    label: "Purchase price",
                    value: formattedPrice(appliance.purchasePrice),
                    systemImage: "tag"
                )
                DetailRow(
                    label: "Store",
                    value: appliance.store,
                    systemImage: "storefront"
                )
                if let notes = appliance.notes, !notes.isEmpty {
                    DetailRow(
                        label: "Notes",
                        value: notes,
                        systemImage: "note.text"
                    )
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
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

    private func uploadImage(_ image: UIImage, docType: DocType = .receipt) {
        let id = appliance.id
        Task {
            _ = try? await StorageService.shared.uploadImage(
                image, entityType: "appliance", entityId: id, docType: docType
            )
        }
    }

    private func uploadPDF(_ data: Data, fileName: String) {
        let id = appliance.id
        Task {
            _ = try? await StorageService.shared.uploadPDF(
                data, fileName: fileName,
                entityType: "appliance", entityId: id, docType: .manual
            )
        }
    }

    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader("Reminders")
            VStack(spacing: 0) {
                reminderToggle(label: "90 days before expiry", binding: $remind90)
                divider
                reminderToggle(label: "30 days before expiry", binding: $remind30)
                divider
                reminderToggle(label: "7 days before expiry", binding: $remind7)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
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

    private func formatted(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day().year())
    }

    private func formattedPrice(_ price: Decimal?) -> String? {
        guard let price else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: price as NSDecimalNumber)
    }

    private func showToast() {
        withAnimation(.spring(duration: 0.3)) { showCopiedToast = true }
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            withAnimation(.spring(duration: 0.3)) { showCopiedToast = false }
        }
    }
}

private struct FlexibleChipsRow: View {
    let items: [String]
    let categoryChip: String

    var body: some View {
        HStack(spacing: 6) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(.label))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(Color(.tertiarySystemBackground))
                    )
            }
            Text(categoryChip)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.accentTeal)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.accentTealLight))
        }
    }
}
