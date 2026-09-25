# Diffy interaction contract

Visual ownership: [DESIGN.md](DESIGN.md). Code ownership: [DEVELOPMENT_STYLE.md](DEVELOPMENT_STYLE.md).

The current integration work is authorized by the September 24, 2026 request to implement GitHub sign-in, usable local projects, repository pages, and Git actions. That request supersedes the old Milestone 0 restriction on authentication and Git. The prototype's immutable fixture rule remains in force for the Mock target and previews.

| Capability | Canonical owner | Variants and behavior |
| --- | --- | --- |
| Select/Listbox | Native SwiftUI Picker and Menu | Platform geometry, keyboard behavior, and accessibility |
| Form | Feature Screen/ViewModel pairs | Native fields; inline errors; preserve commit drafts by project; mask tokens |
| Scrollbar | SwiftUI ScrollView / NSScrollView | Native system preference; no hidden patch scrollbars |
| Feedback | DiffyStatusBanner and feature view model | Persistent error or outcome; no success before service completion |
| Data lists | Feature view model | Local filtering; explicit additional pages for repository discovery and history; lazy rows |
| Account lifecycle | GitHubAccountServiceProtocol | Device flow, installed GitHub CLI browser flow, or personal token; Keychain credentials; metadata separately persisted |
| Git actions | GitServiceProtocol / RepositoryViewModel | User-triggered mutation; serialized by common Git directory; refresh after success, error, or cancellation |
| Confirmation | SwiftUI confirmationDialog | Named project, operation, and consequences for rebase, merge, discard, abort, whole-file resolution, force-with-lease, and disconnect |
| File selection | ProjectDirectoryController | Native macOS folder panel; link and clone save the resulting project |
| File icons | DiffyPathIcon / FileIconService / SettingsViewModel | One persisted theme for PR Review, comparison navigators, repository/folder browsers, and review headers; bundled offline catalogs; native picker with immediate preview; filenames and separate status indicators remain accessible |
| Project presentation | ProjectEditorScreen / WorkspaceViewModel | Add and edit share display-name and icon fields; edits apply to assigned, unassigned, and GitHub-linked projects; failed saves preserve the draft |
| Workspace overview | WorkspaceOverviewScreen / WorkspaceOverviewViewModel | Launches as the landing page; shows active local diffs and account-wide assigned pull requests; first-run actions connect GitHub or add a local folder; refresh remains read-only |

The September 24, 2026 customization request establishes Personal as the only starter Bucket and permits project display-name/icon editing after creation. Repository identity and the editable display name are separate. Editing presentation does not rename a repository or folder, change its GitHub link, or move its Bucket. Saved project names remain the initial display names when opening older libraries. Unmodified legacy iOS/Backend Buckets retire into Personal; customized Buckets remain.

Local repositories remain usable without a GitHub account. API authentication and Git transport authentication are distinct: tokens never enter remote URLs. Connecting an account does not clone every repository. Link Folder validates a matching GitHub remote; Clone asks for a parent folder and imports the completed checkout. Disconnect removes the local credential and account record; it does not delete local projects, folders, or remote repositories.

The Live target is for direct distribution without App Sandbox so system Git can use user Git configuration, SSH agents, credential helpers, hooks, submodules, and worktree directories. Mock remains sandboxed and excludes Live sources entirely. This distribution choice must be revisited before a Mac App Store release.

Read-only inspections never check out a branch or fetch automatically. Git mutations retain Git's normal hooks and protections. Pull offers explicit fast-forward, merge, and rebase strategies; unrestricted force push is absent. Merge/rebase conflicts are recoverable states with continue/abort controls. Cancellation is not rollback: refresh actual Git state and preserve completed changes. A command error must remain visible if the status refresh succeeds.

Repository snapshots remain visible after failed refreshes. Superseded patch requests are cancelled. Account/repository responses are tied to their selection. Source pages are read-only; conflict edits are made in the user's editor or by an explicit whole-file choice. Git output is bounded for display. Native accessibility and visual operation still require runtime verification; source checks do not establish that evidence.

The September 24, 2026 restoration request preserves the original comparison hierarchy for connected accounts: Bucket/project sidebar → changed-file tree → split or unified diff → optional Review Notes. Working tree compares Index to Working tree; Staged compares HEAD to Index. Branch, commit, history, and pull-request comparisons reuse the same navigator and diff tools. Live files load on demand, cancel superseded reads, and keep fixture data separate. Changes/File, search, change navigation, line display options, and annotations apply to live source; source editing remains restricted to the prototype's separate in-memory drafts. Stage/Unstage/Discard and Commit retain explicit Git actions.

Branch/revision reviews and completed Git-operation summaries share a near-full-window native sheet with a visible Close button and Escape dismissal. Files stack vertically with individually expandable Diffy split/unified canvases, status, path, addition/deletion counts, and Viewed checkboxes. Viewed is local review progress for the open comparison; it never stages files or submits a GitHub review. Marking Viewed collapses the file; clearing it expands the file. Filters and expansion state remain local to the modal. Large comparisons expose additional files and lines explicitly instead of eagerly rendering every source row.

Pull, merge, rebase, and checkout summaries compare actual before/after HEAD object IDs captured by the Git service. Fetch compares the tracked upstream's before/after object IDs and explicitly distinguishes remote-reference updates from local working-tree changes. Summaries open only after successful completion; paused conflicts and failed/cancelled operations retain their existing recovery feedback. Missing comparison reads report that the operation completed but its summary is unavailable. No-change operations show an honest empty state. Opening a modal preserves the working-tree selection underneath. Each file owns its diff selection/search state, and annotations retain the modal's source pair and comparison mode.
