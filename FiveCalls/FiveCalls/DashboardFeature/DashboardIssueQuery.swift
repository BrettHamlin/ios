// Copyright 5calls. All rights reserved. See LICENSE for details.

import SwiftUI

struct DashboardCategoryChip: Identifiable, Equatable {
    let category: Category?
    let label: String

    var id: String {
        category.map { "category:\($0.name)" } ?? "all"
    }

    var accessibilityLabel: String {
        label
    }
}

struct DashboardIssueQuery {
    let searchText: String
    let showAllIssues: Bool
    let selectedCategory: Category?

    private let loadedIssues: [Issue]

    init(searchText: String, showAllIssues: Bool, selectedCategory: Category?, allIssues: [Issue]) {
        self.searchText = searchText
        self.showAllIssues = showAllIssues
        self.selectedCategory = selectedCategory
        loadedIssues = allIssues
    }

    var isSearching: Bool {
        Self.isSearching(searchText: searchText)
    }

    var allIssues: [Issue] {
        filterBySelectedCategory(stateSortedIssues)
    }

    var categorizedIssues: [CategorizedIssuesViewModel] {
        if isSearching || !showAllIssues {
            // For search results or default view, make fake categories to preserve order and show flat list.
            return allIssues.map { CategorizedIssuesViewModel(category: Category(name: "\($0.id)"), issues: [$0]) }
        }

        if let selectedCategory {
            return allIssues.isEmpty ? [] : [CategorizedIssuesViewModel(category: selectedCategory, issues: allIssues)]
        }

        var result: [CategorizedIssuesViewModel] = []

        // Separate state-specific issues into their own category with the state name.
        let stateIssues = allIssues.filter { $0.isStateSpecific }
        let nonStateIssues = allIssues.filter { !$0.isStateSpecific }

        if !stateIssues.isEmpty {
            let stateName = stateIssues.first?.stateNameFromAbbreviation ?? "State"
            result.append(CategorizedIssuesViewModel(category: Category(name: stateName), issues: stateIssues))
        }

        // Build regular categories from non-state issues only.
        var categoryViewModels = Set<CategorizedIssuesViewModel>()
        for issue in nonStateIssues {
            for category in issue.categories {
                if let categorized = categoryViewModels.first(where: { $0.category == category }) {
                    categorized.issues.append(issue)
                } else {
                    categoryViewModels.insert(CategorizedIssuesViewModel(category: category, issues: [issue]))
                }
            }
        }
        result.append(contentsOf: Array(categoryViewModels).sorted(by: { $0.category < $1.category }))

        return result
    }

    private var sourceIssues: [Issue] {
        if isSearching {
            return loadedIssues
                .filter { issue in
                    issue.name.localizedCaseInsensitiveContains(searchText) ||
                        issue.reason.localizedCaseInsensitiveContains(searchText) ||
                        issue.script.localizedCaseInsensitiveContains(searchText) ||
                        issue.slug.localizedCaseInsensitiveContains(searchText) ||
                        issue.categories.contains { category in
                            category.name.localizedCaseInsensitiveContains(searchText)
                        }
                }
                .sorted { issue1, issue2 in
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
            return loadedIssues
        } else {
            return loadedIssues.filter(\.active)
        }
    }

    private var stateSortedIssues: [Issue] {
        // Prioritize state-specific issues at the top.
        sourceIssues.sorted { issue1, issue2 in
            let issue1IsState = issue1.isStateSpecific
            let issue2IsState = issue2.isStateSpecific

            if issue1IsState, !issue2IsState {
                return true
            } else if !issue1IsState, issue2IsState {
                return false
            } else if issue1IsState, issue2IsState {
                // TODO: Replace with sort field when available.
                return issue1.createdAt > issue2.createdAt
            } else {
                return false
            }
        }
    }

    private func filterBySelectedCategory(_ issues: [Issue]) -> [Issue] {
        guard let selectedCategory else {
            return issues
        }

        return issues.filter { issue in
            issue.categories.contains(selectedCategory)
        }
    }

    static func isSearching(searchText: String) -> Bool {
        searchText.count >= 3
    }

    static func categories(from issues: [Issue]) -> [Category] {
        Array(Set(issues.flatMap(\.categories))).sorted()
    }

    static func chips(from issues: [Issue], allLabel: String = String(localized: "All", comment: "Dashboard category filter chip for all issues")) -> [DashboardCategoryChip] {
        chips(from: categories(from: issues), allLabel: allLabel)
    }

    static func chips(from categories: [Category], allLabel: String = String(localized: "All", comment: "Dashboard category filter chip for all issues")) -> [DashboardCategoryChip] {
        [DashboardCategoryChip(category: nil, label: allLabel)] +
            Array(Set(categories)).sorted().map { DashboardCategoryChip(category: $0, label: $0.name) }
    }

    static func selectedCategoryAfterRefresh(_ selectedCategory: Category?, issues: [Issue]) -> Category? {
        guard let selectedCategory else {
            return nil
        }

        return issues.contains { issue in
            issue.categories.contains(selectedCategory)
        } ? selectedCategory : nil
    }
}

struct CategoryChipRow: View {
    private let categories: [Category]
    @Binding private var selectedCategory: Category?

    init(issues: [Issue], selectedCategory: Binding<Category?>) {
        categories = DashboardIssueQuery.categories(from: issues)
        _selectedCategory = selectedCategory
    }

    init(categories: [Category], selectedCategory: Binding<Category?>) {
        self.categories = Array(Set(categories)).sorted()
        _selectedCategory = selectedCategory
    }

    private var chips: [DashboardCategoryChip] {
        [DashboardCategoryChip(
            category: nil,
            label: String(localized: "All", comment: "Dashboard category filter chip for all issues")
        )] + categories.map { DashboardCategoryChip(category: $0, label: $0.name) }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(chips) { chip in
                    chipButton(chip)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 2)
        }
        .padding(.bottom, 4)
    }

    private func chipButton(_ chip: DashboardCategoryChip) -> some View {
        let isSelected = selectedCategory == chip.category

        return Button {
            selectedCategory = chip.category
        } label: {
            Text(chip.label)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .lineLimit(1)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .foregroundStyle(isSelected ? Color.fivecallsLightBlue : Color.fivecallsDarkBlueText)
                .background(isSelected ? Color.fivecallsDarkBlue : Color(.systemBackground))
                .overlay {
                    Capsule()
                        .stroke(Color.fivecallsDarkBlue, lineWidth: 1)
                }
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(chip.accessibilityLabel))
        .accessibilityValue(Text(isSelected ?
            String(localized: "Selected", comment: "Selected category chip accessibility value") :
            String(localized: "Not selected", comment: "Unselected category chip accessibility value")
        ))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
