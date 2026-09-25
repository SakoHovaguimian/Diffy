---
version: alpha
name: Diffy
description: A native macOS workbench for reading, organizing, and publishing code changes.
colors:
  primary: "#7862D9"
  background: "#F6F8FA"
  surface: "#FFFFFF"
  text: "#1F2328"
  border: "#D0D7DE"
  success: "#25886C"
  danger: "#D05B72"
  warning: "#986B2B"
typography:
  sans:
    fontFamily: "SF Pro, system-ui, sans-serif"
  mono:
    fontFamily: "SF Mono, Menlo, monospace"
rounded:
  DEFAULT: "10px"
  lg: "12px"
spacing:
  page: "32px"
  section: "26px"
  row: "16px"
components:
  page-heading: {}
  loading-state: {}
  status-banner: {}
  badge: {}
  patch: {}
---

# Diffy Design System

## Overview

A quiet Mac workbench: a repository's commit line is the organizing visual, with changes and branch position beside it. Developers should be able to see where they are, what changed, and what to do next without a wall of metrics. This is a product interface, used repeatedly on a laptop or desktop. The product brief establishes native macOS conventions; no specific geographic market is prescribed. Current copy is English; dates and numbers use the system locale.

The signature is a fine commit spine, violet reference labels, and restrained semantic change colors. The design must not resemble a terminal dashboard or a marketing site. Native controls and readable paths take priority over decoration.

`ThemePaletteCatalog.swift` selects the runtime palette, and `ThemePalette+*.swift` holds the built-in Light and Safira palettes plus adaptations of the user's installed VS Code themes. `DiffyTheme.swift` applies the chosen accent and Diffy's established light/dark change colors. `DiffyContentSize` owns workspace content scaling. No generated CSS or web token layer is used.

## Colors

Use the theme's background, surface, elevated, border, text, and secondaryText roles. Accent identifies selection and navigation, added indicates positive changes, removed indicates deletions/errors, and modified signals conflicts. Status always includes a label or icon. Git output signs remain visible so color is supplementary. Preserve user-selected accents and Diffy's paired light/dark change colors across every theme.

`WorkspaceDefaults.starterBuckets` owns the sole default Bucket, Personal, with the former Backend teal (`#319B90`). Custom Buckets retain their chosen colors.

## Typography

SF Pro carries page titles (28 semibold), section titles (15–18 semibold), and 11–13 point utility copy. SF Mono or the user's editor font size carries patches and commit hashes. Large counts use light rounded system type, only in the overview. Paths may truncate in compact lists; selectable full values appear in detail views. Do not use decorative typefaces for Git actions.

App-owned display names, page and section titles, actions, menus, filters, field labels, short status labels, and interaction tooltips capitalize every word, including words such as A, By, In, Of, Or, The, To, and With. Use `&` instead of `And` in those labels. Preserve established names and acronyms such as GitHub, macOS, iOS, SSH, and URL, along with unit symbols such as pt. Explanatory prose, error details, user-defined names, repository content, paths, code, and immutable source fixtures retain their original casing. Keep display copy separate from stored identifiers and enum raw values wherever those values participate in saved preferences, annotation matching, or cache keys.

## Layout

Workspace pages use 24–32 point outer spacing and 20–30 point section gaps. Settings uses a 780 × 680 point scrollable window. Project changes use the original resizable folder tree beside the split/unified comparison canvas. Keep the comparison toolbar, source headers, connected change regions, and optional Review Notes panel in that hierarchy. Git actions sit in a compact contextual bar; the commit composer opens on demand. Other pages own one vertical ScrollView. Lists use lazy rows and explicit load-more where useful. The existing minimum workspace size is 1050 × 650. Preserve native scrollbars and keyboard navigation. Do not lock a shared page's scroll position to size a child pane.

## Elevation & Depth

