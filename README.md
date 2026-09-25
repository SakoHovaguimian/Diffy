# Diffy

A native macOS comparison workspace with live Git repositories, GitHub accounts, persistent PR AI reviews, read-only comparisons, and explicit repository actions. The separate Mock target preserves the interactive prototype and immutable fixtures. See [GitHub and Git setup](docs/GITHUB_SETUP.md) and [AI review setup](docs/AI_REVIEW.md).

Open **Diffy.xcodeproj**, select **Diffy Live** or **Diffy Mock**, and use **My Mac** as the destination. The project targets macOS 14 and Swift 6. There are no third-party package dependencies. Xcode builds have not been run as part of this work.

## Explore the prototype

1. The app opens Rune's text comparison. Switch between Split and Unified, resize the workspace, navigate changes, or adjust display options.
2. Use the file navigator's menus to switch folder/flat/grouped views, sort by recency or change size, and filter statuses. Settings are remembered per project.
3. Click a line and Shift-click another line on the same side to select a range. Choose **Annotate**, or right-click a line. Notes persist locally.
4. Open **Review Notes** with Shift-Command-R. Edit, resolve, reopen, or delete a note with undo. Export all notes in the comparison, project, or all projects as Markdown, with a preview before copy/save.
5. Open `Welcome.png` for image comparisons, including overlay, reveal slider, difference, blink, zoom, pan, and pixel inspection in single-canvas modes.
6. Open **Merge** for three source panes and an editable result. Accept a side, combine both, keep the base, navigate conflicts, and undo/reset. Everything edits a temporary draft.
7. Open a project overview, explore sample commits/branches, customize a Bucket, or drag a project into another Bucket. Use the outlined Add New Project row to select a local folder and choose its name and icon. Drag a project into Unassigned to detach it from its Bucket.
8. Open Settings with Command-comma. Porcelain follows the provided light references; Safira is adapted from the installed Safira theme. Command-K opens the command palette.

In Mock mode, source files, images, and merge inputs are fixed fixtures. In Live mode, added repositories show actual changes, branches, history, and Git actions. Annotations, captured snippets, local folder references, and preferences are stored separately. Exporting creates only the file selected in the native save panel. Moving or detaching a project cannot affect a folder on disk.

## Project organization

The structure follows Grimoire's conventions: feature-owned Screen/ViewModel pairs, protocol-based services, constructor injection, small assembly files, app-owned reusable components, separated models, explicit target membership, and spacious code.

- `Diffy/App`: app scenes and native command menus.
- `Diffy/DI`: runtime-specific application, service, and view-model assembly.
- `Diffy/DI/Mock`: isolated preview composition with in-memory persistence.
- `Diffy/Screens`: feature-owned screens, view models, and local components.
- `Diffy/Services`: workspace fixtures, preferences, annotations, exports, syntax presentation, and themes.
- `Diffy/Controllers`: AppKit interactions such as clipboard and save panels.
- `Diffy/Components`: app-owned UI and editor primitives.
- `Diffy/Models`: independent workspace, comparison, review, and preference models.

Dependency assembly uses explicit constructors. It preserves the ownership pattern from Grimoire without adding FactoryKit or its iOS-specific services to this prototype.

## SwiftUI previews

Core screens have isolated `#Preview` entry points. Use `mockResolve` for view models or service protocols, then apply `.withMockPreviews()` to inject the mock settings, review model, and theme in one line:

```swift
#Preview {
    WorkspaceScreen(viewModel: mockResolve(WorkspaceViewModel.self))
        .withMockPreviews()
}
```

`MockPreviewFixtures` supplies representative files, annotations, and diff regions. The resolver uses in-memory preferences and annotations; previews never read or write saved user data.

## Local data

Preferences use the app’s UserDefaults domain. The Live project library and account metadata use Application Support/Diffy; GitHub credentials use macOS Keychain. Annotations use `Diffy/annotations-v1.json`. Live is configured for direct distribution without App Sandbox so Git can use the Mac’s configuration, SSH agent, and credentials. Mock remains sandboxed with no network access or Live source membership.

Unreadable annotation storage is reported and protected against overwrite. New in-memory notes remain exportable if storage fails. SwiftUI previews use in-memory services and do not share saved notes or preferences.

## Verification

- Swift 6 source syntax and type checking against the macOS 14 deployment target.
- SwiftLint with `.swiftlint.yml`; expanded-block blank lines are intentional.
- Project/entitlement plist validation and explicit source-target membership inspection.
- No tests written. No Xcode builds, app launches, runtime UI checks, or visual screenshot verification performed.

Run installed SwiftLint with:

```sh
swiftlint lint --config .swiftlint.yml --strict --no-cache
```

After adding or moving source files, refresh explicit project references with:

```sh
python3 scripts/generate_project.py
```

The generator only writes project metadata and the shared scheme. It does not build or launch the app. Preserve deliberate project-setting changes in the generator before refreshing it.

## Scope and remaining work

The current scope includes Git/GitHub integration. Runtime and visual approval remain separate from source verification. See [Milestone 0 Status](docs/MILESTONE_0_STATUS.md) for implemented behavior and the remaining work. The full product specification is in [PRODUCT_BRIEF.md](PRODUCT_BRIEF.md), with [annotation export requirements](ANNOTATION_EXPORT.md) and [development style](DEVELOPMENT_STYLE.md).
