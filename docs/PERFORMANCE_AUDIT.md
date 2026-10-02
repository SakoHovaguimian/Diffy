# Diffy performance audit — October 2, 2026

## Findings

The strongest explanation is expensive UI work repeated during layout and data updates. The October 1 hang report confirms SwiftUI layout churn. A separate live sample confirms synchronous Keychain access from the PR list's rendering path. Source inspection identifies several amplifiers that become costly with large lists and patches.

These findings do not establish one cause for every reported freeze. Resizing the changed application has not been measured, and the precise view emitting the negative-geometry warnings has not been captured.

### Runtime evidence

- Screenshot: Activity Monitor showed Diffy not responding at approximately 100% CPU, with approximately 272 MB real memory. This supports a CPU/layout stall; it does not establish a memory leak.
- Hang report: `/Library/Logs/DiagnosticReports/Diffy_2026-10-01-163642_Sakos-MacBook-Pro-2.hang`. The recorded hang lasted 82.71 seconds. During the sampled interval, nearly all CPU time belonged to the main thread, with repeated `GraphHost.flushTransactions`, AttributeGraph updates, and nested lazy-stack measurement and placement. The report cannot identify the exact Diffy view responsible.
- Live sample: `/tmp/diffy-resize-audit-sample.txt`, captured from PID 42178 on October 2. It contains `RepositoryPullRequestsView.body → RepositoryViewModel.availableAccounts → LiveGitHubAccountService.loadAccounts → GitHubCredentialStore.read → SecItemCopyMatching`. Rendering was reading Keychain on the main thread.
- That live sample was mostly idle. It did not capture a sustained resize stall and must not be used as an estimate of resize speed or the benefit of these changes.
- User observation: Overview, file diffs, and PR review slow down with large data sets. Branch/PR loading also emits negative-width and negative-height geometry warnings.

## Changes applied

| Area | Repeated work or invalid layout path | Change |
| --- | --- | --- |
| Entire workspace | Every pixel of window resizing changed root SwiftUI state and a descendant environment value. | Removed the workspace size broadcast. The existing AppKit controller owns sheet sizing. |
| PR list accounts | A computed property called the account service and Keychain during rendering. | Read a metadata snapshot; update it from the accounts view model and after reauthorization errors. Credential validation still happens for GitHub requests. |
| Code rows | Syntax regexes, inline comparisons, and wrapping were rebuilt on view updates. | Reuse compiled regexes. Cache width-independent highlighting and wrapped output, keyed by source, comparison, theme, relevant preferences, and wrapping columns. |
| Markdown | Parsing the same discussion text on view updates. | Cache parsed blocks by text; link permissions and theme styling still apply in each view. |
| Diff visibility | Repeated filtering and region construction for the same source and preferences. | Cache the current visible lines and region presentation. Retained discussion lines, limits, and gap-splitting changes invalidate the appropriate results. |
| File navigation | Filtering, sorting, recursive tree construction, and descendant scans inside directory-sort comparisons. | Cache the current presentation; group descendants once per tree level and calculate update ordering once. |
| Overview lists | Sorting on each render and repeatedly sorting/filtering repository and author groups. | Sort when request data or ordering changes; flatten group headings and requests into one LazyVStack with stable identities and one child per entry. |
| PR discussions | Every source line scanned all comments/drafts; every unanchored comment scanned all lines. | Build line-number sets and match each collection once. Discussion-line preparation changes from O(lines × (comments + drafts)) to O(lines + comments + drafts). |
| Conversation and patch metadata | Conversation threads were sorted/regrouped and patch completeness reparsed during rendering. | Prepare threads when conversation data changes; cache completeness for each immutable review file. |
| Embedded PR diffs | Every height change retriggered navigation to the selected line/comment, including wrapping changes during resizing. | Repeat navigation after layout only when initial presentation or newly revealed lines need it. |
| Editable mock diff | Every native-view update restyled the full text storage. | Apply styles when text, comparison data, theme, or editor settings change; still update container layout for resizing. |
| Geometry | Diff panes could subtract a gutter from a smaller transient width; sheet sizes subtracted margins without bounds; tab-indicator frame changes continuously restarted animations. | Clamp pane widths, reject invalid measured heights, guard zero-width drags, bound sheet sizes, and animate tab selection changes instead of every rectangle change. |
| Account changes | Selecting a new account could launch a PR load from both account and picker observers. | Use one selection observer and refresh directly only when the selection remains the same. |

