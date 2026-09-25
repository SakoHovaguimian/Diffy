# Diffy — Product Brief

## 1. What we are building

Diffy is a native macOS application for understanding changes in code, images, folders, and Git repositories, annotating a review, and eventually resolving merge conflicts.

The everyday workflow is simple:

**Choose a Bucket → open a repository → choose what to compare → inspect and annotate changes → export the review.**

Standalone file and folder comparisons should also be accessible without organizing a repository first.

The product should combine the visual polish associated with Kaleidoscope, the approachable developer experience of Cursor, and the comparison and merge ambitions of Beyond Compare, Araxis Merge, and DeltaWalker. These are design references, not a requirement to reproduce every feature or layout.

Success means that changes are easy to understand, navigation feels natural, and the interface stays calm even when the comparison is complicated.

## 2. Nonnegotiable principles

- **Native macOS:** use native Mac technologies and familiar desktop interactions.
- **Local first:** repository inspection, comparison, projects, themes, and preferences live on the Mac. Core functionality works offline without an account or backend.
- **Visual experience first:** complete Milestone 0 before implementing Git integration or designing a production Git architecture.
- **Readable by default:** establish clear hierarchy, comfortable spacing, strong typography, and restrained use of color.
- **Exceptional UX is a release criterion:** every major flow must be beautiful, understandable, responsive, and comfortable to use. Evaluate this throughout implementation.
- **Power on demand:** place advanced controls in toolbars, menus, inspectors, and settings without overwhelming the default workspace.
- **Customization is a core feature:** Buckets, themes, editor presentation, navigation, and comparison preferences should feel intentionally designed.
- **Readable implementation:** follow the Obelisk-derived rules in [DEVELOPMENT_STYLE.md](DEVELOPMENT_STYLE.md), including micro functions and separate model files.

GitHub becomes an optional network feature in a later milestone. Authentication must never become a prerequisite for opening a local repository.

## 3. The product's four main concepts

| Concept | Meaning | Example |
| --- | --- | --- |
| Bucket | A customizable collection of projects | iOS, Backend, Personal |
| Project / repository | A local folder tracked by the app; Git repositories gain Git features later | Rune, JobLens API, Obelisk |
| Comparison | A selected pair of versions or locations, or a three-way merge session | Working tree vs HEAD, branch vs branch, folder vs folder |
| File view | The detailed text, image, binary summary, or merge presentation for a selected file | A side-by-side Swift diff |

Favorites and Recents are shortcuts to existing projects and comparisons. They should not create duplicate project records.

## 4. Workspace and navigation

The primary workspace has a sidebar, a contextual file list, and a main comparison area. An optional inspector exposes additional details.

| Area | Purpose |
| --- | --- |
| Sidebar | Buckets, projects, favorites, and recent comparisons |
| Toolbar | Comparison sources, presentation mode, search, and previous/next change |
| File list / diff tree | Changed files, folder hierarchy, sorting, grouping, and filters |
| Main content | Project overview, text diff, image comparison, folder comparison, or merge |
| Optional inspector | File metadata, timestamps, comparison options, and secondary information |
| Review Notes panel | All annotations in the chosen scope, with navigation and export |
| Settings window | Themes, appearance, editor, diff, repository, and shortcut preferences |

Use native menus, context menus, keyboard navigation, drag and drop, file pickers, resizable split panes, multiple windows, and tabs where they help. Quick Look-style previews and transitions should be restrained and useful. macOS materials should support legibility rather than obscure content.

Selecting a project opens its dashboard. Opening a comparison places the file list beside the comparison content. Preserve navigation context, the selected file, and useful scroll positions when moving between views.

## 5. Buckets and project organization

Example organization:

| Bucket | Projects |
| --- | --- |
| iOS | Hatch, Rune, JobLens iOS, ExperimentalApp |
| Backend | JobLens API, Obelisk, Internal Tools |
| Personal | Stormkeep, Side Projects |

Users should be able to create, rename, reorder, hide, and customize Buckets, move projects between them, and favorite projects.

Every expanded Bucket ends with a tinted outlined **Add New Project** row. It opens the macOS folder picker, then a project sheet for its name and icon. The project inherits its Bucket color. Projects can be dragged between any Buckets or detached into an Unassigned section, then assigned again by drag or menu. Detaching changes only Diffy's organization; it does not touch the folder.

Bucket customization includes:

