import Foundation
import SwiftData
import UIKit
import Supabase

enum StorageError: LocalizedError {
    case fileTooLarge
    case notAuthenticated
    case uploadFailed(String)
    case missingImage
    case unknown

    var errorDescription: String? {
        switch self {
        case .fileTooLarge: "File is too large. Max 20MB."
        case .notAuthenticated: "Please sign in to upload documents."
        case .uploadFailed(let reason): "Upload failed: \(reason)"
        case .missingImage: "Image data was unavailable."
        case .unknown: "Something went wrong."
        }
    }
}

struct DocumentPayload: Codable {
    let id: String
    let user_id: String
    let entity_type: String
    let entity_id: String
    let doc_type: String
    let storage_path: String
    let file_size: Int64?
    let mime_type: String?
}

@Observable
@MainActor
final class StorageService {
    static let shared = StorageService()

    var uploadProgress: [UUID: Double] = [:]
    var isUploading: Bool = false
    var lastUploadError: String? = nil

    static let maxFileSizeBytes: Int = 20_000_000
    static let maxImageDimension: CGFloat = 1920

    private init() {}

    private var client: SupabaseClient {
        SupabaseService.shared.client
    }

    private var userIdString: String? {
        SupabaseService.shared.currentUser?.id.uuidString
    }

    private var isGuestMode: Bool {
        UserDefaults.standard.bool(forKey: "isGuestMode")
    }

    private var modelContainer: ModelContainer? {
        SyncService.shared.modelContainer
    }

    @discardableResult
    func uploadImage(
        _ image: UIImage,
        entityType: String,
        entityId: UUID,
        docType: DocType
    ) async throws -> Document {
        guard let data = compressImage(image) else {
            throw StorageError.missingImage
        }
        guard data.count <= Self.maxFileSizeBytes else {
            throw StorageError.fileTooLarge
        }

        let document = try await performUpload(
            data: data,
            contentType: "image/jpeg",
            fileExtension: "jpg",
            entityType: entityType,
            entityId: entityId,
            docType: docType
        )
        return document
    }

    @discardableResult
    func uploadPDF(
        _ data: Data,
        fileName: String,
        entityType: String,
        entityId: UUID,
        docType: DocType
    ) async throws -> Document {
        guard data.count <= Self.maxFileSizeBytes else {
            throw StorageError.fileTooLarge
        }
        return try await performUpload(
            data: data,
            contentType: "application/pdf",
            fileExtension: "pdf",
            entityType: entityType,
            entityId: entityId,
            docType: docType
        )
    }

    private func performUpload(
        data: Data,
        contentType: String,
        fileExtension: String,
        entityType: String,
        entityId: UUID,
        docType: DocType
    ) async throws -> Document {
        let uploadId = UUID()
        isUploading = true
        uploadProgress[uploadId] = 0
        defer {
            uploadProgress.removeValue(forKey: uploadId)
            if uploadProgress.isEmpty { isUploading = false }
        }

        guard !isGuestMode else {
            return try insertLocalDocument(
                storagePath: "local/\(uploadId.uuidString).\(fileExtension)",
                fileSize: Int64(data.count),
                mimeType: contentType,
                entityType: entityType,
                entityId: entityId,
                docType: docType,
                userIdString: nil
            )
        }

        guard let userIdString else {
            throw StorageError.notAuthenticated
        }

        let storagePath = "\(userIdString)/\(entityType)/\(entityId.uuidString)/\(uploadId.uuidString).\(fileExtension)"

        do {
            _ = try await client.storage
                .from("documents")
                .upload(
                    storagePath,
                    data: data,
                    options: FileOptions(contentType: contentType, upsert: false)
                )
        } catch {
            lastUploadError = error.localizedDescription
            CrashReporter.logError(error, context: [
                "stage": "storage_upload",
                "content_type": contentType,
                "size_bytes": data.count
            ])
            BannerManager.shared.showError("Upload failed — we'll retry shortly.")
            throw StorageError.uploadFailed(error.localizedDescription)
        }

        let document = try insertLocalDocument(
            storagePath: storagePath,
            fileSize: Int64(data.count),
            mimeType: contentType,
            entityType: entityType,
            entityId: entityId,
            docType: docType,
            userIdString: userIdString
        )

        if let supabaseId = document.supabaseId {
            let payload = DocumentPayload(
                id: supabaseId.uuidString,
                user_id: userIdString,
                entity_type: entityType,
                entity_id: entityId.uuidString,
                doc_type: docType.rawValue,
                storage_path: storagePath,
                file_size: document.fileSize,
                mime_type: document.mimeType
            )
            do {
                try await client.from("documents").insert(payload).execute()
            } catch {
                CrashReporter.logError(error, context: ["stage": "documents_row_insert"])
                #if DEBUG
                print("[Storage] documents row insert failed: \(error)")
                #endif
            }
        }

        AnalyticsService.shared.track(.documentUploaded(type: docType.rawValue))
        return document
    }

    private func insertLocalDocument(
        storagePath: String,
        fileSize: Int64,
        mimeType: String,
        entityType: String,
        entityId: UUID,
        docType: DocType,
        userIdString: String?
    ) throws -> Document {
        guard let container = modelContainer else {
            throw StorageError.unknown
        }
        let context = ModelContext(container)
        let document = Document(
            entityType: entityType,
            entityId: entityId,
            docType: docType,
            storagePath: storagePath,
            fileSize: fileSize,
            mimeType: mimeType
        )
        document.supabaseId = document.id
        context.insert(document)
        try context.save()
        return document
    }

    func getSignedURL(for document: Document) async throws -> URL {
        if isGuestMode || document.storagePath.hasPrefix("local/") {
            throw StorageError.notAuthenticated
        }
        do {
            return try await client.storage
                .from("documents")
                .createSignedURL(path: document.storagePath, expiresIn: 3600)
        } catch {
            throw StorageError.uploadFailed(error.localizedDescription)
        }
    }

    func deleteDocument(_ document: Document) async throws {
        let path = document.storagePath
        let supabaseId = document.supabaseId

        if !isGuestMode, !path.hasPrefix("local/") {
            do {
                _ = try await client.storage
                    .from("documents")
                    .remove(paths: [path])
            } catch {
                #if DEBUG
                print("[Storage] remove from bucket failed: \(error)")
                #endif
            }
            if let id = supabaseId {
                do {
                    try await client.from("documents")
                        .delete()
                        .eq("id", value: id.uuidString)
                        .execute()
                } catch {
                    #if DEBUG
                    print("[Storage] delete row failed: \(error)")
                    #endif
                }
            }
        }

        if let container = modelContainer {
            let context = ModelContext(container)
            let docId = document.id
            if let local = try? context.fetch(
                FetchDescriptor<Document>(predicate: #Predicate { $0.id == docId })
            ).first {
                context.delete(local)
                try? context.save()
            }
        }
    }

    private func compressImage(_ image: UIImage) -> Data? {
        let size = image.size
        let maxDim = Self.maxImageDimension
        let longest = max(size.width, size.height)
        let scale = longest > maxDim ? maxDim / longest : 1.0

        if scale >= 1.0 {
            return image.jpegData(compressionQuality: 0.8)
        }

        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return resized.jpegData(compressionQuality: 0.8)
    }
}
