// Copyright 5calls. All rights reserved. See LICENSE for details.

import Foundation

enum IssueListFilter {
    static func categories(in issues: [Issue]) -> [Category] {
        Array(Set(issues.flatMap(\.categories))).sorted()
    }

    static func filter(
        issues: [Issue],
        showAllIssues: Bool,
        searchText: String,
        selectedCategory: Category?
    ) -> [Issue] {
        let scopedIssues = categorySourceIssues(issues: issues, showAllIssues: showAllIssues)
        let indexedIssues = scopedIssues.enumerated().map { offset, issue in
            IndexedIssue(issue: issue, index: offset)
        }

        let baseIssues: [IndexedIssue]

        if searchText.count >= 3 {
            baseIssues = indexedIssues.filter { indexedIssue in
                matchesSearch(indexedIssue.issue, searchText: searchText)
            }
        } else {
            baseIssues = indexedIssues
        }

        let sortedIssues = baseIssues.sorted { lhs, rhs in
            shouldSortBefore(lhs, rhs, searchText: searchText)
        }.map(\.issue)

        guard let selectedCategory else {
            return sortedIssues
        }

        return sortedIssues.filter { issue in
            issue.categories.contains(selectedCategory)
        }
    }

    static func categorySourceIssues(issues: [Issue], showAllIssues: Bool) -> [Issue] {
        showAllIssues ? issues : issues.filter(\.active)
    }

    private static func shouldSortBefore(
        _ lhs: IndexedIssue,
        _ rhs: IndexedIssue,
        searchText: String
    ) -> Bool {
        let lhsIssue = lhs.issue
        let rhsIssue = rhs.issue
        let lhsIsState = lhsIssue.isStateSpecific
        let rhsIsState = rhsIssue.isStateSpecific

        if lhsIsState != rhsIsState {
            return lhsIsState
        }

        if lhsIsState, rhsIsState, lhsIssue.createdAt != rhsIssue.createdAt {
            return lhsIssue.createdAt > rhsIssue.createdAt
        }

        if searchText.count >= 3 {
            let lhsNameMatch = lhsIssue.name.localizedCaseInsensitiveContains(searchText)
            let rhsNameMatch = rhsIssue.name.localizedCaseInsensitiveContains(searchText)

            if lhsNameMatch != rhsNameMatch {
                return lhsNameMatch
            }
        }

        return lhs.index < rhs.index
    }

    private static func matchesSearch(_ issue: Issue, searchText: String) -> Bool {
        issue.name.localizedCaseInsensitiveContains(searchText) ||
            issue.reason.localizedCaseInsensitiveContains(searchText) ||
            issue.script.localizedCaseInsensitiveContains(searchText) ||
            issue.slug.localizedCaseInsensitiveContains(searchText) ||
            issue.categories.contains(where: { category in
                category.name.localizedCaseInsensitiveContains(searchText)
            })
    }

    static func resetCategoryIfNeeded(issues: [Issue], selectedCategory: Category?) -> Category? {
        guard let selectedCategory else {
            return nil
        }

        return categories(in: issues).contains(selectedCategory) ? selectedCategory : nil
    }

    private struct IndexedIssue {
        let issue: Issue
        let index: Int
    }
}