- Identity: title, subtitle, icon, SF Symbol, or custom image.
- Color: accent, tint, background treatment, and gradient.
- Shape: border style and corner radius.
- Layout: presentation layout and compact, normal, or expanded density.
- Organization: repository sorting, favorites, manual order, and visibility.
- Defaults: preferred branch and comparison mode.

Provide a live preview and a reset-to-default action. Keep the initial customization panel approachable, with detailed appearance controls available when expanded.

## 6. Project dashboard

The dashboard answers three questions: **Where am I? What changed? What should I inspect next?**

Show:

- Current branch and repository status.
- Working-tree changes: local edits that have not been staged.
- Staged changes: edits selected for the next commit.
- Recent commits, branches, and tags.
- Recently compared files and comparisons.
- Direct actions to inspect changes or start a comparison.

Prioritize current changes and the next action. Keep secondary history and metadata visually subordinate. Avoid turning the dashboard into a wall of equally weighted cards.

## 7. File navigation, sorting, and filtering

This is a major product feature. A user should quickly find the most relevant file whether they think in folders, recency, file types, or change size.

### Three independent controls

| Control | Question it answers | Options |
| --- | --- | --- |
| View / grouping | How are files organized? | Folder tree, flat list, grouped by change type, grouped by file type |
| Sort | What comes first? | Name, path, last updated, change type, file type, lines changed, file size |
| Filter | Which files are visible? | Added, removed, modified, renamed, moved, identical, conflicted; staged/unstaged where applicable; path/name search |

Support ascending and descending order, folders-first ordering, expand/collapse all, and remembering the chosen presentation per project. Optional columns can expose path, status, additions/deletions, size, and date.

### Make “last updated” explicit

Different dates describe different events:

- **Last edited on disk:** the filesystem modification time for a local file, where available.
- **Last changed in Git:** the timestamp of the most recent commit affecting that file at the selected revision, when available. Do not substitute the comparison commit's date for every file.
- **Recently viewed:** when the user last opened that file in Diffy.

Use the applicable label in the interface rather than a misleading universal timestamp. If a date is unavailable, show an unavailable value and sort it consistently at the end. A deterministic name/path tie-breaker keeps ordering stable.

In tree view, sorting operates among siblings so files stay in their folders. A directory's recency can be the newest eligible descendant timestamp, clearly described as such. In flat view, the newest file can appear first regardless of folder.

For example, a user can select **Flat list → Last edited on disk → Newest first → Modified files** to inspect the files they just worked on, then switch back to the folder tree without losing their selection.

An optional later **Changed by me** filter can use an explicitly selected Git author identity. Author filtering and local edit timestamps are separate concepts.

### Tree behavior

- Display added, removed, modified, renamed, moved, and identical files, plus changed directories.
- Show both original and destination paths for renamed or moved files.
- Keep ancestor folders visible when a descendant matches a filter.
- Show useful change counts beside folders.
- Preserve selection and expansion state when changing filters or sorting.
- If a selected file becomes hidden, make that clear rather than silently displaying an unrelated file.
- Provide a clear empty state and a quick way to clear filters.

Milestone 0 must demonstrate these behaviors using fixed mock metadata.

## 8. Comparison experiences

### Text diff

The text comparison is the visual centerpiece. Default to a polished side-by-side presentation with clearly labeled sources and an easy switch to unified view.

Include:

- Line numbers and syntax highlighting.
- Line, word, and character change highlighting.
- Added, removed, and modified indicators that do not rely on color alone.
- Connector guides, changed-region framing, and previous/next change navigation.
- Collapsible unchanged regions and configurable context lines.
- Adjustable panes and synchronized scrolling.
- Optional line wrapping, font size, and line height controls.
- Whitespace visualization.
- Ignore whitespace, indentation, blank lines, comments, and formatting-style changes.
- Search, command palette, and discoverable keyboard shortcuts.

Clearly distinguish display preferences from comparison rules. Showing whitespace only changes its visibility; ignoring whitespace changes which differences are considered relevant.

Formatting-style and comment suppression should eventually be language-aware where necessary. Preserve access to the full textual comparison and make active ignore rules visible.

### Image diff

Include side-by-side, overlay, slider, difference, and blink modes, with zoom, pan, and pixel inspection.

Use bundled reference images and fixed comparison assets in Milestone 0. Interaction should be convincing: the slider moves, overlay opacity changes, zoom and pan respond, and the inspector identifies the selected pixel. A production image comparison engine belongs to Milestone 3.

### Folder / repository diff

