// Copyright 5calls. All rights reserved. See LICENSE for details.

import XCTest
@testable import FiveCalls

final class DashboardIssueQueryTests: XCTestCase {
    private let environment = Category(name: "Environment")
    private let health = Category(name: "Health")
    private let taxes = Category(name: "Taxes")

    //harness:criterion=c-dashboard-issue-query-helper-exists,c-query-search-gte3-all-issues-then-category,c-query-tests-cover-all-six-branches
    func testSearchWithSelectedCategorySearchesAllIssuesBeforeCategoryFilter() {
        let activeEnvironmentMatch = issue(id: 1, name: "Environment bill", categories: [environment], active: true)
        let inactiveEnvironmentMatch = issue(id: 2, name: "Environmental cleanup", categories: [environment], active: false)
        let activeHealthMatch = issue(id: 3, name: "Environment health funds", categories: [health], active: true)
        let unrelated = issue(id: 4, name: "Protect voting access", categories: [environment], active: true)

        let query = DashboardIssueQuery(
            searchText: "env",
            showAllIssues: false,
            selectedCategory: environment,
            allIssues: [activeEnvironmentMatch, inactiveEnvironmentMatch, activeHealthMatch, unrelated]
        )

        XCTAssertEqual(Set(query.allIssues.map(\.id)), Set([1, 2]))
    }

    //harness:criterion=c-query-search-gte3-no-category-returns-all-matching,c-query-tests-cover-all-six-branches
    func testSearchWithAllChipReturnsMatchingIssuesAcrossCategories() {
        let environmentMatch = issue(id: 1, name: "Tax policy cleanup", categories: [environment], active: true)
        let inactiveHealthMatch = issue(id: 2, name: "Health tax credits", categories: [health], active: false)
        let categoryNameMatch = issue(id: 3, name: "Tax revenue bill", categories: [taxes], active: true)
        let unrelated = issue(id: 4, name: "Voting access", categories: [health], active: true)

        let query = DashboardIssueQuery(
            searchText: "tax",
            showAllIssues: false,
            selectedCategory: nil,
            allIssues: [environmentMatch, inactiveHealthMatch, categoryNameMatch, unrelated]
        )

        XCTAssertEqual(Set(query.allIssues.map(\.id)), Set([1, 2, 3]))
    }

    //harness:criterion=c-query-search-lt3-show-all-then-category,c-query-tests-cover-all-six-branches
    func testShortSearchShowAllWithSelectedCategoryIncludesActiveAndInactiveCategoryIssues() {
        let activeEnvironment = issue(id: 1, categories: [environment], active: true)
        let inactiveEnvironment = issue(id: 2, categories: [environment], active: false)
        let activeHealth = issue(id: 3, categories: [health], active: true)

        let query = DashboardIssueQuery(
            searchText: "",
            showAllIssues: true,
            selectedCategory: environment,
            allIssues: [activeEnvironment, inactiveEnvironment, activeHealth]
        )

        XCTAssertEqual(Set(query.allIssues.map(\.id)), Set([1, 2]))
    }

    //harness:criterion=c-query-search-lt3-show-all-no-category,c-query-tests-cover-all-six-branches
    func testShortSearchShowAllWithAllChipReturnsEveryLoadedIssue() {
        let issues = [
            issue(id: 1, categories: [environment], active: true),
            issue(id: 2, categories: [environment], active: false),
            issue(id: 3, categories: [health], active: true),
            issue(id: 4, categories: [taxes], active: false),
        ]

        let query = DashboardIssueQuery(
            searchText: "",
            showAllIssues: true,
            selectedCategory: nil,
            allIssues: issues
        )

        XCTAssertEqual(Set(query.allIssues.map(\.id)), Set([1, 2, 3, 4]))
    }

    //harness:criterion=c-query-search-lt3-active-only-then-category,c-query-tests-cover-all-six-branches
    func testShortSearchDefaultWithSelectedCategoryReturnsOnlyActiveCategoryIssues() {
        let activeEnvironment = issue(id: 1, categories: [environment], active: true)
        let inactiveEnvironment = issue(id: 2, categories: [environment], active: false)
        let activeHealth = issue(id: 3, categories: [health], active: true)

        let query = DashboardIssueQuery(
            searchText: "",
            showAllIssues: false,
            selectedCategory: environment,
            allIssues: [activeEnvironment, inactiveEnvironment, activeHealth]
        )

        XCTAssertEqual(query.allIssues.map(\.id), [1])
    }

    //harness:criterion=c-query-search-lt3-active-only-no-category,c-query-tests-cover-all-six-branches
    func testShortSearchDefaultWithAllChipReturnsOnlyActiveIssues() {
        let issues = [
            issue(id: 1, categories: [environment], active: true),
            issue(id: 2, categories: [environment], active: false),
            issue(id: 3, categories: [health], active: true),
            issue(id: 4, categories: [taxes], active: false),
        ]

        let query = DashboardIssueQuery(
            searchText: "",
            showAllIssues: false,
            selectedCategory: nil,
            allIssues: issues
        )

        XCTAssertEqual(Set(query.allIssues.map(\.id)), Set([1, 3]))
        XCTAssertTrue(query.allIssues.allSatisfy(\.active))
    }

