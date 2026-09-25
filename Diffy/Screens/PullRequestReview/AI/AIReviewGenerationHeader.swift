import SwiftUI

struct AIReviewGenerationHeader: View {

    let generation: AIReviewGeneration
    let revisionStatus: AIReviewRevisionStatus
    let isGenerating: Bool
    let regenerate: () -> Void
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        VStack(alignment: .leading, spacing: 11) {

            HStack(alignment: .firstTextBaseline, spacing: 12) {

                Text(self.generation.visualizationType.title)
                    .font(.system(size: 18, weight: .semibold))
                Spacer(minLength: 8)
                Text(self.generation.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 11))
                    .foregroundStyle(self.theme.secondaryText)

            }
            HStack(spacing: 8) {

                DiffyBadge(title: self.generation.provider.title, color: self.theme.accent, size: .small)
                Text(self.generation.model)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(self.theme.secondaryText)
                Text("·")
                    .foregroundStyle(self.theme.secondaryText)
                Text(self.generation.route.title)
                    .font(.system(size: 11))
                    .foregroundStyle(self.theme.secondaryText)
                Spacer(minLength: 8)
                Text("\(String(self.generation.baseSHA.prefix(7))) → \(String(self.generation.headSHA.prefix(7)))")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(self.theme.secondaryText)

            }
            if self.generation.visualizationType != .riskMap {

                Text("Patch text sent: \(self.patchPaths.count) of \(self.generation.context.fileInventory.count) listed files · \(self.shortenedPatchPaths.count) shortened")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(self.hasCompletePatchCoverage ? self.theme.secondaryText : self.theme.modified)

            }
            if !self.generation.context.omissions.isEmpty || self.generation.visualizationType != .riskMap {

                DisclosureGroup("Context Used For This Saved Review") {

                    contextCoverage()
                    ForEach(self.generation.context.omissions, id: \.self) { omission in
                        Text(omission)
                            .font(.system(size: 11))
                            .foregroundStyle(self.theme.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                }
                .font(.system(size: 11, weight: .medium))

            }
            if case .outdated = self.revisionStatus {

                HStack(spacing: 12) {

                    Label("Analyzed Before The Latest PR Changes", systemImage: "clock.arrow.circlepath")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(self.theme.modified)
                    Spacer(minLength: 8)
                    Button("Regenerate For Latest Changes", action: self.regenerate)
                        .disabled(self.isGenerating)

                }
                .padding(10)
                .background(self.theme.modified.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))

            }
            if case .unknown = self.revisionStatus {
                DiffyStatusBanner(message: "Current PR revision unavailable. This review belongs to the saved base and head revisions.")
            }

        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(self.theme.surface)
        .overlay(alignment: .bottom) { self.theme.border.frame(height: 1) }

    }

    private var patchPaths: Set<String> {
        self.generation.context.patchPaths
    }

    private var hasCompletePatchCoverage: Bool {
        self.generation.context.fileInventory.count == self.generation.analyzedFiles.count
            && self.patchPaths.count == self.generation.context.fileInventory.count
            && self.shortenedPatchPaths.isEmpty
    }

    private var pathsWithoutFileDetails: [String] {

        let detailedPaths = Set(self.generation.context.files.map(\.filename))
        return self.generation.context.fileInventory.filter { !detailedPaths.contains($0) }

    }

    private var filesWithoutPatchText: [String] {
        self.generation.context.files.filter { $0.patch?.isEmpty ?? true }.map(\.filename)
    }

    private var shortenedPatchPaths: [String] {

        let originalPatches = Dictionary(uniqueKeysWithValues: self.generation.analyzedFiles.compactMap { file in
            file.patch.map { (file.filename, $0) }
        })

        return self.generation.context.files.compactMap { file in
            guard let original = originalPatches[file.filename],
                  let sent = file.patch,
                  sent.count < original.count else { return nil }
            return file.filename
        }

    }

    @ViewBuilder
    private func contextCoverage() -> some View {

        if self.generation.visualizationType != .riskMap {

            let listedCount = self.generation.context.fileInventory.count
            let changedCount = self.generation.analyzedFiles.count
            Text("File paths listed: \(listedCount) of \(changedCount) loaded changed files.")
            Text("Patch text sent: \(self.patchPaths.count) of \(listedCount) listed files.")
            Text("Paths and change counts alone do not give the AI the file's code changes.")

            if !self.pathsWithoutFileDetails.isEmpty {
                DisclosureGroup("Path only (\(self.pathsWithoutFileDetails.count))") {
                    ForEach(self.pathsWithoutFileDetails, id: \.self) { path in
                        Text(path)
                    }
                }
            }

            if !self.filesWithoutPatchText.isEmpty {
                DisclosureGroup("File metadata, no patch text (\(self.filesWithoutPatchText.count))") {
                    ForEach(self.filesWithoutPatchText, id: \.self) { path in
                        Text(path)
                    }
                }
            }

            if !self.shortenedPatchPaths.isEmpty {
                DisclosureGroup("Patch text shortened by Diffy (\(self.shortenedPatchPaths.count))") {
                    ForEach(self.shortenedPatchPaths, id: \.self) { path in
                        Text(path)
                    }
                }
            }

        }

    }

}