Compare two folder structures using the file-navigation behaviors above. Selecting a file opens the appropriate text or image view; binary files receive an understandable metadata summary when a visual comparison is unavailable.

### Commit and branch comparison

Provide selectors for:

- Branch vs branch.
- Commit vs commit.
- Working tree vs HEAD, the currently checked-out commit.
- Staged changes vs HEAD.
- File history and comparisons between historical versions.

Keep source labels visible throughout a comparison. Selecting a branch for comparison must not imply checking it out.

### Three-way merge

Explain the four roles in the interface:

| Pane | Meaning |
| --- | --- |
| Base | The shared starting version |
| Yours | Your version |
| Theirs | The other version |
| Result | The proposed combined output |

Include accept yours, accept theirs, accept both, reject both, conflict navigation, and an editable result.

Avoid ambiguous actions: accepting both must expose insertion order. For the prototype, “reject both” restores the base text for that conflict; it does not silently delete the entire region. Keep unresolved status visible until the user explicitly resolves a conflict.

Provide undo and reset for result editing. Adapt the pane layout to the window size while keeping the source roles clear.

## 9. Code annotations and LLM-ready review export

Users should be able to review a comparison, annotate individual lines or ranges, and gather every annotation into a clean, portable document that an LLM can understand.

The flow is: **Select code → add a note → continue reviewing → open Review Notes → export all notes in the chosen scope.**

Include:

- Line and range annotations in side-by-side, unified, and merge views.
- Clear attachment to the correct source: left/right or base/yours/theirs/result.
- Small gutter markers and an inline comment editor that preserve code readability.
- Edit, delete with undo, and resolve/reopen actions.
- A Review Notes panel grouped by file, with search and jump-to-code navigation.
- Explicit comparison, project, or all-project export scope. Export All includes notes outside the currently visible file or filtered tree.
- A Markdown preview, Copy for LLM action, and Save Markdown action.
- File path, source version, side, line range, original code snippet, and verbatim user comment for each annotation.
- Saved source context and clear stale-location feedback if the underlying file changes later.

The export should be understandable outside Diffy. Do not use opaque internal IDs as the only location references, strip the user's wording, or claim that a historical line number is the current one.

This feature requires no LLM integration or network request. The user can paste or attach the exported review to their preferred tool.

Milestone 0 includes a working local annotation flow and export against fixed fixtures. Persist review notes separately from those immutable fixtures. Real-file anchors and Git revision context arrive with the corresponding later milestones.

See [ANNOTATION_EXPORT.md](ANNOTATION_EXPORT.md) for the interaction contract and an example of the export format.

## 10. Themes and customization

Inspect every supplied reference when implementation begins:

`/Users/sakohovaguimian/Desktop/Personal/Themes To Build`

Use `Safira-Dark-Custom-color-theme.json` as the primary dark-theme reference. Use the supplied light-mode image or images as the primary light-theme design reference. Inspect the remaining supplied references before defining additional themes.

Translate the references into a coherent native design system. Do not mechanically apply VS Code colors to unrelated macOS surfaces.

Define named theme values for:

- Window, sidebar, cards, panels, and editor surfaces.
- Added, removed, modified, and conflicted content.
- Primary text, secondary text, borders, selection, and hover.
- Accent colors and syntax highlighting.
- Scrollbars where customizable.
- Menus, popovers, buttons, and inputs, respecting native system behavior.

Support future themes through shared semantic roles rather than scattered color literals. Include a theme preview, light/dark selection, and a system-appearance option. Review contrast, keyboard focus, reduced motion, and reduced transparency in both primary themes.

## 11. Settings

| Category | Controls |
| --- | --- |
| Editor | Font family, font size, line height, ligatures, tab width, wrapping, whitespace, line numbers, syntax theme |
| Diff | Side-by-side/unified, line/word/character highlighting, ignore rules, context lines, collapse unchanged regions, algorithm, connector lines, changed-region framing, animations |
| Appearance | Theme, accent, sidebar size, density, corner radius, transparency, blur, shadows, animations |
| Repository | Default branch, comparison mode, file exclusions, generated-file exclusions, ignore patterns, binary-file behavior |
| File navigation | Default view, grouping, sorting, folders-first ordering, visible columns, remembered filters |
| Navigation | Custom shortcuts for major actions, shortcut-conflict feedback, reset to defaults |
| Review notes | Default export scope, code context around annotations, resolved-note inclusion, export metadata options |