    //harness:criterion=c-query-all-chip-passthrough
    func testAllChipAppliesNoCategoryFilterAcrossSearchAndMoreFewerStates() {
        let issues = [
            issue(id: 1, name: "Climate tax bill", categories: [environment], active: true),
            issue(id: 2, name: "Health tax bill", categories: [health], active: false),
            issue(id: 3, name: "Tax voting access", categories: [taxes], active: true),
        ]

        let searchQuery = DashboardIssueQuery(searchText: "tax", showAllIssues: false, selectedCategory: nil, allIssues: issues)
        XCTAssertEqual(Set(searchQuery.allIssues.map(\.id)), Set([1, 2, 3]))

        let showAllQuery = DashboardIssueQuery(searchText: "", showAllIssues: true, selectedCategory: nil, allIssues: issues)
        XCTAssertEqual(Set(showAllQuery.allIssues.map(\.id)), Set([1, 2, 3]))

        let activeOnlyQuery = DashboardIssueQuery(searchText: "", showAllIssues: false, selectedCategory: nil, allIssues: issues)
        XCTAssertEqual(Set(activeOnlyQuery.allIssues.map(\.id)), Set([1, 3]))
    }

    //harness:criterion=c-chip-list-deduplication,c-query-tests-cover-dedup-and-sort
    func testCategoryChipSourceDeduplicatesCategoriesFromLoadedIssues() {
        let issues = [
            issue(id: 1, categories: [environment]),
            issue(id: 2, categories: [environment]),
            issue(id: 3, categories: [environment]),
            issue(id: 4, categories: [health]),
            issue(id: 5, categories: [health]),
        ]

        let categories = DashboardIssueQuery.categories(from: issues)

        XCTAssertEqual(categories, [environment, health])
    }

    //harness:criterion=c-chip-list-sort-order,c-chip-row-all-chip-always-first,c-query-tests-cover-dedup-and-sort
    func testCategoryChipsPlaceAllFirstThenSortCategoriesCaseInsensitively() {
        let chips = DashboardIssueQuery.chips(
            from: [Category(name: "zebra"), Category(name: "apple"), Category(name: "Mango"), Category(name: "apple")],
            allLabel: "All"
        )

        XCTAssertNil(chips.first?.category)
        XCTAssertEqual(chips.map(\.label), ["All", "apple", "Mango", "zebra"])
    }

    //harness:criterion=c-selected-category-reset-on-refresh,c-query-tests-cover-reset-on-refresh
    func testSelectedCategoryResetsWhenRefreshRemovesCategory() {
        let refreshedIssues = [issue(id: 1, categories: [health])]

        let selectedCategory = DashboardIssueQuery.selectedCategoryAfterRefresh(environment, issues: refreshedIssues)

        XCTAssertNil(selectedCategory)
    }

    //harness:criterion=c-selected-category-retained-on-refresh
    func testSelectedCategoryIsRetainedWhenRefreshStillContainsCategory() {
        let refreshedIssues = [
            issue(id: 1, categories: [health]),
            issue(id: 2, categories: [environment]),
        ]

        let selectedCategory = DashboardIssueQuery.selectedCategoryAfterRefresh(environment, issues: refreshedIssues)

        XCTAssertEqual(selectedCategory, environment)
    }

    //harness:criterion=c-chip-row-accessibility-label,c-query-tests-cover-chip-labels
    func testChipLabelsExposeLocalizedAllAndCategoryNames() {
        let allLabel = String(localized: "All", comment: "Dashboard category filter chip for all issues")
        let chips = DashboardIssueQuery.chips(from: [health, environment], allLabel: allLabel)

        XCTAssertEqual(chips[0].label, allLabel)
        XCTAssertEqual(chips[0].accessibilityLabel, allLabel)
        XCTAssertEqual(chips[1].label, "Environment")
        XCTAssertEqual(chips[1].accessibilityLabel, "Environment")
        XCTAssertEqual(chips[2].label, "Health")
        XCTAssertEqual(chips[2].accessibilityLabel, "Health")
    }

    //harness:criterion=c-chip-row-all-chip-selected-by-default
    func testNilSelectedCategoryRepresentsSelectedAllChip() {
        let chips = DashboardIssueQuery.chips(from: [environment], allLabel: "All")
        let selectedCategory: Category? = nil

        XCTAssertEqual(chips.first?.label, "All")
        XCTAssertEqual(chips.first?.category, selectedCategory)
        XCTAssertNotEqual(chips.last?.category, selectedCategory)
    }

    //harness:criterion=c-chip-row-category-chip-selected-state
    func testSelectedCategoryMatchesOnlyThatCategoryChip() {
        let chips = DashboardIssueQuery.chips(from: [environment, health], allLabel: "All")
        let selectedCategory: Category? = health

        let selectedLabels = chips.filter { $0.category == selectedCategory }.map(\.label)

        XCTAssertEqual(selectedLabels, ["Health"])
        XCTAssertNotEqual(chips.first?.category, selectedCategory)
    }

