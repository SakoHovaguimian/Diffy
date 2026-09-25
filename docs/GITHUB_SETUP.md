# GitHub and local Git setup

Use the **Diffy Live** scheme. Mock never runs Git, accesses Keychain, or makes network requests.

## Sign in with GitHub

The primary button is enabled in Diffy Live. If a GitHub App client ID is configured, it uses Diffy's App device flow. Otherwise it invokes the official installed GitHub CLI (`gh auth login --web`). GitHub CLI is available on this development Mac at `/opt/homebrew/bin/gh`; supported lookup locations also include `/usr/local/bin/gh` and `/usr/bin/gh`.

Click **Sign in with GitHub**, copy the displayed code, then click **Open GitHub**. Approve the named provider and choose the intended account. The fallback explicitly identifies its provider as GitHub CLI. Diffy validates the authorized account and stores its own credential in Keychain. CLI configuration is scoped to a private temporary directory and removed after completion or cancellation; normal CLI config and Git credential-helper configuration are not rewritten. The CLI may also save a credential in its own system keychain, which Disconnect in Diffy does not remove.

On a Mac without the CLI, the button explains how to [install GitHub CLI](https://cli.github.com/); token connection remains available. No third-party client ID or secret is copied into Diffy.

## Connect with a token

Open Settings → Accounts → Connect with a personal access token. Create a fine-grained token for the desired repositories, with Contents read access and Pull requests read/write access for reviews and comments (read access is sufficient for browsing). The API verifies the account before saving its token in macOS Keychain. Tokens are never placed in project files or Git URLs. Token expiry or revocation requires reconnecting. If a build has no client ID, this path remains available.

After connecting, choose **Link folder…** for a matching local checkout or **Clone…** and select a parent folder. Clone creates a directory named for the repository; existing directories are never overwritten. Imports are saved in the project library and appear in the workspace. Account connection alone does not clone repositories.

## Browser sign-in with a GitHub App

1. Register your GitHub App, enable Device Flow, and grant Metadata and Contents read access, and Pull requests read/write access for review submission and comments. Check runs require Checks read access.
2. Install the app on the repositories you want to expose.
3. Create the ignored `Config/GitHub.local.xcconfig`:

   ```xcconfig
   DIFFY_GITHUB_CLIENT_ID = your-public-client-id
   DIFFY_GITHUB_APP_SLUG = your-app-slug
   DIFFY_GITHUB_HOST = github.com
   ```

4. Build/run Diffy Live when ready. Settings → Accounts → Sign in with GitHub displays a code. Copy it, open GitHub, and approve it. Choose the desired GitHub account in the browser. Reconnect verifies that you approved the same account.

No client secret or private key belongs in a desktop build. Device-flow App user tokens refresh using their refresh token and public client ID; GitHub does not require a client secret for this flow. Concurrent requests share a refresh operation, and rotated credentials stay in Keychain. Expired refresh tokens or revoked access require reconnecting. Approval polling respects GitHub’s interval and slowdown responses and can be cancelled.

## Local Git transport

The app invokes `/usr/bin/git` with argument arrays, never a shell command. Install Apple's Command Line Tools if Git is unavailable. Configure your repository's `user.name` and `user.email`, plus an SSH agent or HTTPS credential helper, as you would for command-line Git. API sign-in does not change your commit author or grant the Git process credentials. Interactive prompts are disabled; authentication errors are shown with recovery guidance.

The Live target is a directly distributed macOS app without App Sandbox. Git requires access beyond the selected folder for credentials, agents, global configuration, hooks, and linked worktrees. The Mock target remains sandboxed. Both keep hardened runtime enabled. Project references continue using bookmarks and paths; unreadable metadata files are protected from overwrite.

## Repository pages

Working tree and Staged use the original changed-file tree and rich split/unified diff, with source headers, connected change regions, Changes/File display, search, line options, annotations, and image comparison tools. Working tree compares Index to Working tree; Staged compares HEAD to Index. Files load on demand, including untracked paths and renames. Per-file and filtered bulk staging remain available; Commit opens a focused composer. Live source is read-only, while Mock retains its separate in-memory editing drafts. Branches provides comparison, creation, checkout, merge, and rebase. Branch, commit, history, and pull-request comparisons open a near-full-window review sheet with a vertical list of expandable split/unified diffs, file deltas, Viewed checkboxes, filtering, and a clear Close button; folder comparisons currently retain the raw patch fallback. Commits shows the latest 50 commits for any selected local or remote branch. File history opens in the flat Files layout, resets its folder tree fully collapsed, and can browse another branch’s file inventory and history without checking it out. It follows renames, loads up to 500 commits, and opens the full historical commit so earlier filenames stay visible. Pull requests provides account/filter selection and two actions on each item: **Open in GitHub** and **Review**. The local **Fetch & compare** action remains in the item’s context menu. Overview uses the same two actions for assignments and review requests. Conflicts provides whole-file choices, staging, continue, and abort; choosing a side replaces the entire file, including any hand edits. During rebase, “your changes” means the replayed commit. Folders compares the selected trees, including hidden files; choose source directories to omit `.git` and build output.

Fetch, Pull, and Push are in every repository's action bar. Publish branch sets its upstream. Force push only uses `--force-with-lease` and requires confirmation. Remote ahead/behind counts reflect the most recent fetch. Failed or stopped commands refresh the repository so completed changes and conflicts remain visible. Successful Pull, Merge, Rebase, and Check Out actions open a collapsed changed-file summary comparing the actual before/after commits. Successful Fetch shows changes to the tracked upstream, explicitly leaving the working tree unchanged. Expand any file to inspect its Diffy diff. Viewed checkboxes track progress in that open review only; they do not stage files or publish a GitHub review.

## GitHub review page

**Review** opens a near-full-window page without fetching commits or requiring a checkout. Choose the connected account, navigate and filter changed files using the shared folder tree, flat list, change-status, or file-type layouts, switch between unified and split patches, and mark files Viewed locally. The sort menu matches the normal diff navigator, including reverse order; disk edit time and file size are disabled because GitHub patch listings do not provide that metadata. Code fills its pane from the top-left, with horizontal scrolling for long lines. The layout controls stay on one line and move below the file summary when the pane is narrow. GitHub omits patches for some binary or large files and caps the file listing at 3,000; the page identifies missing or partial content and keeps **Open in GitHub** available.

Use a line’s comment button to add an unpublished draft. **Review changes** submits those drafts together with a Comment, Approve, or Request changes review. Comments and change requests require a summary. Own PRs and draft PRs only offer Comment. The page checks the current base/head revision before submitting and attaches the reviewed head SHA to the submission. A changed revision requires reloading and reviewing again. Refreshing or closing with unpublished drafts asks before discarding them; drafts and Viewed flags exist only for the current page and do not synchronize to GitHub. An existing pending review on GitHub must be completed there first.

**Conversation** displays the description, comments, review decisions, and inline discussions. Post a general comment or reply to an inline discussion; these actions publish immediately. The connected account needs Pull requests write permission and repository access. Reconnect or update the app installation/token permissions if GitHub denies submission. Failed requests preserve the draft; after an interrupted submission, check GitHub before retrying to avoid duplicates. No API mutation occurs just by opening the page.

This implements the core review workflow, not every GitHub repository administration feature. Resolving threads, editing/deleting published comments, applying suggestions, managing reviewers, merging, and changing PR metadata remain available through **Open in GitHub**. Markdown can be written in comments; existing content is displayed as text. Mock implementations never publish reviews or comments and never access network credentials.

API references: [Reviews](https://docs.github.com/en/rest/pulls/reviews), [review comments and replies](https://docs.github.com/en/rest/pulls/comments), [conversation comments](https://docs.github.com/en/rest/issues/comments).

## Validation boundary

Source parsing/type checks, SwiftLint, property-list validation, and target membership checks do not establish a signed app's runtime behavior. No Xcode build or automated tests are authorized by the project instructions. Before release, manually verify Keychain access, sign-in approval/expiry/cancellation, private repo credentials, cloning, initial commits, linked worktrees, clean/dirty branch operations, and conflict recovery in a built Live app.

Sources: [GitHub CLI browser login](https://cli.github.com/manual/gh_auth_login), [GitHub device authorization](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-a-user-access-token-for-a-github-app), [token refresh requirements](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/refreshing-user-access-tokens), [Git status format](https://git-scm.com/docs/git-status).
