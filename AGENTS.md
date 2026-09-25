# Diffy

Diffy is a native macOS SwiftUI application. The active milestone is **Milestone 0: an interactive visual prototype with immutable mock comparison sources**.

## Standing rules

- Do not run Xcode builds unless explicitly asked. Do not write tests.
- Split independent models into separate files wherever practical, near their owning feature or service.
- Follow [DEVELOPMENT_STYLE.md](DEVELOPMENT_STYLE.md), especially small functions, explicit naming, and compact versus expanded block spacing.
- Preserve Grimoire's Screen/ViewModel organization, protocol-based services, constructor injection, feature ownership, and app-owned components. Reference `/Users/sakohovaguimian/Desktop/Personal/Grimoire/docs/IMPLEMENTATION_BEST_PRACTICES.md` when needed.
- UI state belongs in feature view models; AppKit interactions belong in focused controllers; reusable visual treatments belong in Diffy components.
- Keep source fixtures immutable. Store annotations, temporary merge results, and preferences separately.
- Do not add Git services, repository mutation, authentication, production diff algorithms, or network dependencies during Milestone 0.
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
| App construction | [AppAssembler.swift](Diffy/DI/Live/AppAssembler.swift), [ServiceAssembly.swift](Diffy/DI/Live/ServiceAssembly.swift), [ViewModelAssembly.swift](Diffy/DI/Live/ViewModelAssembly.swift) |
| Workspace and navigation | [WorkspaceViewModel.swift](Diffy/Screens/Workspace/WorkspaceViewModel.swift) |
| Themes | [DiffyTheme.swift](Diffy/Services/DesignSystem/DiffyTheme.swift) |

Use source syntax/type checks, SwiftLint, plist validation, and source membership review as appropriate. These checks do not establish runtime or visual correctness. Report the distinction clearly.