Use a clear preference order where a setting applies: **app default → Bucket default → project override → current comparison override**. Not every setting needs all four scopes. The interface should show when a value is inherited and let the user return to the inherited value.

Keep common controls easy to reach and advanced options searchable. Settings must produce visible changes where the prototype supports them. Engine-dependent settings can select precomputed examples or be labeled as previews; they must not imply that an engine is already implemented.

## 12. Milestone 0 — A complete interactive visual prototype

### Objective

Build the complete visual experience using realistic fixed data so we can evaluate the product before implementing Git functionality.

This milestone is an interactive native application. It must contain meaningful navigation and working visual controls, not only static screenshots.

### Mock-data contract

- Use fixed repositories, branches, commits, tags, files, folders, staged changes, working-tree changes, image pairs, and merge conflicts.
- Give fixtures stable identifiers, believable paths, and fixed timestamps.
- Include clean repositories, complex changes, empty results, long paths, large file lists, and unavailable-file examples.
- Keep source text, source images, comparison snapshots, and source merge panes immutable.
- Store selection, sorting, filters, pane sizes, theme choices, and other interactive UI state separately.
- Store user-authored annotations separately from the fixtures. Save them locally so a prototype review can be resumed, and export the actual notes the user entered.
- Merge editing changes only a temporary result draft. It never changes the source fixtures or files on disk.
- Ignore rules and advanced engine options may switch among precomputed comparison variants. Do not build a real diff engine to make the prototype work.
- Provide a way to reset demo presentation state and return to the original fixtures. Resetting presentation must not silently delete user-authored notes.

Simple persistence for theme and presentation preferences, local project folder references, and prototype review notes is in scope. A folder reference stores the selected path and presentation details without reading project files. Folder inspection and comparisons against real local content belong to Milestone 1. Explicitly saving an annotation export is also in scope.

### Build order within Milestone 0

| Step | Deliverable | What we evaluate |
| --- | --- | --- |
| 0A — Foundation | Theme reference review, native window, typography, surfaces, sidebar, toolbar, mock Buckets and projects | Does this look and feel like a premium Mac app? |
| 0B — Main workflow | Project dashboard, comparison selection, sortable/filterable file tree, flagship text diff, line annotations, Review Notes, Markdown export | Can we find, understand, and explain a change quickly? |
| 0C — Comparison coverage | Unified view, history and branch/commit screens, folder comparison, image modes, merge workspace | Does every major comparison have a coherent experience? |
| 0D — Personalization | Bucket editor, theme selector, settings, keyboard customization, command palette | Is configuration useful and enjoyable? |
| 0E — Interaction polish | Resizing, focus, keyboard flow, context menus, drag and drop, tabs/windows, empty states, accessibility | Does the experience hold together during normal use? |

All five steps belong to Milestone 0. This sequence does not move required prototype screens into later milestones.

Visual and interaction quality are evaluated at every step. Step 0E checks consistency across the finished experience; it is not the first time usability receives attention.

### Explicit boundaries

Do not implement repository scanning, Git commands, Git services, GitHub authentication, cloning, staging, committing, checkout, production diff algorithms, or merge writes during this milestone.

Controls for future repository mutations should be clearly identified as previews or unavailable. A mock interaction must never claim it changed a real repository.

### Completion criteria

Milestone 0 is ready for product review when:

1. A user can navigate Bucket → project → comparison → file without getting lost.
2. The sidebar, project dashboard, and comparison screens form one coherent application.
3. Sorting, grouping, filtering, and recency ordering are demonstrated with realistic data.
4. The text diff remains readable in both themes and at compact laptop and larger desktop window sizes.
5. All major text, image, folder, history, and merge screens are reachable.
6. Customization visibly affects the interface and can be reset.
7. Mock merge controls edit only the temporary result and support undo/reset.
8. Keyboard navigation, resizing, and empty states are usable.
9. Source fixtures remain immutable and no real Git actions occur.
10. A user can annotate multiple files, resume their notes, and export all notes in the selected scope with accurate source labels, snippets, and line references.
11. The review-quality criteria in section 14 are met for the main workflows.
12. We have reviewed whether the navigation, information hierarchy, Buckets, dashboard, and comparison experience are strong enough to justify wiring in real data.

Complete the visual review and address the resulting design issues before starting Milestone 1. Advancing is a product decision, not an automatic consequence of finishing the screens.

## 13. Later milestones

