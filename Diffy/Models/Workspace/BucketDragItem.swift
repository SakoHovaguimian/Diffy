import CoreTransferable
import UniformTypeIdentifiers

struct BucketDragItem: Codable, Transferable {

    let id: String

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .diffyBucket)
    }

}

private extension UTType {

    static let diffyBucket = UTType(exportedAs: "com.diffy.app.bucket")

}
