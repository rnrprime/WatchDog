import SwiftUI

struct DaysCountdownView: View {
    enum Style {
        case compact, full, expired
    }

    let endDate: Date
    var style: Style = .compact

    private var days: Int {
        Calendar.current.dateComponents([.day], from: .now, to: endDate).day ?? 0
    }

    private var color: Color {
        if days < 0 { return .statusExpired }
        if days <= 30 { return .statusExpiring }
        if days <= 90 { return Color(red: 1.0, green: 0.75, blue: 0.0) }
        return .statusValid
    }

    private var text: String {
        let abs = Swift.abs(days)
        let unit = abs == 1 ? "day" : "days"
        switch style {
        case .compact:
            return days < 0 ? "Expired" : "\(days) \(unit)"
        case .full:
            return days < 0 ? "Expired \(abs) \(unit) ago" : "\(days) \(unit) remaining"
        case .expired:
            return "Expired \(abs) \(unit) ago"
        }
    }

    var body: some View {
        Text(text)
            .font(style == .full ? .headline : .subheadline)
            .foregroundStyle(color)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        DaysCountdownView(endDate: .now.addingTimeInterval(-3 * 86400), style: .full)
        DaysCountdownView(endDate: .now, style: .compact)
        DaysCountdownView(endDate: .now.addingTimeInterval(14 * 86400), style: .compact)
        DaysCountdownView(endDate: .now.addingTimeInterval(60 * 86400), style: .full)
        DaysCountdownView(endDate: .now.addingTimeInterval(365 * 86400), style: .compact)
    }
    .padding()
}
