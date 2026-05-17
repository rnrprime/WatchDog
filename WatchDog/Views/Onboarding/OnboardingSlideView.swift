import SwiftUI

struct OnboardingSlideView: View {
    let symbolName: String
    let title: String
    let subtitle: String
    var chips: [String] = []
    var checklist: [String] = []

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: symbolName)
                .font(.system(size: 160, weight: .regular))
                .foregroundStyle(Color.accentTeal)
                .accessibilityHidden(true)

            VStack(spacing: 16) {
                Text(title)
                    .font(.system(size: 28, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .foregroundStyle(Color(.label))

                Text(subtitle)
                    .font(.system(size: 17))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 40)
            }

            if !chips.isEmpty {
                ChipsRow(chips: chips)
                    .padding(.horizontal, 24)
            }

            if !checklist.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(checklist, id: \.self) { item in
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.accentTeal)
                                .font(.system(size: 18, weight: .semibold))
                            Text(item)
                                .font(.system(size: 15))
                                .foregroundStyle(Color(.label))
                        }
                    }
                }
                .padding(.horizontal, 40)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ChipsRow: View {
    let chips: [String]

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(chips, id: \.self) { chip in
                Text(chip)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.accentTeal)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.accentTealLight))
            }
        }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = computeRows(maxWidth: maxWidth, subviews: subviews)
        let height = rows.reduce(0) { $0 + $1.height } + CGFloat(max(0, rows.count - 1)) * spacing
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: min(width, maxWidth), height: height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let maxWidth = bounds.width
        let rows = computeRows(maxWidth: maxWidth, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            let rowWidth = row.width
            var x = bounds.minX + (maxWidth - rowWidth) / 2
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func computeRows(maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = [Row()]
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let current = rows[rows.count - 1]
            let projected = current.indices.isEmpty
                ? size.width
                : current.width + spacing + size.width
            if projected > maxWidth, !current.indices.isEmpty {
                rows.append(Row())
            }
            var row = rows[rows.count - 1]
            if !row.indices.isEmpty { row.width += spacing }
            row.indices.append(index)
            row.width += size.width
            row.height = max(row.height, size.height)
            rows[rows.count - 1] = row
        }
        return rows
    }
}

#Preview {
    OnboardingSlideView(
        symbolName: "shield.checkered",
        title: "Warranties. Passports. Everything.",
        subtitle: "Track what matters and get reminded before it's too late.",
        chips: ["Warranty reminders", "Passport expiry", "Receipt vault"]
    )
}
