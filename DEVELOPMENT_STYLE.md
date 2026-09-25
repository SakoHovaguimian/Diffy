# Diffy — Readability and Formatting Rules

## Source and intent

These rules adapt the user's Obelisk / Hono Template style to native macOS development.

The inspected source is:

`/Users/sakohovaguimian/Desktop/Personal/Hono Template/docs/prompts/LINTING_FORMATTING_SEMANTICS.md`

Obelisk's `AGENTS.md` also requires independent models to be split into separate files where possible.

Obelisk currently documents its formatting rules without an automated lint or format command. Diffy now supplies a SwiftLint configuration for mechanical checks; the Grimoire adaptation and intentionally manual rules are described below.

The expanded/compact block distinction and spacing rules below come from Obelisk. The micro-function emphasis is an explicit user requirement. The Swift naming, initialization, and UI composition guidance are adaptations for this project.

## 1. Optimize for reading

- Prefer clear intent over the fewest lines of code.
- Use descriptive names and explicit intermediate values when they clarify a step.
- Separate logical phases with one blank line.
- Prefer straightforward control flow and early exits over deep nesting.
- Avoid dense chained transformations, nested ternaries, and multiple statements on one line.
- Comments should explain intent, constraints, or a non-obvious choice.
- Do not introduce extra abstraction merely to make a function shorter.

Verbose spacing means giving distinct operations room to breathe. It does not mean adding blank lines between every property or expanding every trivial expression.

## 2. Build with micro functions

A function should do one understandable job. A coordinating function should read as a short sequence of named steps.

Extract a helper when it names a useful concept, removes meaningful repetition, isolates a decision, or makes the caller easier to scan. Avoid helpers that only obscure a simple expression or force readers to jump between files unnecessarily.

For file navigation, filtering entries, ordering entries, and deriving a visible presentation are separate responsibilities. Do not bury all three inside a SwiftUI view body.

Prefer:

```swift
// MARK: - Visible Files

func visibleFiles() -> [DiffFile] {

    let matchingFiles = filterFiles(files)
    let orderedFiles = sortFiles(matchingFiles)

    return orderedFiles

}
```

Each helper should have a clear name and remain as small as the underlying responsibility allows. There is no arbitrary line-count target.

## 3. Preserve compact and expanded block rules

### Compact executable blocks

A block with one short statement that fits on one line has no internal blank padding.

```swift
func hasChanges() -> Bool {
    changeCount > 0
}
```

```swift
guard let selectedFile else {
    return
}
```

### Expanded executable blocks

A block with multiple statements, nested control flow, multiple phases, or a wrapped statement has exactly one blank line after its opening brace and before its closing brace.

```swift
func selectFile(_ file: DiffFile) {

    selectedFileID = file.id

    resetChangeNavigation()
    recordRecentSelection(file)

}
```

```swift
if shouldRevealSelection {

    revealFile(
        selectedFile,
        expandAncestors: true
    )

}
```

Classify each branch independently. A short guard remains compact even when its enclosing function is expanded. Keep `} else {` and `} catch {` together. Use braces for control flow.

Use a blank line between logical switch cases, not mechanically after every `case` label.

## 4. Keep data declarations distinct from executable code

Do not apply executable-block padding to array literals, dictionary literals, argument lists, or stored-property-only model declarations. Keep adjacent related properties together.

```swift
struct DiffFile: Identifiable {
    let id: UUID
    let path: String
    let status: FileChangeStatus
}
```

Separate genuinely different groups when it improves comprehension. Types containing functions and UI behavior can use the expanded type-body layout and MARK sections.

## 5. Split models and large views

- Put independent models in separate files whenever practical.
- Prefer `Bucket.swift`, `RepositoryProject.swift`, `ComparisonSession.swift`, and `DiffFile.swift` over a catch-all `Models.swift`.
- Give independent settings and theme models their own focused files.
- Keep a tightly coupled nested type with its owner when that is clearer.
- Split a large screen into named UI components with meaningful responsibilities.
- Use small computed view properties for short local sections; extract reusable or substantial components into their own files.
- Keep rendering separate from data preparation and interaction decisions.
- Keep immutable fixtures separate from mutable UI state and editable merge drafts.
- Search for an existing equivalent before adding a helper, model, or component.

