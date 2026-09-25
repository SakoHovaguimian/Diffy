# Diffy — Code Annotations and Review Export

## 1. Purpose

Let a user capture their reasoning while inspecting code, then export the complete review with enough context for an LLM or another person to understand each comment without having Diffy open.

This is a local feature. It does not require an account, an LLM API, automatic message sending, or a GitHub review integration.

## 2. Annotating code

Select a line or range, then invoke Add Annotation through a gutter action, context menu, or keyboard shortcut. Open a compact editor beside the selection with a clearly labeled source and line range.

The user writes a comment, saves it, and continues reviewing. An understated gutter marker indicates the note. Opening the note must preserve the selected code and surrounding reading position.

Support:

- Single-line and multiline selections.
- Left/right source annotations in side-by-side and unified comparisons.
- Base/yours/theirs/result annotations in the merge view.
- Multiple notes per file, including overlapping selections.
- Edit and delete, with undo for deletion.
- Resolve and reopen, without removing the note's source context.
- A small unsaved-draft indicator when the annotation editor contains changes.

In unified view, added lines belong to the new/right source and removed lines belong to the old/left source. Unchanged lines must expose which source is being annotated. If a selection spans both sources, preserve distinct source ranges and snippets; never invent a single continuous range across two versions.

Keep comments visually secondary to the code until the user opens them. Markers should communicate annotation state without competing with added/removed highlighting.

## 3. Reviewing all notes

The Review Notes panel gathers annotations across the chosen comparison, project, or all local projects.

Group notes by project, comparison, and file as needed. Each entry shows its location, a comment excerpt, and open/resolved status. Selecting an entry reveals the associated source and code range.

Include search, open/resolved filters, file order or creation-time order, and an Export All action that explicitly names its scope and count.

For example: **Export all 12 annotations in this comparison.**

File-tree filters must not silently limit this export. If the user intentionally exports only selected or filtered notes, label that action and show its count separately.

Default Export All to include open and resolved notes, with their status retained. The export preview may offer an explicit open-only choice.

## 4. Source context and changing files

An annotation needs a reliable description of the code it referred to when it was written:

- Project name and repository-relative file path.
- Comparison type and source labels.
- Specific source side or merge role.
- One-based start and end lines in that source, not rendered diff-row positions.
- Selected code and a small, configurable amount of surrounding context.
- Language when known.
- Original user comment, status, and creation/update time.
- Stable source snapshot identity; Git commit identity when available in later milestones.

For renamed or moved files, retain both paths where relevant. Do not expose an absolute home-directory path by default.

Working-tree and index snapshots need their own captured context because they are not necessarily represented by a commit. A branch name alone is not an immutable source identifier.

If the code changes later, preserve the original snippet and location. Attempt relocation only when it is supported and reliable; otherwise mark the note as referring to an earlier version and let the user reattach it. Never silently point the note at unrelated code just because the old line number still exists.

An annotation on an editable merge result follows the same rule. Editing the draft must not silently corrupt the note's location.

Milestone 0 uses fixed source identifiers and immutable fixtures. Only the editable result draft needs changing-content behavior at that stage; stale-location feedback is sufficient without building a general relocation engine.

## 5. Export behavior

Provide:

- **Preview:** inspect the complete export before copying or saving.
- **Copy for LLM:** put the formatted Markdown on the clipboard.
- **Save Markdown:** save the same content to a user-selected local file.

Use plain Markdown as the primary format. Organize it consistently: review context first, then annotations grouped by file and source.

Each annotation includes an ordinal number, path, source/side, line range, status, code snippet, and the exact user comment. Include a summary count so a recipient can verify that all notes are present.

Use fenced code blocks with the correct language when known. Keep raw code copyable by placing the annotated range and snippet range above the block instead of inserting line numbers into the source text. Choose fences long enough to safely contain embedded backticks. Keep comments clearly separated from code and export metadata.

Do not truncate comments or selected code silently. For large exports, show the size and offer explicit context reduction or numbered parts while preserving all annotations and selected ranges.

Include an optional user-written review goal, such as “Address these comments while preserving existing behavior.” Do not invent implementation instructions or treat comments as instructions to automatically send messages or execute actions.

No real files, credentials, or network requests are needed for the Milestone 0 export. Its content comes from the selected fixture snapshots and the user's locally saved comments.

## 6. Example Markdown export

This is an illustrative export using mock source identities and code. Real exports must use the actual recorded context.

````markdown
# Diffy Review

Project: Rune
Comparison: Working tree vs HEAD
Left source: HEAD — mock-commit-rune-001
Right source: Working tree — mock-snapshot-rune-002
Scope: All annotations in this comparison
Annotations: 2 total; 2 open; 0 resolved
Line numbering: One-based, relative to the specified source file

## 1. Sources/Accounts/AccountService.swift

Source: Right — Working tree — mock-snapshot-rune-002
Annotated lines: 42–46
Snippet lines: 42–46
Status: Open

### Code

```swift
func refreshAccount() async throws {

    account = try await client.fetchAccount()

}
```

### Comment

Please separate fetching from updating the view state so each function has one clear responsibility.

## 2. Sources/Views/AccountHeader.swift

Source: Right — Working tree — mock-snapshot-rune-002
Annotated lines: 18–19
Snippet lines: 18–19
Status: Open

### Code

```swift
Text(account.displayName)
    .font(.headline)
```

### Comment

Give the account name more breathing room and make sure long names stay readable in a narrow window.
````

## 7. Milestone 0 acceptance

The feature is ready when a user can annotate several files, leave and return without losing saved notes, jump back to each code selection, and copy or save a complete review with accurate paths, ranges, source context, snippets, and comments.

Verify both old and new source lines, multiline ranges, resolved notes, filtered file trees, and comments containing Markdown. Resetting the demo's appearance or sorting must preserve saved review notes.

Keep the annotation model in its own file, with separate focused models for independently meaningful source anchors or export options as needed. Avoid creating future Git or synchronization infrastructure for the prototype.