### Lazy-stack follow-up

Large lists retain LazyVStack: Overview requests, repository PRs, file navigation, standalone diff lines, PR review files, and conversation activity. Grouped Overview now uses one flat LazyVStack containing individual repository headers, author headers, and requests. It no longer nests lazy collections or wraps each complete repository/author group in an eager container. Stable group/request identities preserve collapse state, and detail-loading tasks remain attached to individual lazy request rows.

Small row wrappers use VStack so a conditional separator does not change the lazy collection's child count. Embedded PR diff canvases retain their existing intrinsic-height presentation and incremental line limit. Their full height is needed by the outer lazy file list; changing them to intrinsic lazy stacks would recreate the measurement risk identified in the hang investigation.

## Consequences and limits

- Code and Markdown caches consume additional memory. `NSCache` eviction hints are 4,096 entries/16 MiB estimated cost for code and 256 entries/8 MiB estimated cost for Markdown. These are estimates, not hard process-memory limits. Cached review/source content stays in memory.
- File-navigation and diff-visibility caches retain the current presentation; Overview caches retain the two current sorted collections. Their input changes refresh the result.
- Small section containers and intrinsic-height file discussions can create their contents up front. Grouped Overview instead prepares data entries and lets the single lazy stack create row views as needed.
- Sheets now depend on the existing native sizing controller instead of duplicate SwiftUI size propagation. Parent resizing and sheet minimum sizes need visual verification.
- Tab transitions still animate when selection changes. Window resizing updates the indicator immediately.
- Source fixtures, persisted annotations, Git mutations, authentication checks, and service contracts are unchanged.
- The guards address known invalid-size calculations. They do not prove that every branch/PR loading warning is resolved; those lists do not contain an explicit negative fixed-size expression that identifies the reported warning by itself.

## Remaining profiling priorities

1. Capture a sustained resize with Instruments' SwiftUI and Time Profiler instruments in the changed application. Compare Overview, a large standalone diff, and an expanded PR review using the same data and window widths.
2. Identify the exact view producing negative geometry during branch and PR loading. Instrument the warning site or capture its stack, then distinguish application sizes from framework layout proposals.
3. Measure the remaining PR row `ViewThatFits` hierarchy, branch/tag lazy grid, and workspace geometry/compositing groups. They remain candidates for repeated measurement; the current evidence does not justify replacing all of them.
4. Measure first-open preparation of large patches and long code lines. Caches reduce repeated work but do not move their first parse/highlight off the main thread.
5. Measure metadata update bursts and background request volume. Repository PR loading currently reads all available pages and then loads details/checks with bounded concurrency. Overview detail tasks are retained until refresh. These can amplify UI updates and network work; pagination behavior was preserved.
6. Verify wrapping, selection, Unicode/tab rendering, comment navigation, group collapse, account connection/removal, sheet sizing, and theme/font changes in Live and Mock. Source checks cannot establish these behaviors visually.

Apple's [Optimize SwiftUI performance with Instruments](https://developer.apple.com/videos/play/wwdc2025/306/) describes the profiling workflow for expensive view-body and representable updates. The findings above come from local diagnostics and source inspection.

## Validation

No Xcode build was run and no tests were written. Changed/new sources have been parsed and linted, and the project plist has been validated. Command-line Swift 6 checks use the real target source membership and macOS preview macro plugin, checking changed/new files as primary sources with the remaining target files as declaration context. They do not link an application or establish runtime correctness.

Passed:

- Swift 6 type checking of all 32 changed/new Swift files as primary sources in both Live and Mock contexts, including preview macro expansion.
- Swift syntax parsing and strict SwiftLint checks for those 32 sources.
- `git diff --check` and project plist validation.
- Source membership review: all eight new shared Swift files belong to Live and Mock; no missing or duplicate source entries; Mock excludes `Live/` implementations; the deleted size environment has no remaining project reference.

No performance improvement percentage, visual correctness, or resolution of all geometry warnings is claimed.