    //harness:criterion=c-grouped-mode-filters-to-selected-category-section
    func testGroupedShowAllModeWithSelectedCategoryShowsOnlySelectedCategorySection() {
        let issues = [
            issue(id: 1, categories: [environment]),
            issue(id: 2, categories: [health]),
        ]
        let query = DashboardIssueQuery(searchText: "", showAllIssues: true, selectedCategory: environment, allIssues: issues)

        XCTAssertEqual(query.categorizedIssues.count, 1)
        XCTAssertEqual(query.categorizedIssues.first?.category, environment)
        XCTAssertEqual(query.categorizedIssues.first?.issues.map(\.id), [1])
    }

    //harness:criterion=c-grouped-mode-no-category-shows-all-sections
    func testGroupedShowAllModeWithAllChipShowsEveryCategorySection() {
        let issues = [
            issue(id: 1, categories: [environment]),
            issue(id: 2, categories: [health]),
        ]
        let query = DashboardIssueQuery(searchText: "", showAllIssues: true, selectedCategory: nil, allIssues: issues)

        XCTAssertEqual(Set(query.categorizedIssues.map(\.category)), Set([environment, health]))
        XCTAssertEqual(query.categorizedIssues.count, 2)
    }

    //harness:criterion=c-search-mode-flat-list-preserved
    func testSearchModeKeepsFlatIssueSectionsWithAndWithoutCategoryFilter() {
        let issues = [
            issue(id: 1, name: "Environment bill", categories: [environment]),
            issue(id: 2, name: "Environment health bill", categories: [health]),
        ]

        let allSearch = DashboardIssueQuery(searchText: "env", showAllIssues: true, selectedCategory: nil, allIssues: issues)
        XCTAssertEqual(allSearch.categorizedIssues.count, 2)
        XCTAssertTrue(allSearch.categorizedIssues.allSatisfy { $0.issues.count == 1 })
        XCTAssertEqual(Set(allSearch.categorizedIssues.map(\.category.name)), Set(["1", "2"]))

        let filteredSearch = DashboardIssueQuery(searchText: "env", showAllIssues: true, selectedCategory: environment, allIssues: issues)
        XCTAssertEqual(filteredSearch.categorizedIssues.count, 1)
        XCTAssertEqual(filteredSearch.categorizedIssues.first?.category.name, "1")
        XCTAssertEqual(filteredSearch.categorizedIssues.first?.issues.first?.id, 1)
    }

    //harness:criterion=c-fewer-mode-flat-list-preserved
    func testFewerModeKeepsFlatIssueSectionsWithAndWithoutCategoryFilter() {
        let issues = [
            issue(id: 1, categories: [environment], active: true),
            issue(id: 2, categories: [health], active: true),
            issue(id: 3, categories: [environment], active: false),
        ]

        let allActive = DashboardIssueQuery(searchText: "", showAllIssues: false, selectedCategory: nil, allIssues: issues)
        XCTAssertEqual(allActive.categorizedIssues.count, 2)
        XCTAssertTrue(allActive.categorizedIssues.allSatisfy { $0.issues.count == 1 })
        XCTAssertEqual(Set(allActive.categorizedIssues.map(\.category.name)), Set(["1", "2"]))

        let filteredActive = DashboardIssueQuery(searchText: "", showAllIssues: false, selectedCategory: environment, allIssues: issues)
        XCTAssertEqual(filteredActive.categorizedIssues.count, 1)
        XCTAssertEqual(filteredActive.categorizedIssues.first?.category.name, "1")
        XCTAssertEqual(filteredActive.categorizedIssues.first?.issues.first?.id, 1)
    }

    //harness:criterion=c-more-fewer-footer-hidden-only-while-searching
    func testFooterHiddenConditionDependsOnlyOnActiveSearch() {
        XCTAssertTrue(DashboardIssueQuery.isSearching(searchText: "env"))

        let selectedCategoryQuery = DashboardIssueQuery(
            searchText: "",
            showAllIssues: false,
            selectedCategory: environment,
            allIssues: [issue(id: 1, categories: [environment])]
        )
        XCTAssertFalse(selectedCategoryQuery.isSearching)
    }

    private func issue(
        id: Int,
        name: String? = nil,
        categories: [Category],
        active: Bool = true,
        meta: String = "",
        reason: String = "Call Congress about this issue",
        script: String = "Please support this issue"
    ) -> Issue {
        Issue(
            id: id,
            meta: meta,
            name: name ?? "Issue \(id)",
            slug: "issue-\(id)",
            reason: reason,
            script: script,
            categories: categories,
            active: active,
            outcomeModels: [],
            contactType: "reps",
            contactAreas: ["US House", "US Senate"],
            createdAt: Date(timeIntervalSince1970: TimeInterval(id)),
            actions: nil
        )
    }
}
