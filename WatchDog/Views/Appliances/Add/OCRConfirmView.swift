import SwiftUI

struct OCRConfirmView: View {
    let result: OCRResult
    let image: UIImage
    let onConfirm: (Date?, Decimal?, String?) -> Void
    let onRetake: () -> Void
    let onEnterManually: () -> Void

    @State private var editedDate: Date
    @State private var hasDate: Bool
    @State private var editedPriceText: String
    @State private var editedBrand: String

    init(
        result: OCRResult,
        image: UIImage,
        onConfirm: @escaping (Date?, Decimal?, String?) -> Void,
        onRetake: @escaping () -> Void,
        onEnterManually: @escaping () -> Void
    ) {
        self.result = result
        self.image = image
        self.onConfirm = onConfirm
        self.onRetake = onRetake
        self.onEnterManually = onEnterManually
        _editedDate = State(initialValue: result.purchaseDate ?? .now)
        _hasDate = State(initialValue: result.purchaseDate != nil)
        _editedPriceText = State(
            initialValue: result.purchasePrice.map { "\($0)" } ?? ""
        )
        _editedBrand = State(initialValue: result.brandName ?? "")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Color.clear.frame(height: 0).onAppear {
                        AnalyticsService.shared.track(.ocrScanAttempted)
                        if result.isUseful {
                            AnalyticsService.shared.track(
                                .ocrScanSucceeded(confidence: result.confidence)
                            )
                        }
                    }
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 120)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                    if result.confidence < 0.5 && !result.rawText.isEmpty {
                        confidenceBanner
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("What we found")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Color(.label))
                        Text(result.isUseful
                             ? "Tap any field to edit"
                             : "Couldn't read this receipt clearly")
                            .font(.system(size: 15))
                            .foregroundStyle(result.isUseful ? Color.secondary : Color.orange)
                    }

                    dateField
                    priceField
                    brandField

                    Spacer().frame(height: 8)

                    PrimaryButton(title: "Use this data") {
                        onConfirm(
                            hasDate ? editedDate : nil,
                            decimalFromText(editedPriceText),
                            editedBrand.isEmpty ? nil : editedBrand
                        )
                    }

                    SecondaryButton(title: "Retake scan", action: onRetake)

                    Button("Enter manually instead", action: onEnterManually)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .padding(24)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Confirm")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var confidenceBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text("Receipt was hard to read — please double-check the values")
                .font(.system(size: 13))
                .foregroundStyle(Color(.label))
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.12))
        )
    }

    private var dateField: some View {
        let detected = result.purchaseDate != nil
        return VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Purchase date", detected: detected)
            HStack(spacing: 10) {
                statusIcon(detected: detected)
                Toggle("", isOn: $hasDate).labelsHidden().tint(Color.accentTeal)
                if hasDate {
                    DatePicker("", selection: $editedDate, displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .tint(Color.accentTeal)
                } else {
                    Text("Not detected — toggle to add")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .frame(minHeight: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }

    private var priceField: some View {
        let detected = result.purchasePrice != nil
        return VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Purchase price", detected: detected)
            HStack(spacing: 10) {
                statusIcon(detected: detected)
                Text("$").foregroundStyle(.secondary)
                TextField(detected ? "" : "Not detected — tap to add", text: $editedPriceText)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 17))
            }
            .padding(.horizontal, 12)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }

    private var brandField: some View {
        let detected = result.brandName != nil
        return VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Brand", detected: detected)
            HStack(spacing: 10) {
                statusIcon(detected: detected)
                TextField(detected ? "" : "Not detected — tap to add", text: $editedBrand)
                    .font(.system(size: 17))
            }
            .padding(.horizontal, 12)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }

    private func statusIcon(detected: Bool) -> some View {
        Image(systemName: detected ? "checkmark.circle.fill" : "minus.circle")
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(detected ? Color.statusValid : Color(.tertiaryLabel))
    }

    private func sectionLabel(_ text: String, detected: Bool) -> some View {
        HStack(spacing: 6) {
            Text(text.uppercased())
                .font(.system(size: 13, weight: .semibold))
                .tracking(0.05)
                .foregroundStyle(.secondary)
            if detected {
                Text("• AUTO")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.accentTeal)
            }
        }
    }

    private func decimalFromText(_ text: String) -> Decimal? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        return Decimal(string: trimmed)
    }
}
