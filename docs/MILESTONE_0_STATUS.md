> Historical prototype status. The September 24, 2026 integration request advances Live Git and GitHub work beyond Milestone 0. See [GITHUB_SETUP.md](GITHUB_SETUP.md); Mock sources remain immutable.

# Milestone 0 — Initial Implementation

This implementation establishes the native application and the principal review workflows. Milestone 0 remains open for runtime review, visual iteration, and the remaining controls in the product brief.

## Implemented

- Native macOS application target, shared scheme, window scenes, Settings scene, menu commands, and resizable workspace panes.
- Feature-owned Screen/ViewModel structure, protocol-based services, explicit dependency assembly, and in-memory previews for every screen and app-owned component, following Grimoire.
- Porcelain light and Safira dark palettes, semantic theme roles, system appearance selection, and adjustable accent colors.
- Seven mock projects in three Buckets; favorites, recent comparisons, and project dashboards. Working Tree and Overview are the active top tabs; the other tabs show green placeholders.
- Bucket name, SF Symbol, preset or custom color, and live preview. Gradient, visibility, expanded density, and 10-point corners are fixed. Every expanded Bucket has a tinted Add New Project row that chooses a local folder, then asks for a name and icon. The saved folder path and presentation details persist separately from sample fixtures. Projects inherit Bucket color, move by drag/drop or menu, and detach into Unassigned. Bucket ordering and deletion are available from Bucket actions. Deleting a Bucket moves its projects to another Bucket.
- Folder, flat, change-type, and file-type file navigation; name/path/recency/change-size/status/size/type sorting; filtering, search, expand/collapse, and per-project presentation preferences.
- Aligned side-by-side and unified source rows, line numbers, lightweight syntax color, sample inline emphasis, synchronized scrolling, a centered changed-regions/whole-file switch, search navigation, optional trailing guides and changed-region framing, display preferences, and source-range selection.
- In-place editable working-copy panes for text fixtures, with lightweight live line matching and diff colors that refresh as the draft changes. A floating Apply Changes action accepts the in-memory draft, while navigation with unapplied edits offers Apply, Discard, or Cancel. Original comparison fixtures remain immutable and no repository files are written.
- Text annotations with captured source/side/path/range/code, local persistence, project grouping and bulk deletion with undo, edit/delete/resolve/reopen, review scopes, and full Markdown preview/copy/save.
- Image modes using native-generated fixed sample artwork: side-by-side, overlay, slider, difference, blink, zoom, pan, and single-canvas pixel readout.
- The three-way merge prototype remains in source with conflict navigation, temporary editable results, and snapshot annotations; its top tab currently shows a placeholder.
- Native clipboard and save-panel controllers. No network calls, Git commands, account flows, or writes to repository files.
- SwiftLint configuration that preserves the requested blank-line style.

## Deliberately limited sample behavior

- Branch and commit fixtures remain fixed samples; their top tabs currently show placeholders.
- Added local folders are references only. Their overview shows the path and explains that file and Git comparisons will arrive later; no local contents are read.
- Folder comparisons use the same fixed tree data. Binary files display metadata rather than a production binary comparison.
- Syntax coloring is a lightweight presentation helper. Inline emphasis is supplied by fixtures; full distinct word/character sample spans still need refinement.
- Editable text comparisons use a deliberately small line matcher for prototype feedback. Applied drafts persist in memory while navigating the workspace, but they are not a production diff engine or file-writing workflow.
- Merge panes show conflict fragments, with annotation line numbers relative to the composed sample source. The result is a temporary per-view draft. Annotations preserve snapshots even after that draft is edited or reset.
- Image art is drawn locally for the prototype. It is not an implementation of file loading or the production image comparison engine.

## Remaining Milestone 0 work

1. Build and launch when explicitly authorized, then inspect the actual macOS UI at compact and large window sizes. Source checks alone do not verify layout, accessibility, performance, or interaction behavior.
2. Refine the native comparison canvas after visual review, including independently adjustable horizontal panes, connector geometry, and richer selected spans.
3. Add distinct immutable fixture variants for branch/commit/history selections and formatting-ignore modes. Add larger trees, empty repositories, and unavailable-source scenarios.
4. Finish keyboard customization and collision feedback, comparison tabs, robust back/forward history, and source selection by keyboard.
5. Finish Bucket custom images, tint/border/layout controls, repository sort defaults, full density behavior, and preference inheritance.
6. Complete remaining settings previews: ligatures, tab width, syntax-theme selection, indentation/blank-line/formatting controls, density, materials, shadows, animation, and exclusions.
7. Expand merge annotation selection to arbitrary line ranges and retain draft state across navigation. Add explicit accept-both ordering options in addition to the current yours-then-theirs action.
8. Review multiwindow state consistency, VoiceOver, focus behavior, reduced motion/transparency, long paths, and export volume.

These are remaining prototype tasks. They do not authorize starting Git integration early.

## Theme references

The three screenshots under `/Users/sakohovaguimian/Desktop/Personal/Themes To Build` were inspected. They informed Porcelain's cool white surfaces and pink/violet/green/teal syntax direction.

`Safira-Dark-Custom-color-theme.json` was absent. The user explicitly approved using installed Safira for now. The inspected reference was `/Users/sakohovaguimian/.cursor/extensions/yinz.safira-0.0.9/themes/Safira-color-theme.json`; its palette was translated into native semantic roles rather than copied literally.

## Validation boundary

Source syntax/type checks, lint, and project metadata checks are permitted and recorded in the README. No tests were written, and no Xcode build or app launch was performed. The application has not yet received visual approval.
