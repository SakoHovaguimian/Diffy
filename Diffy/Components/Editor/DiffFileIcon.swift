import SwiftUI

struct DiffFileIcon: View {

    let file: DiffFile
    var size: CGFloat = 12

    var body: some View {

        DiffyPathIcon(
            path: self.file.path,
            isBinary: self.file.kind == .binary,
            size: max(16, self.size)
        )

    }

}

#Preview {

    HStack(spacing: 20) {

        DiffFileIcon(file: MockPreviewFixtures.textFile, size: 20)
        DiffFileIcon(file: MockPreviewFixtures.imageFile, size: 20)
        DiffFileIcon(file: MockWorkspaceFixtures.projects[4].files[0], size: 20)

    }
    .padding(24)
    .withMockPreviews()

}
