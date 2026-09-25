---
version: alpha
name: Diffy
description: A native macOS workbench for reading, organizing, and publishing code changes.
colors:
  primary: "#7862D9"
  background: "#F6F8FA"
  surface: "#FFFFFF"
  text: "#303540"
  border: "#E3E6ED"
  success: "#25886C"
  danger: "#D05B72"
  warning: "#BA8740"
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
  status-banner: {}
  badge: {}
  patch: {}
---

# Diffy Design System

## Overview

A quiet Mac workbench: a repository's commit line is the organizing visual, with changes and branch position beside it. Developers should be able to see where they are, what changed, and what to do next without a wall of metrics. This is a product interface, used repeatedly on a laptop or desktop. The product brief establishes native macOS conventions; no specific geographic market is prescribed. Current copy is English; dates and numbers use the system locale.

The signature is a fine commit spine, violet reference labels, and restrained semantic change colors. The design must not resemble a terminal dashboard or a marketing site. Native controls and readable paths take priority over decoration.

`DiffyTheme.swift` remains the canonical runtime color source; this document mirrors its Porcelain palette and default accent. Safira supplies the existing dark counterparts. `DiffyContentSize` owns workspace content scaling. No generated CSS or web token layer is used.

## Colors

Use the theme's background, surface, elevated, border, text, and secondaryText roles. Accent identifies selection and navigation, added indicates positive changes, removed indicates deletions/errors, and modified signals conflicts. Status always includes a label or icon. Git output signs remain visible so color is supplementary. Preserve user-selected accent colors across both themes.

`WorkspaceDefaults.starterBuckets` owns the sole default Bucket, Personal, with the former Backend teal (`#319B90`). Custom Buckets retain their chosen colors.

## Typography

SF Pro carries page titles (28 semibold), section titles (15–18 semibold), and 11–13 point utility copy. SF Mono or the user's editor font size carries patches and commit hashes. Large counts use light rounded system type, only in the overview. Paths may truncate in compact lists; selectable full values appear in detail views. Do not use decorative typefaces for Git actions.

## Layout

Workspace pages use 24–32 point outer spacing and 20–30 point section gaps. Settings uses a 780 × 680 point scrollable window. Project changes use the original resizable folder tree beside the split/unified comparison canvas. Keep the comparison toolbar, source headers, connected change regions, and optional Review Notes panel in that hierarchy. Git actions sit in a compact contextual bar; the commit composer opens on demand. Other pages own one vertical ScrollView. Lists use lazy rows and explicit load-more where useful. The existing minimum workspace size is 1050 × 650. Preserve native scrollbars and keyboard navigation. Do not lock a shared page's scroll position to size a child pane.

## Elevation & Depth

Separate surfaces with tone and one-point borders. Do not add marketing shadows, atmospheric gradients, or nested cards. Native sheets are reserved for focused comparisons and confirmations. Branch and revision reviews fill the owning workspace with a fixed title, prominent Close button, and a single vertical list of file sections. Each section uses a GitHub-familiar filename/status/delta/Viewed header above Diffy’s existing split/unified canvas and change connectors. Operation summaries begin with collapsed sections; branch reviews begin expanded. Keep the styling in the existing theme, not GitHub colors.

## Shapes

Use 10–12 point rounded surfaces and 6–8 point selected rows and status banners. Keep native button, field, menu, and picker geometry. SF Symbols provide the visual vocabulary; icons supplement clear verbs.

## Components

`DiffyPageHeading` owns eyebrow/title/detail hierarchy. `DiffyStatusBanner` owns textual error and status feedback. `DiffyBadge` owns compact statuses. `RepositoryCommitRow` owns the commit spine and explicitly receives whether it draws a trailing connector. `ComparisonScreen`, `FileNavigatorScreen`, `TextDiffScreen`, and `DiffToolbar` own the comparison experience in both Live and Mock. Live data must feed these shared components, including image tools, rather than replacing them with raw patch output. `ComparisonReviewScreen` owns vertical review modals; `DiffChangeSummary` owns numeric additions/deletions and the compact delta bar. `ComparisonModalSizingController` sizes the native sheet to its parent window. `DiffyPatchTextView` remains a fallback for folder patches.

Buttons use native focus, pressed, disabled, and hover behavior. Bordered prominent emphasis identifies the next deliberate action; destructive actions stay in menus and named confirmations. Native ProgressView is the loading treatment. Keep source content selectable; loading and failure should not pretend a repository is empty.

Search offers a clear action. Native SwiftUI menus and pickers are intentional macOS-owned popups. Secret values are masked by default. The existing tab transition respects Reduce Motion; new data pages add no ambient animation.

Use direct verbs: Stage, Unstage, Commit, Fetch, Pull, Push, Check out, Merge, Rebase. A remote count is labeled as last-fetched knowledge, never live truth. Empty and error states include a route to recovery.

## Do's and Don'ts

- Do reuse the existing Porcelain/Safira themes and app-owned components.
- Do keep Git state, source selection, and action consequences readable together.
- Don't invent charts, activity, checks, or repository data.
- Don't use a green rectangle or a decorative card as a substitute for a working page.
