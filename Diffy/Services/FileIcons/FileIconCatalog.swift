import Foundation

struct FileIconCatalog: Decodable {
    let light: FileIconAssociations
    let dark: FileIconAssociations
}