Separate surfaces with tone and one-point borders. Do not add marketing shadows, atmospheric gradients, or nested cards. Native sheets are reserved for focused comparisons and confirmations. Branch and revision reviews fill the owning workspace with a fixed title, prominent Close button, and a single vertical list of file sections. Each section uses a GitHub-familiar filename/status/delta/Viewed header above Diffy’s existing split/unified canvas and change connectors. Operation summaries begin with collapsed sections; branch reviews begin expanded. Keep the styling in the existing theme, not GitHub colors.

## Shapes

Use 10–12 point rounded surfaces and 6–8 point selected rows and status banners. Keep native button, field, menu, and picker geometry. SF Symbols provide the action vocabulary; icons supplement clear verbs. File and folder identities use the selected icon theme: Material Icons by default, VSCode Icons, Catppuccin, Catppuccin Perfect, Catppuccin Noctis, NewAge Icons, or monochrome Native Symbols. Catppuccin and Catppuccin Perfect pair Latte artwork with light workspaces and Mocha with dark workspaces. Preserve upstream brand colors; selection, Git status, and Viewed indicators remain separate from file identity.

## Components

`DiffyPageHeading` owns eyebrow/title/detail hierarchy. `DiffyLoadingState` owns every titled loading treatment, pairing a native spinner with a compact work-in-progress label on a quiet bordered surface; control-only spinners remain native and unlabeled. `DiffyStatusBanner` owns textual error and status feedback. `DiffyBadge` owns compact statuses. `GitHubAvatar` owns remote GitHub profile images with an initials fallback, and `PullRequestPeopleSummary` owns compact assignee and requested-reviewer groups. `RepositoryCommitRow` owns the commit spine and explicitly receives whether it draws a trailing connector. `ComparisonScreen`, `FileNavigatorScreen`, `TextDiffScreen`, and `DiffToolbar` own the comparison experience in both Live and Mock. Live data must feed these shared components, including image tools, rather than replacing them with raw patch output. `ComparisonReviewScreen` owns vertical review modals; `DiffChangeSummary` owns numeric additions/deletions and the compact delta bar. `ComparisonModalSizingController` sizes the native sheet to its parent window. `DiffyPatchTextView` remains a fallback for folder patches.

Buttons use native focus, pressed, disabled, and hover behavior. Bordered prominent emphasis identifies the next deliberate action; destructive actions stay in menus and named confirmations. `DiffyLoadingState` keeps the native `ProgressView` spinner as its motion core rather than inventing ambient animation. Keep source content selectable; loading and failure should not pretend a repository is empty.

Search offers a clear action. Native SwiftUI menus and pickers are intentional macOS-owned popups. Secret values are masked by default. The existing tab transition respects Reduce Motion; new data pages add no ambient animation.

Coordinated motion for large view groups is isolated at the group boundary with SwiftUI `geometryGroup()` and `compositingGroup()`. Apply this to opening and closing workspace side panels and layered image canvases rather than to individual rows. Keep Bucket disclosure groups outside this isolation because it interferes with their disclosure and reorder animations. All authored group motion respects Reduce Motion.

`DiffyPathIcon` owns file and folder imagery for every navigator and review header; `DiffFileIcon` adapts comparison models to it. `FileIconService` loads bundled catalogs and caches raster artwork, with theme-specific light/dark and expanded-folder variants. Unknown names use generic icons; unavailable artwork falls back to native symbols. Keep icon geometry fixed and scale it with `DiffyContentSize`. Settings → Appearance provides the native theme picker and common-file preview. `SettingsViewModel.fileIconTheme` persists independently of workspace colors and updates all windows immediately. Previews use the same bundled artwork and in-memory preferences.

Use direct verbs: Stage, Unstage, Commit, Fetch, Pull, Push, Check Out, Merge, Rebase. A remote count is labeled as last-fetched knowledge, never live truth. Empty and error states include a route to recovery.

## Do's and Don'ts

- Do keep Light and Safira as the System appearance fallbacks and retain all app-owned components.
- Do keep Git state, source selection, and action consequences readable together.
- Don't invent charts, activity, checks, or repository data.
- Don't use a green rectangle or a decorative card as a substitute for a working page.
