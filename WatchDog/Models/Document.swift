import Foundation
import SwiftData

@Model
final class Document {
    var id: UUID = UUID()
    var supabaseId: UUID?
    var entityType: String = ""
    var entityId: UUID = UUID()
    var docType: DocType = DocType.other
    var storagePath: String = ""
    var fileSize: Int64?
    var mimeType: String?
    var uploadedAt: Date = Date.now

    init(
        entityType: String,
        entityId: UUID,
        docType: DocType,
        storagePath: String,
        fileSize: Int64? = nil,
        mimeType: String? = nil
    ) {
        self.entityType = entityType
        self.entityId = entityId
        self.docType = docType
        self.storagePath = storagePath
        self.fileSize = fileSize
        self.mimeType = mimeType
    }
}
