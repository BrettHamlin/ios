// Copyright 5calls. All rights reserved. See LICENSE for details.

import Foundation

internal enum CategoryFilterOption: Equatable, Hashable, Identifiable {
    case all
    case category(FiveCalls.Category)

    var id: String {
        switch self {
        case .all:
            return "all"
        case let .category(category):
            return "category-\(category.name)"
        }
    }

    var category: FiveCalls.Category? {
        switch self {
        case .all:
            return nil
        case let .category(category):
            return category
        }
    }

    var name: String {
        switch self {
        case .all:
            return String(
                localized: "Category filter all option",
                defaultValue: "All",
                comment: "CategoryFilterBar all categories option"
            )
        case let .category(category):
            return category.name
        }
    }
}

internal enum IssueFilterHelper {
    static func categoryOptions(from issues: [Issue]) -> [CategoryFilterOption] {
        let categories = Set(issues.flatMap(\.categories)).sorted()
        return [.all] + categories.map { .category($0) }
    }

    static func categoryNames(from issues: [Issue]) -> Set<String> {
        Set(issues.flatMap(\.categories).map(\.name))
    }

    static func validatedSelectedCategory(_ selectedCategory: FiveCalls.Category?, issues: [Issue]) -> FiveCalls.Category? {
        guard let selectedCategory else { return nil }

        let categoryIsPresent = categoryNames(from: issues).contains(selectedCategory.name)

        return categoryIsPresent ? selectedCategory : nil
    }

    static func filteredIssues(
        from issues: [Issue],
        showAllIssues: Bool,
        isSearching: Bool,
        searchText: String,
        selectedCategory: FiveCalls.Category?
    ) -> [Issue] {
        let baseIssues: [Issue]

        if isSearching {
            // When searching, search all issues regardless of active status.
            let filteredIssues = issues.filter { issue in
                issue.name.localizedCaseInsensitiveContains(searchText) ||
                    issue.reason.localizedCaseInsensitiveContains(searchText) ||
                    issue.script.localizedCaseInsensitiveContains(searchText) ||
                    issue.slug.localizedCaseInsensitiveContains(searchText) ||
                    issue.categories.contains { category in
                        category.name.localizedCaseInsensitiveContains(searchText)
                    }
            }

            // Sort results with name matches first.
            baseIssues = filteredIssues.sorted { issue1, issue2 in
                let issue1NameMatch = issue1.name.localizedCaseInsensitiveContains(searchText)
                let issue2NameMatch = issue2.name.localizedCaseInsensitiveContains(searchText)

                if issue1NameMatch, !issue2NameMatch {
                    return true // issue1 comes first
                } else if !issue1NameMatch, issue2NameMatch {
                    return false // issue2 comes first
                } else {
                    return false
                }
            }
        } else if showAllIssues {
            baseIssues = issues
        } else {
            baseIssues = issues.filter(\.active)
        }

        let categoryFilteredIssues: [Issue]
        if let selectedCategory {
            categoryFilteredIssues = baseIssues.filter { issue in
                issue.categories.contains { category in
                    category.name == selectedCategory.name
                }
            }
        } else {
            categoryFilteredIssues = baseIssues
        }

        // Prioritize state-specific issues at the top.
        return categoryFilteredIssues.sorted { issue1, issue2 in
            let issue1IsState = issue1.isStateSpecific
            let issue2IsState = issue2.isStateSpecific

            if issue1IsState, !issue2IsState {
                return true // State-specific issues come first
            } else if !issue1IsState, issue2IsState {
                return false // Non-state issues come after
            } else if issue1IsState, issue2IsState {
                // Both are state-specific, sort by createdAt (newest first).
                // TODO: Replace with sort field when available.
                return issue1.createdAt > issue2.createdAt
            } else {
                // Both are non-state, maintain original order (no sorting).
                return false
            }
        }
    }
}
