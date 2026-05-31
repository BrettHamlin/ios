// Copyright 5calls. All rights reserved. See LICENSE for details.

import Foundation

enum IssueCategoryFilter {
    static let minimumSearchLength = 3

    static func categoryOptions(from issues: [Issue]) -> [Category] {
        Array(Set(issues.flatMap(\.categories))).sorted()
    }

    static func validatedSelectedCategory(_ selectedCategory: Category?, for issues: [Issue]) -> Category? {
        guard let selectedCategory else { return nil }
        return issues.contains { $0.categories.contains(selectedCategory) } ? selectedCategory : nil
    }

    static func validateSelectedCategory(_ selectedCategory: inout Category?, for issues: [Issue]) {
        selectedCategory = validatedSelectedCategory(selectedCategory, for: issues)
    }

    static func filteredIssues(
        from issues: [Issue],
        searchText: String,
        showAllIssues: Bool,
        selectedCategory: Category?
    ) -> [Issue] {
        let baseIssues: [Issue]

        if searchText.count >= minimumSearchLength {
            // Preserve the legacy dashboard search path: search all loaded issues
            // regardless of the More/Fewer active-only setting.
            let filteredIssues = issues.filter { issue in
                issue.name.localizedCaseInsensitiveContains(searchText) ||
                    issue.reason.localizedCaseInsensitiveContains(searchText) ||
                    issue.script.localizedCaseInsensitiveContains(searchText) ||
                    issue.slug.localizedCaseInsensitiveContains(searchText) ||
                    issue.categories.contains { category in
                        category.name.localizedCaseInsensitiveContains(searchText)
                    }
            }

            baseIssues = filteredIssues.sorted { issue1, issue2 in
                let issue1NameMatch = issue1.name.localizedCaseInsensitiveContains(searchText)
                let issue2NameMatch = issue2.name.localizedCaseInsensitiveContains(searchText)

                if issue1NameMatch, !issue2NameMatch {
                    return true
                } else if !issue1NameMatch, issue2NameMatch {
                    return false
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
                issue.categories.contains(selectedCategory)
            }
        } else {
            categoryFilteredIssues = baseIssues
        }

        return categoryFilteredIssues.sorted { issue1, issue2 in
            let issue1IsState = issue1.isStateSpecific
            let issue2IsState = issue2.isStateSpecific

            if issue1IsState, !issue2IsState {
                return true
            } else if !issue1IsState, issue2IsState {
                return false
            } else if issue1IsState, issue2IsState {
                return issue1.createdAt > issue2.createdAt
            } else {
                return false
            }
        }
    }
}
