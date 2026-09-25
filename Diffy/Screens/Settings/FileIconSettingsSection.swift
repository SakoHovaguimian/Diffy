import SwiftUI

struct FileIconSettingsSection: View {

    @EnvironmentObject private var viewModel: SettingsViewModel

    private let samplePaths = [
        "index.ts", "App.tsx", "main.js", "Dockerfile",
        "data.json", "package.json", "main.py", "ContentView.swift",
        "main.go", "Cargo.toml", "README.md", ".gitignore",
        "index.html", "styles.css", "theme.scss", "App.vue",
        "App.svelte", "Main.java", "Main.kt", "main.c",
        "main.cpp", "Program.cs", "app.rb", "index.php",
        "schema.sql", "config.yaml", "setup.sh"
    ]

    var body: some View {

        Section("File & Folder Icons") {

            Picker("Icon Theme", selection: self.$viewModel.fileIconTheme) {

                ForEach(FileIconTheme.allCases) { iconTheme in
                    Text(iconTheme.title).tag(iconTheme)
                }

            }
            Text(self.viewModel.fileIconTheme.detail)
                .font(.caption)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 155), alignment: .leading)], alignment: .leading, spacing: 14) {

                ForEach(self.samplePaths, id: \.self) { path in

                    HStack(spacing: 6) {

                        DiffyPathIcon(path: path, size: 20)
                        Text(path)
                            .font(.system(size: 11, design: .monospaced))
                            .lineLimit(1)
                            .truncationMode(.middle)

                    }
                    .help(path)

                }

                HStack(spacing: 6) {

                    DiffyPathIcon(path: "src", isFolder: true, size: 20)
                    Text("src").font(.system(size: 11, design: .monospaced))

                }
                HStack(spacing: 6) {

                    DiffyPathIcon(path: "src", isFolder: true, isExpanded: true, size: 20)
                    Text("src · expanded").font(.system(size: 11, design: .monospaced))

                }

            }
            .padding(.vertical, 8)
            .environment(\.fileIconTheme, self.viewModel.fileIconTheme)

            Text("Applies immediately to every file browser and review. Icons are included with Diffy and work offline.")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let creditsURL = self.viewModel.fileIconTheme.creditsURL {

                Link("\(self.viewModel.fileIconTheme.title) · Credits", destination: creditsURL)
                    .font(.caption)

            }

        }

    }

}

#Preview {

    Form { FileIconSettingsSection() }
        .formStyle(.grouped)
        .frame(width: 720, height: 430)
        .withMockPreviews()

}
