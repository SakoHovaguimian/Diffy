import SwiftUI

struct TutorialFeature: Identifiable {

    let id: String
    let symbol: String
    let title: String
    let subtitle: String
    let colors: [Color]

    static let essentials: [TutorialFeature] = [
        TutorialFeature(
            id: "changes",
            symbol: "rectangle.split.2x1",
            title: "See every change clearly",
            subtitle: "Compare local changes, commits, branches, and pull requests in a focused workspace.",
            colors: [Color(red: 0.04, green: 0.48, blue: 0.96), Color(red: 0.29, green: 0.78, blue: 0.96)]
        ),
        TutorialFeature(
            id: "notes",
            symbol: "text.bubble.fill",
            title: "Keep your review together",
            subtitle: "Attach notes to code, find them by project, and export them with their source context.",
            colors: [Color(red: 0.36, green: 0.33, blue: 0.92), Color(red: 0.72, green: 0.34, blue: 0.88)]
        ),
        TutorialFeature(
            id: "ai",
            symbol: "sparkles",
            title: "Review with AI",
            subtitle: "Explore risks, ask questions, and generate proposed fixes from selected pull request notes.",
            colors: [Color(red: 1.00, green: 0.58, blue: 0.05), Color(red: 0.98, green: 0.24, blue: 0.43)]
        ),
        TutorialFeature(
            id: "workspace",
            symbol: "folder.fill",
            title: "Make it your workspace",
            subtitle: "Organize projects in Buckets and tailor themes and diff views to the way you work.",
            colors: [Color(red: 0.17, green: 0.74, blue: 0.42), Color(red: 0.15, green: 0.72, blue: 0.77)]
        )
    ]

}