File splitting should improve navigation and ownership. It should not create a generic architecture before the product requires one.

## 6. Adapt Obelisk declarations to Swift

- Use four spaces for indentation in new Swift files, with no tabs.
- Keep opening braces on the declaration or control-flow line.
- Use one space around assignment and binary operators, after commas, and after type-annotation colons.
- Use descriptive Swift argument labels.
- Follow the Obelisk constructor rule for explicit Swift initializers: with two or more parameters, use one parameter per line and align the closing parenthesis with `init`.
- Wrap other declarations and calls when doing so improves readability; use one argument or parameter per line when wrapped.
- Use Swift's normal string syntax and omit unnecessary semicolons.
- Use `// MARK: - …` with a blank line before the following declaration to identify meaningful sections and nontrivial behavior methods. Use native Swift MARK syntax rather than requiring Obelisk's TypeScript asterisk banners.
- Do not add a MARK banner above every trivial property or tiny view fragment.

```swift
init(
    project: RepositoryProject,
    comparison: ComparisonSession
) {

    self.project = project
    self.comparison = comparison

}
```

SwiftUI view-builder closures containing multiple views follow the expanded block rule. Keep long modifier sequences readable, and split a view when its hierarchy becomes difficult to follow.

## 7. Formatting and verification policy

- Use LF line endings and exactly one final newline.
- Remove trailing whitespace and whitespace-only blank lines.
- Use one blank line between phases; avoid multiple consecutive blank lines.
- Preserve unrelated code and user changes.
- If linting or formatting tooling is introduced, configure it to preserve these conventions. Review or disable conflicting defaults rather than silently flattening the spacing.
- Distinguish tool-enforced rules from manual review rules. Do not claim that a style check passed unless that check exists and was actually run.
- Do not write tests, per the standing project instruction.
- Do not run Xcode builds unless explicitly asked.
- Use source review and permitted checks, and clearly state any validation that was not performed.

## 8. Review checklist

Before considering an implementation change complete, confirm:

1. Functions and view components have clear, focused responsibilities.
2. Independent models live in separate files where practical.
3. Expanded blocks have the required padding; compact blocks remain compact.
4. Logical phases are separated and names explain intent.
5. Model properties and literals have not received unnecessary vertical padding.
6. Initializers, wrapped calls, and MARK sections follow the agreed Swift adaptation.
7. Source fixtures remain immutable; interactive state is separate.
8. Changes stay within the active milestone and introduce only the architecture currently needed.

## 9. Grimoire's SwiftUI structure

The implementation additionally follows the inspected Grimoire sources:

- `/Users/sakohovaguimian/Desktop/Personal/Grimoire/AGENTS.md`
- `/Users/sakohovaguimian/Desktop/Personal/Grimoire/docs/IMPLEMENTATION_BEST_PRACTICES.md`
- Grimoire's app entry point, live/mock assemblies, Screen/ViewModel pairs, UserDefaults service contract, and base ViewModel contract.

Keep screens and view models together by feature. Prefer `@StateObject` ownership and `@ObservedObject` consumers, protocol-based services, constructor injection, app-owned reusable components, and small view-building helpers. Use explicit `self` for properties and dependencies, `@MainActor` for UI-bound state and services, and separated `SCREAMING_SNAKE_CASE` logger identifiers.

AppKit-specific clipboard, save-panel, and other window interactions belong in focused controllers. Use native macOS controls instead of importing iOS-only implementations. Assemble preview dependencies with in-memory storage so previews cannot modify the user's real notes or preferences.

The initial implementation now includes `.swiftlint.yml`. Its rules check mechanical formatting without removing expanded-block padding. Micro-function boundaries, spacing by logical phase, and ownership remain manual review concerns. Do not import a formatter preset that erases those conventions.
