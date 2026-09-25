# Persistent PR AI Review

Pull requests open in the main workspace with Conversation, Commits, and Files Changed. Draft comments, Viewed state, and navigation survive closing and reopening a PR within the same workspace. AI results persist across app launches.

## Setup

Open **Settings → AI Review**, choose provider and connection, then use **Refresh Models**. Choose a default model and save. The PR composer also refreshes models when opened or when its provider/connection changes. API and installed-tool catalogs are stored separately: a model offered by a provider API may not work with the same provider's CLI subscription.

- **Provider API:** OpenAI, Anthropic, and Gemini keys are stored only in macOS Keychain.
- **Installed Command-Line Tool:** install and sign in to Codex CLI, Claude Code, or Gemini CLI in Terminal. Diffy detects common installation paths and absolute PATH entries, then checks required flags before generation. Detection confirms installation, not authentication or model access.

The PR header’s **Ask AI** composer supports request overrides. Generate sends bounded PR context for Learning Path, Architecture Map, questions, and note fixes. Risk Map fetches and assesses the complete text diff in successive parts. Opening a PR or restoring history never generates automatically. There is no Diffy backend.

Model discovery uses the saved Keychain key for provider APIs, or the installed tool's own sign-in for CLI connections. Codex reports its model catalog; Claude Code reports models during initialization; Gemini reports models when opening a temporary ACP session. Discovery sends no PR context or analysis prompt. Catalogs can contain account- or capability-dependent entries, so generation still confirms access and structured-output compatibility. A failed refresh keeps the last model list and allows manual IDs, including Claude's documented `[1m]` suffix.

