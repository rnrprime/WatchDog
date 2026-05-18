import SwiftUI

struct Step1_EntryMethod: View {
    @Bindable var viewModel: AddApplianceViewModel
    let onAdvance: () -> Void

    @State private var showSerialScanner = false
    @State private var showBarcodeScanner = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("How would you like to add it?")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color(.label))
                Text("Pick the fastest method")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            }

            Spacer().frame(height: 12)

            VStack(spacing: 12) {
                EntryMethodCard(
                    icon: "barcode.viewfinder",
                    title: "Scan serial number",
                    subtitle: "Fastest — just point your camera",
                    tag: "PRIMARY"
                ) {
                    viewModel.entryMethod = .scanSerial
                    showSerialScanner = true
                }

                EntryMethodCard(
                    icon: "barcode",
                    title: "Scan product barcode",
                    subtitle: "Auto-fill brand and model",
                    tag: nil
                ) {
                    viewModel.entryMethod = .scanBarcode
                    showBarcodeScanner = true
                }

                EntryMethodCard(
                    icon: "keyboard",
                    title: "Enter manually",
                    subtitle: "Type the details yourself",
                    tag: nil
                ) {
                    viewModel.entryMethod = .manual
                    onAdvance()
                }
            }
        }
        .padding(24)
        .fullScreenCover(isPresented: $showSerialScanner) {
            SerialNumberScannerView(
                onResult: { serial in
                    viewModel.serialNumber = serial
                    showSerialScanner = false
                    onAdvance()
                },
                onCancel: {
                    showSerialScanner = false
                    viewModel.entryMethod = nil
                }
            )
        }
        .fullScreenCover(isPresented: $showBarcodeScanner) {
            BarcodeScannerView(
                onResult: { brand, model in
                    if let brand, viewModel.brand.isEmpty {
                        viewModel.brand = brand
                    }
                    if let model, viewModel.model.isEmpty {
                        viewModel.model = model
                    }
                    showBarcodeScanner = false
                    BannerManager.shared.showSuccess("Brand & model auto-filled")
                    onAdvance()
                },
                onManualFallback: {
                    showBarcodeScanner = false
                    viewModel.entryMethod = .manual
                    onAdvance()
                },
                onCancel: {
                    showBarcodeScanner = false
                    viewModel.entryMethod = nil
                }
            )
        }
    }
}

private struct EntryMethodCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let tag: String?
    let action: () -> Void

    private var hasPrimaryTag: Bool { tag == "PRIMARY" }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.accentTealLight)
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Color.accentTeal)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color(.label))
                        if let tag {
                            Text(tag)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.accentTeal))
                        }
                    }
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .frame(minHeight: 90)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        hasPrimaryTag ? Color.accentTeal : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
