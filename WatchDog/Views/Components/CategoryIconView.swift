import SwiftUI

struct CategoryIconView: View {
    let category: ApplianceCategory
    var size: CGFloat = 44

    private var icon: String {
        switch category {
        case .kitchen: "refrigerator.fill"
        case .laundry: "washer.fill"
        case .electronics: "tv.fill"
        case .hvac: "fan.fill"
        case .outdoor: "leaf.fill"
        case .other: "shippingbox.fill"
        }
    }

    private var color: Color {
        switch category {
        case .kitchen: .orange
        case .laundry: .accentTeal
        case .electronics: .blue
        case .hvac: .gray
        case .outdoor: .green
        case .other: .purple
        }
    }

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.27)
            .fill(color.opacity(0.15))
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: icon)
                    .font(.system(size: size * 0.45, weight: .semibold))
                    .foregroundStyle(color)
            )
    }
}

struct ExpiryCategoryIconView: View {
    let category: ExpiryCategory
    var size: CGFloat = 44

    private var icon: String {
        switch category {
        case .document: "doc.fill"
        case .medication: "pill.fill"
        case .food: "fork.knife"
        case .subscription: "creditcard.fill"
        case .insurance: "shield.fill"
        case .vehicle: "car.fill"
        case .other: "tag.fill"
        }
    }

    private var color: Color {
        switch category {
        case .document: .blue
        case .medication: .red
        case .food: .orange
        case .subscription: .purple
        case .insurance: .accentTeal
        case .vehicle: .gray
        case .other: .brown
        }
    }

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.27)
            .fill(color.opacity(0.15))
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: icon)
                    .font(.system(size: size * 0.45, weight: .semibold))
                    .foregroundStyle(color)
            )
    }
}

#Preview {
    ScrollView {
        VStack(alignment: .leading, spacing: 20) {
            Text("Appliances").font(.headline)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60), spacing: 16)], spacing: 16) {
                ForEach(ApplianceCategory.allCases, id: \.self) { c in
                    VStack(spacing: 6) {
                        CategoryIconView(category: c)
                        Text(c.rawValue).font(.caption2)
                    }
                }
            }
            Text("Expiry").font(.headline)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60), spacing: 16)], spacing: 16) {
                ForEach(ExpiryCategory.allCases, id: \.self) { c in
                    VStack(spacing: 6) {
                        ExpiryCategoryIconView(category: c)
                        Text(c.rawValue).font(.caption2)
                    }
                }
            }
        }
        .padding()
    }
}
