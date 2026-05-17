import Foundation
import Vision
import UIKit

struct OCRResult: Sendable {
    let rawText: String
    let purchaseDate: Date?
    let purchasePrice: Decimal?
    let brandName: String?
    let confidence: Double

    var isUseful: Bool {
        purchaseDate != nil || purchasePrice != nil || brandName != nil
    }

    static let empty = OCRResult(
        rawText: "",
        purchaseDate: nil,
        purchasePrice: nil,
        brandName: nil,
        confidence: 0
    )
}

actor OCRService {
    static let shared = OCRService()

    private static let knownBrands: [String] = [
        "Samsung", "LG", "Sony", "Bosch", "Whirlpool", "Daikin",
        "Mitsubishi", "Panasonic", "Philips", "Dyson", "Apple",
        "Xiaomi", "Haier", "KitchenAid", "GE", "Miele", "Siemens",
        "Frigidaire", "Maytag", "Hisense", "TCL", "Sharp", "Toshiba",
        "Electrolux", "Vizio"
    ]

    func processReceipt(image: UIImage) async -> OCRResult {
        await Task.detached(priority: .userInitiated) {
            Self.runOCR(image: image)
        }.value
    }

    private static func runOCR(image: UIImage) -> OCRResult {
        guard let cgImage = image.cgImage else { return .empty }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return .empty
        }

        guard let observations = request.results, !observations.isEmpty else {
            return .empty
        }

        var lines: [String] = []
        var confidences: [Float] = []
        for observation in observations {
            if let candidate = observation.topCandidates(1).first {
                lines.append(candidate.string)
                confidences.append(candidate.confidence)
            }
        }

        let rawText = lines.joined(separator: "\n")
        let avgConfidence = confidences.isEmpty
            ? 0
            : Double(confidences.reduce(0, +) / Float(confidences.count))

        let extracted = extractStructuredData(from: rawText)

        return OCRResult(
            rawText: rawText,
            purchaseDate: extracted.date,
            purchasePrice: extracted.price,
            brandName: extracted.brand,
            confidence: avgConfidence
        )
    }

    private static func extractStructuredData(
        from text: String
    ) -> (date: Date?, price: Decimal?, brand: String?) {
        (extractDate(from: text), extractPrice(from: text), extractBrand(from: text))
    }

    private static func extractBrand(from text: String) -> String? {
        let lower = text.lowercased()
        for brand in knownBrands where lower.contains(brand.lowercased()) {
            return brand
        }
        return nil
    }

    private static func extractDate(from text: String) -> Date? {
        let nsText = text as NSString

        func sanityCheck(_ date: Date) -> Date? {
            let year = Calendar.current.component(.year, from: date)
            let currentYear = Calendar.current.component(.year, from: .now)
            return (year >= 2000 && year <= currentYear + 1) ? date : nil
        }

        func parse(_ pattern: String, formats: [String]) -> Date? {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            else { return nil }
            let matches = regex.matches(
                in: text, range: NSRange(location: 0, length: nsText.length)
            )
            for match in matches {
                let str = nsText.substring(with: match.range)
                for format in formats {
                    let formatter = DateFormatter()
                    formatter.dateFormat = format
                    formatter.locale = Locale(identifier: "en_US_POSIX")
                    if let date = formatter.date(from: str), let valid = sanityCheck(date) {
                        return valid
                    }
                }
            }
            return nil
        }

        if let date = parse(#"\d{1,2}/\d{1,2}/\d{4}"#, formats: ["dd/MM/yyyy", "MM/dd/yyyy"]) {
            return date
        }
        if let date = parse(#"\d{1,2}-\d{1,2}-\d{4}"#, formats: ["dd-MM-yyyy", "MM-dd-yyyy"]) {
            return date
        }
        if let date = parse(#"\d{4}-\d{1,2}-\d{1,2}"#, formats: ["yyyy-MM-dd"]) {
            return date
        }
        if let date = parse(
            #"\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{4}"#,
            formats: ["d MMM yyyy", "d MMMM yyyy"]
        ) {
            return date
        }
        if let date = parse(
            #"(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{1,2},?\s+\d{4}"#,
            formats: ["MMM d, yyyy", "MMMM d, yyyy", "MMM d yyyy", "MMMM d yyyy"]
        ) {
            return date
        }
        return nil
    }

    private static func extractPrice(from text: String) -> Decimal? {
        let amountPattern = #"[\$£€]?\s*(\d+(?:[,]\d{3})*\.\d{2})"#
        guard let regex = try? NSRegularExpression(
            pattern: amountPattern, options: [.caseInsensitive]
        ) else { return nil }
        let nsText = text as NSString

        let totalKeywordPattern =
            #"(?:Total|Amount|Sum|Grand\s*Total|Balance)[^\n]*?[\$£€]?\s*(\d+(?:[,]\d{3})*\.\d{2})"#
        if let totalRegex = try? NSRegularExpression(
            pattern: totalKeywordPattern, options: [.caseInsensitive]
        ) {
            let totalMatches = totalRegex.matches(
                in: text, range: NSRange(location: 0, length: nsText.length)
            )
            if let last = totalMatches.last {
                let captured = nsText.substring(with: last.range(at: 1))
                if let decimal = decimalFromString(captured) {
                    return decimal
                }
            }
        }

        let matches = regex.matches(
            in: text, range: NSRange(location: 0, length: nsText.length)
        )
        var maxValue: Decimal? = nil
        for match in matches {
            let captured = nsText.substring(with: match.range(at: 1))
            if let decimal = decimalFromString(captured) {
                if maxValue == nil || decimal > (maxValue ?? 0) {
                    maxValue = decimal
                }
            }
        }
        return maxValue
    }

    private static func decimalFromString(_ str: String) -> Decimal? {
        let cleaned = str.replacingOccurrences(of: ",", with: "")
        return Decimal(string: cleaned)
    }
}