API catalogs follow the providers' model-list interfaces: [OpenAI](https://platform.openai.com/docs/api-reference/models/list), [Anthropic](https://platform.claude.com/docs/en/api/models/list), and [Gemini](https://ai.google.dev/api/models). CLI discovery uses [Codex's model catalog command](https://learn.chatgpt.com/docs/developer-commands), the installed Claude Code control protocol, and [Gemini ACP](https://geminicli.com/docs/cli/acp-mode/). CLI protocols can vary by installed version; unsupported versions surface an error and leave manual selection available.

Diffy shows the catalog source and explains when a previously selected model is absent from the returned list. A successful composer refresh saves model choices without overwriting defaults edited in Settings. **Save AI Settings** explicitly saves default selection and manual model edits.

CLI failures include a bounded, sanitized error reason and exit status. For an unsupported Codex model, refresh the **Installed Command-Line Tool** list instead of copying an API model ID. Authentication, quota, network, and schema failures remain distinct; selecting the API connection requires its own saved key.

## Review & History

Learning Path teaches concepts in dependency order. Architecture Map provides selectable components, relationships, and an inspector. Risk Map starts with an overview and cross-file blast-radius assessment, then lists every changed file by attention level, followed by selectable review-area cards. Selecting a row or card highlights it and opens its inspector; **Open Diff** is a separate action. Generated views join PR navigation. Questions and proposed fixes also remain in local history.

Learning Path steps expand inline. The numbered header toggles the step; **Expand All**, **Collapse All**, **Next**, and **Revisit** support reading at your own pace. The first step opens initially, and disclosure choices stay with each generation for the current PR session. Summaries use plain language; expanded sections explain inputs, behavior, and results with styled Markdown and concrete examples.

The learning contract adds `breakdown_descriptions` (Markdown), `codeReferences` (stable IDs, labels, and exact file paths), and `examples` (code, language, explanation, file, and `source` or `illustrative` kind). Inline code that matches an unambiguous reference label or filename becomes a file link. Explicit Markdown links use `diffy://learning-code/<reference-id>`. Only declared destinations can open, through the existing current/historical diff navigation. Both code examples and their filename headers open the corresponding file; source excerpts are checked against the supplied patch, and illustrative examples are visibly labeled. Older saved paths still load without rewriting records; generate a new path to get the expanded teaching content.

Records retain repository/PR identity, base/head SHA, provider/model, timestamp, prompt, structured output, transmitted context, and captured file/annotation snapshots. Changed revisions are explicitly outdated; unavailable current data is labeled unknown. Historical file links show saved patches instead of borrowing current code.

History lives in `~/Library/Application Support/Diffy/AI/History-v1`, separate from Git caches. Settings use `AI/settings-v1.json`. Private records are published atomically without overwriting earlier UUIDs. Failed saves remain visible as unsaved with a retry action.

`AIContextBuilder` bounds patches, selected files, and local notes for the other AI requests and records omissions. Risk Map bypasses those patch and file-selection limits: it fetches GitHub's raw diff, checks it against the complete changed-file list, sends every text patch in successive parts, and refuses to save if any part or file assessment is missing. Binary diff markers are sent, but binary contents cannot be interpreted as text. `AIReviewPrompts` supplies shared grounding rules and mode-specific pre-prompts; descriptions, code, and comments are untrusted input. Shared schemas and validators reject malformed shapes, invalid references, and graph/step inconsistencies. Native SwiftUI renders structured data; generated UI code is never executed.

Learning Path and Architecture Map headers report the saved number of paths listed, files with patch text, and patches shortened by Diffy. The context disclosure names files without patch text and shortened patches. A listed path alone does not provide the model with that file's code changes.

Every new analysis, question, and note-fix request first refreshes the full paginated PR conversation: issue comments, review summaries (including approval/change-request states), and inline comments/replies. Complete comment bodies, authors, timestamps, URLs, file/line locations, reply IDs, and pending/outdated states are sent and saved with the request. File selection does not filter out discussion. Risk Map includes the conversation explicitly in every diff-part and synthesis prompt, not only in local request metadata. A failed conversation fetch stops the request instead of silently analyzing without comments. Older history still decodes, with absent conversation context distinguished from an empty discussion.

The PR description and all loaded commit summaries are included without text/count truncation. Existing patch, file-inventory, and local-note limits remain recorded in omissions. PR comments are never silently shortened or dropped to meet a provider limit; a provider context-limit failure is surfaced to the user. Comments inform intent and review context but remain untrusted claims, not instructions or proof of code behavior.

Architecture Map may cite changed files only when their text patches were included in the bounded AI context. Diffy supplies the eligible paths explicitly and retries once when a model cites an unavailable patch. Risk Map uses the complete raw diff, requires one assessment per changed file, and validates cited paths against it. A provider context-limit failure is shown instead of silently omitting diff content.

API implementations follow [OpenAI Structured Outputs](https://developers.openai.com/api/docs/guides/structured-outputs), [Anthropic Structured Outputs](https://platform.claude.com/docs/en/build-with-claude/structured-outputs), and [Gemini Structured Output](https://ai.google.dev/gemini-api/docs/generate-content/structured-output). HTTP sessions are ephemeral, and OpenAI requests use `store: false`.

CLI requests run in private temporary directories with minimal environments and bounded, cancellable output. Codex uses read-only sandboxing, ephemeral mode, disabled integrations/tools, and [schema output](https://learn.chatgpt.com/docs/non-interactive-mode). Claude uses safe mode, no tools, isolated MCP configuration, no session persistence, and [JSON schema output](https://code.claude.com/docs/en/cli-reference). Gemini disables extensions, MCP, hooks, and skills and uses a deny-all [tool policy](https://geminicli.com/docs/reference/policy-engine/). Each CLI manages its own sign-in.

## Notes & Apply

The PR line note action captures revision, path, side, line, code, language, and comment. Select notes and choose **Ask AI To Address Notes** to generate a saved plan, file list, uncertainty, and proposed patch.

**Apply Proposed Patch** requires explicit confirmation. Apply first rechecks the current GitHub base/head. The Git service then verifies exact checkout HEAD, permitted paths, clean affected files, safe destinations, and `git apply --check`. Apply changes only the working tree; it never stages, commits, pushes, fetches, or checks out. Binary, rename, link, and mode changes require manual handling. Cancellation is not rollback; inspect the refreshed checkout after an interrupted operation.

Mock and previews use in-memory AI services and immutable fixtures. Network, Keychain, process, and durable AI storage implementations are excluded from Mock via `Live/` target membership.

Source checks, lint, plist checks, and membership inspection do not prove runtime/provider compatibility or visual correctness. No Xcode builds or tests are authorized by this change.