| Milestone | Outcome | Included work |
| --- | --- | --- |
| 1 — Local projects | Use real local folders | Inspect saved folder references, add/remove project references, basic folder metadata, Buckets, favorites, recent projects, durable local access, and annotations attached to real local file snapshots. Removing a project from Diffy does not delete the folder. Git behavior remains minimal. |
| 2 — Read-only Git | Inspect actual repositories | Native/local Git invocation for status, HEAD, working tree, index, branches, commits, tags, history, commit comparison, and branch comparison. Add revision-aware annotation context. Basic real text comparisons may use Git output; the advanced engine remains separate. |
| 3 — Advanced diff | Improve comparison accuracy and performance | High-performance text diffing, word/character detail, moved blocks, rename detection, folder and image diff, binary awareness, optional semantic analysis. |
| 4 — Merge | Resolve actual conflicts | Real three-way Git merge, editable output, accept left/right/both, conflict navigation, validation of resolution state, and saving the result. |
| 5 — GitHub | Add optional remote context | GitHub sign-in/OAuth and organization SSO where applicable, repository discovery, cloning, open on GitHub, PR metadata and file comparisons, commit links, and branch links. Store credentials in macOS Keychain. |
| 6 — Developer integrations | Open Diffy from existing workflows | Git difftool and mergetool support, CLI file/folder comparison, and integrations with Cursor, VS Code, Xcode, and terminal workflows. |

Semantic comparisons in Milestone 3 supplement the deterministic text diff. For example, they may identify a moved Swift method or suggest that multiple replacements represent `fetchUser` becoming `fetchCurrentUser`. Present these as additional explanations with appropriate uncertainty, and keep the underlying textual changes inspectable.

GitHub authentication must use an appropriate installed-application flow without introducing a required application backend or embedding a confidential client secret. Choose and verify the exact flow during Milestone 5.

Illustrative CLI workflows for Milestone 6:

```sh
diffapp fileA.swift fileB.swift
diffapp repoA repoB
git difftool
git mergetool
```

The command name is illustrative until product naming is finalized.

## 14. Visual and UX quality criteria

The interface should feel intentionally composed at every scale: the entire window, a file row, a changed line, and an annotation popover.

- **Clarity:** the current repository, comparison sources, selected file, and next action are immediately understandable.
- **Typography and spacing:** establish a consistent type hierarchy, comfortable code density, precise alignment, and generous spacing around controls. Keep information-dense areas readable.
- **Calm presentation:** show essential controls first. Reveal advanced tools through clear secondary surfaces without hiding basic actions behind hover alone.
- **Purposeful color:** use color to explain state and guide attention. Keep diff highlights, Bucket accents, and annotations visually distinguishable.
- **Useful feedback:** make selection, focus, loading, empty results, unsaved edits, saved notes, and successful copying easy to recognize. Avoid disruptive feedback for routine actions.
- **Continuity:** preserve context during navigation, filtering, theme changes, and pane resizing. Annotation editors should not unexpectedly move the code beneath the user's pointer.
- **Keyboard and pointer comfort:** support predictable focus order, visible focus, discoverable shortcuts, adequate click targets, and context menus.
- **Adaptability:** preserve usable code panes at smaller sizes; collapse secondary information before making the main content unreadable.
- **Accessibility:** pair color with labels or shapes, support VoiceOver, and respect reduced motion and reduced transparency.
- **Motion:** use short, purposeful transitions that communicate a change of state without delaying work or animating large amounts of code unnecessarily.
- **Responsiveness:** aim for immediate feedback during scrolling, sorting, searching, and opening annotations, including substantial mock file lists. Verify performance during implementation rather than assuming it from visual appearance.

Manually walk through these core journeys during product review: open a project and find a change; sort to the newest files; annotate several files and export the review; resolve a mock conflict; customize a Bucket; switch themes; repeat the main workflow using the keyboard.

Do not consider a screen complete only because all its controls exist. It must also have clear hierarchy, coherent states, and comfortable interaction.

## 15. Development boundaries

Use Swift and native macOS UI technologies. Keep UI components focused, models separated, and fixture data distinct from interaction state. Choose supporting components when implementation requires them.

Do not introduce a production Git abstraction, speculative backend, broad service framework, or complex persistence layer for Milestone 0. Keep the visual prototype easy to iterate on.

Follow [DEVELOPMENT_STYLE.md](DEVELOPMENT_STYLE.md). Do not write tests. Do not run Xcode builds unless explicitly requested. These standing project rules apply during implementation as well as prototype work.
