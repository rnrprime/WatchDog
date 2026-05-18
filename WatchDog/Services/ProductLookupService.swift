import Foundation

/// Resolves a scanned barcode to a brand + model name. Tries Open Food Facts
/// first (broad coverage, no key required), then falls back to a tiny local
/// GS1-prefix dictionary that recognises common appliance manufacturers.
actor ProductLookupService {
    static let shared = ProductLookupService()

    struct Product: Sendable, Equatable {
        let brand: String?
        let model: String?
    }

    /// Common GS1 company prefixes for consumer-electronics / appliance brands.
    /// Not exhaustive — just enough that totally-unknown product lookups still
    /// produce a useful hint when Open Food Facts comes up empty.
    private let brandPrefixes: [(prefix: String, brand: String)] = [
        ("8801643", "Samsung"),
        ("8801031", "LG"),
        ("4548951", "Sony"),
        ("4901780", "Panasonic"),
        ("4902704", "Sharp"),
        ("4905524", "Toshiba"),
        ("4953170", "Daikin"),
        ("0085391", "Whirlpool"),
        ("0099487", "KitchenAid"),
        ("0048231", "GE"),
        ("4242002", "Bosch"),
        ("4242003", "Bosch"),
        ("4242004", "Siemens"),
        ("4060300", "Miele"),
        ("5025155", "Dyson"),
        ("5060175", "Dyson"),
        ("4980117", "Hisense"),
        ("8806084", "Vizio"),
        ("0078567", "Maytag"),
        ("0030878", "Frigidaire")
    ]

    func lookup(_ barcode: String) async -> Product? {
        let trimmed = barcode.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        if let online = try? await fetchOpenFoodFacts(barcode: trimmed),
           online.brand != nil || online.model != nil {
            return online
        }

        return prefixLookup(trimmed)
    }

    private func fetchOpenFoodFacts(barcode: String) async throws -> Product? {
        guard let url = URL(
            string: "https://world.openfoodfacts.org/api/v0/product/\(barcode).json"
        ) else { return nil }

        var request = URLRequest(url: url)
        request.timeoutInterval = 6
        request.setValue(
            "Watchdog iOS / 1.0 (contact: support@watchdog.app)",
            forHTTPHeaderField: "User-Agent"
        )

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            return nil
        }

        let payload = try JSONDecoder().decode(OpenFoodFactsResponse.self, from: data)
        guard payload.status == 1, let product = payload.product else { return nil }

        let modelName = product.product_name?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Product(
            brand: firstBrand(from: product.brands),
            model: (modelName?.isEmpty == false) ? modelName : nil
        )
    }

    private func firstBrand(from raw: String?) -> String? {
        guard let raw, !raw.isEmpty else { return nil }
        let trimmed = raw
            .components(separatedBy: ",")
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (trimmed?.isEmpty == false) ? trimmed : nil
    }

    private func prefixLookup(_ barcode: String) -> Product? {
        let digits = barcode.filter(\.isNumber)
        guard !digits.isEmpty else { return nil }
        for entry in brandPrefixes where digits.hasPrefix(entry.prefix) {
            return Product(brand: entry.brand, model: nil)
        }
        return nil
    }
}

private struct OpenFoodFactsResponse: Sendable {
    let status: Int
    let product: ProductPayload?
}

extension OpenFoodFactsResponse: Decodable {
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.status = try container.decode(Int.self, forKey: .status)
        self.product = try container.decodeIfPresent(ProductPayload.self, forKey: .product)
    }
    private enum CodingKeys: String, CodingKey { case status, product }
}

private struct ProductPayload: Sendable {
    let product_name: String?
    let brands: String?
}

extension ProductPayload: Decodable {
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.product_name = try container.decodeIfPresent(String.self, forKey: .product_name)
        self.brands = try container.decodeIfPresent(String.self, forKey: .brands)
    }
    private enum CodingKeys: String, CodingKey { case product_name, brands }
}
