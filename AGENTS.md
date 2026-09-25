# Diffy

Diffy is a native macOS SwiftUI application. The active work is **live Git and GitHub integration**, explicitly requested on September 24, 2026. The Mock target and previews retain immutable comparison fixtures.

## Standing rules

- Do not run Xcode builds unless explicitly asked. Do not write tests.
- Split independent models into separate files wherever practical, near their owning feature or service.
- Follow [DEVELOPMENT_STYLE.md](DEVELOPMENT_STYLE.md), especially small functions, explicit naming, and compact versus expanded block spacing.
- Preserve Grimoire's Screen/ViewModel organization, protocol-based services, constructor injection, feature ownership, and app-owned components. Reference `/Users/sakohovaguimian/Desktop/Personal/Grimoire/docs/IMPLEMENTATION_BEST_PRACTICES.md` when needed.
- UI state belongs in feature view models; AppKit interactions belong in focused controllers; reusable visual treatments belong in Diffy components.
- Keep source fixtures immutable. Store annotations, temporary merge results, and preferences separately.
- Live Git operations and GitHub authentication are authorized for the current integration milestone. Keep every mutation user-triggered and keep Live process/network/credential implementations out of the Mock target. See [docs/GITHUB_SETUP.md](docs/GITHUB_SETUP.md).
- Preserve user changes. Inspect existing equivalents before creating services, models, components, or helpers.
- Update live and mock composition when a service contract changes. Previews must remain isolated from persisted user data.
- New Swift files need explicit target membership. Use `scripts/generate_project.py`, preserving deliberate project changes in that generator.

## References

| Task | Reference |
| --- | --- |
| Product scope and milestone boundaries | [PRODUCT_BRIEF.md](PRODUCT_BRIEF.md) |
| Current implementation and gaps | [docs/MILESTONE_0_STATUS.md](docs/MILESTONE_0_STATUS.md) |
| Code style and source references | [DEVELOPMENT_STYLE.md](DEVELOPMENT_STYLE.md) |
| Annotations and review export | [ANNOTATION_EXPORT.md](ANNOTATION_EXPORT.md) |
| App construction | [AppAssembler.swift](Diffy/DI/AppAssembler.swift), [ServiceAssembly.swift](Diffy/DI/ServiceAssembly.swift), [ViewModelAssembly.swift](Diffy/DI/ViewModelAssembly.swift) |
| Workspace and navigation | [WorkspaceViewModel.swift](Diffy/Screens/Workspace/WorkspaceViewModel.swift) |
| Themes | [DiffyTheme.swift](Diffy/Services/DesignSystem/DiffyTheme.swift) |

Use source syntax/type checks, SwiftLint, plist validation, and source membership review as appropriate. These checks do not establish runtime or visual correctness. Report the distinction clearly.
