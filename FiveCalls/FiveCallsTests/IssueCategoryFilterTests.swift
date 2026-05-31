// Copyright 5calls. All rights reserved. See LICENSE for details.

import SwiftUI
import XCTest
@testable import FiveCalls

final class IssueCategoryFilterTests: XCTestCase {
    private let civilRights = Category(name: "Civil Rights")
    private let environment = Category(name: "Environment")
    private let healthcare = Category(name: "Healthcare")

    func testAllChipIsFirst() {
        //harness:criterion=c-category-filter-view-exists,c-all-chip-always-first
        let view = CategoryFilterView(
            categories: [environment, civilRights],
            selectedCategory: .constant(nil)
        )

        XCTAssertEqual(view.options.first?.label, "All")
        XCTAssertNil(view.options.first?.category)
    }

    func testAllChipSelectedByDefault() {
        //harness:criterion=c-all-chip-selected-by-default
        let options = CategoryFilterOption.options(
            categories: [civilRights, environment],
            selectedCategory: nil
        )

        XCTAssertTrue(options[0].isSelected)
        XCTAssertTrue(options.dropFirst().allSatisfy { !$0.isSelected })
    }

    func testCategoryOptionsDedupAndSort() {
        //harness:criterion=c-category-chips-derived-deduped-sorted,c-shallow-test-category-options-dedup-sort
        let issues = [
            makeIssue(id: 1, categories: [environment]),
            makeIssue(id: 2, categories: [civilRights, environment]),
            makeIssue(id: 3, categories: [environment]),
        ]

        XCTAssertEqual(
            IssueCategoryFilter.categoryOptions(from: issues),
            [civilRights, environment]
        )
    }

    func testChipSelectionUpdatesState() {
        //harness:criterion=c-chip-selection-updates-state
        var selectedCategory: Category?
        let options = CategoryFilterOption.options(
            categories: [civilRights, environment],
            selectedCategory: selectedCategory
        )

        CategoryFilterOption.select(options[2], selectedCategory: &selectedCategory)

        XCTAssertEqual(selectedCategory, environment)
    }

    func testAllChipSelectionClearsState() {
        //harness:criterion=c-all-chip-selection-clears-state
        var selectedCategory: Category? = environment
        let options = CategoryFilterOption.options(
            categories: [civilRights, environment],
            selectedCategory: selectedCategory
        )

        CategoryFilterOption.select(options[0], selectedCategory: &selectedCategory)

        XCTAssertNil(selectedCategory)
    }

    func testNilCategoryReturnsAllIssues() {
        //harness:criterion=c-filter-all-category-nil-returns-all-issues
        let issues = [
            makeIssue(id: 10, categories: [civilRights]),
            makeIssue(id: 11, categories: [environment]),
            makeIssue(id: 12, categories: [healthcare]),
        ]

        let result = IssueCategoryFilter.filteredIssues(
            from: issues,
            searchText: "",
            showAllIssues: true,
            selectedCategory: nil
        )

        XCTAssertEqual(result.map(\.id), [10, 11, 12])
    }

    func testSelectedCategoryKeepsMatchingIssues() {
        //harness:criterion=c-filter-selected-category-keeps-matching-issues
        let issues = [
            makeIssue(id: 20, categories: [civilRights]),
            makeIssue(id: 21, categories: [environment]),
            makeIssue(id: 22, categories: [civilRights, environment]),
        ]

        let result = IssueCategoryFilter.filteredIssues(
            from: issues,
            searchText: "",
            showAllIssues: true,
            selectedCategory: civilRights
        )

        XCTAssertEqual(result.map(\.id).sorted(), [20, 22])
        XCTAssertTrue(result.allSatisfy { $0.categories.contains(civilRights) })
    }

    func testSelectedCategoryExcludesNonMatchingIssues() {
        //harness:criterion=c-filter-selected-category-excludes-nonmatching-issues
        let issues = [
            makeIssue(id: 30, categories: [civilRights]),
            makeIssue(id: 31, categories: [environment]),
            makeIssue(id: 32, categories: [civilRights, environment]),
        ]

        let result = IssueCategoryFilter.filteredIssues(
            from: issues,
            searchText: "",
            showAllIssues: true,
            selectedCategory: civilRights
        )

        XCTAssertFalse(result.map(\.id).contains(31))
        XCTAssertTrue(result.allSatisfy { $0.categories.contains(civilRights) })
    }

    func testActiveOnlyThenCategoryFilter() {
        //harness:criterion=c-precedence-active-only-then-category
        let issues = [
            makeIssue(id: 40, categories: [environment], active: true),
            makeIssue(id: 41, categories: [environment], active: false),
            makeIssue(id: 42, categories: [civilRights], active: true),
        ]

        let result = IssueCategoryFilter.filteredIssues(
            from: issues,
            searchText: "",
            showAllIssues: false,
            selectedCategory: environment
        )

        XCTAssertEqual(result.map(\.id), [40])
        XCTAssertTrue(result.allSatisfy { $0.active && $0.categories.contains(environment) })
    }

    func testAllIssuesThenCategoryFilter() {
        //harness:criterion=c-precedence-all-issues-then-category
        let issues = [
            makeIssue(id: 50, categories: [environment], active: true),
            makeIssue(id: 51, categories: [environment], active: false),
            makeIssue(id: 52, categories: [civilRights], active: true),
        ]

        let result = IssueCategoryFilter.filteredIssues(
            from: issues,
            searchText: "",
            showAllIssues: true,
            selectedCategory: environment
        )

        XCTAssertEqual(result.map(\.id).sorted(), [50, 51])
    }

    func testSearchActiveNoCategoryFilter() {
        //harness:criterion=c-precedence-search-active-no-category
        let issues = [
            makeIssue(id: 60, name: "Environment Bill", categories: [environment]),
            makeIssue(id: 61, name: "Civil Rights Act", categories: [civilRights]),
            makeIssue(id: 62, name: "Environmental Policy", categories: [civilRights]),
        ]

        let result = IssueCategoryFilter.filteredIssues(
            from: issues,
            searchText: "env",
            showAllIssues: true,
            selectedCategory: nil
        )

        XCTAssertEqual(result.map(\.id).sorted(), [60, 62])
    }

    func testSearchActiveWithCategoryFilter() {
        //harness:criterion=c-precedence-search-active-with-category
        let issues = [
            makeIssue(id: 70, name: "Environment Bill", categories: [environment]),
            makeIssue(id: 71, name: "Environmental Policy", categories: [civilRights]),
            makeIssue(id: 72, name: "Civil Rights Act", categories: [civilRights]),
        ]

        let result = IssueCategoryFilter.filteredIssues(
            from: issues,
            searchText: "env",
            showAllIssues: true,
            selectedCategory: environment
        )

        XCTAssertEqual(result.map(\.id), [70])
    }

    func testMoreFewerNoCategoryFilter() {
        //harness:criterion=c-precedence-more-fewer-no-category
        let issues = [
            makeIssue(id: 80, categories: [environment], active: true),
            makeIssue(id: 81, categories: [environment], active: false),
            makeIssue(id: 82, categories: [environment], active: true),
        ]

        let fewerResult = IssueCategoryFilter.filteredIssues(
            from: issues,
            searchText: "",
            showAllIssues: false,
            selectedCategory: nil
        )
        let moreResult = IssueCategoryFilter.filteredIssues(
            from: issues,
            searchText: "",
            showAllIssues: true,
            selectedCategory: nil
        )

        XCTAssertEqual(fewerResult.map(\.id), [80, 82])
        XCTAssertEqual(moreResult.map(\.id), [80, 81, 82])
    }

    func testSearchBelow3CharsNoFilter() {
        //harness:criterion=c-search-below-3-chars-no-search-filter
        let issues = [
            makeIssue(id: 90, name: "Environment Bill", categories: [environment]),
            makeIssue(id: 91, name: "Civil Rights Act", categories: [civilRights]),
            makeIssue(id: 92, name: "Healthcare Funding", categories: [healthcare]),
        ]

        let shortSearchResult = IssueCategoryFilter.filteredIssues(
            from: issues,
            searchText: "en",
            showAllIssues: true,
            selectedCategory: nil
        )
        let emptySearchResult = IssueCategoryFilter.filteredIssues(
            from: issues,
            searchText: "",
            showAllIssues: true,
            selectedCategory: nil
        )

        XCTAssertEqual(shortSearchResult.map(\.id), emptySearchResult.map(\.id))
        XCTAssertEqual(shortSearchResult.count, 3)
    }

    func testRefreshRemovesSelectedCategoryResetsToNil() {
        //harness:criterion=c-refresh-resets-selected-category,c-shallow-test-refresh-removal-resets-selection
        var selectedCategory: Category? = environment
        let updatedIssues = [
            makeIssue(id: 100, categories: [civilRights]),
            makeIssue(id: 101, categories: [healthcare]),
        ]

        IssueCategoryFilter.validateSelectedCategory(&selectedCategory, for: updatedIssues)

        XCTAssertNil(selectedCategory)
    }

    func testRefreshPreservesValidSelectedCategory() {
        //harness:criterion=c-refresh-preserves-valid-selected-category
        var selectedCategory: Category? = environment
        let updatedIssues = [
            makeIssue(id: 110, categories: [civilRights]),
            makeIssue(id: 111, categories: [environment]),
        ]

        IssueCategoryFilter.validateSelectedCategory(&selectedCategory, for: updatedIssues)

        XCTAssertEqual(selectedCategory, environment)
    }

    func testExistingSearchBehaviorPreserved() {
        //harness:criterion=c-existing-search-behavior-preserved
        let issues = [
            makeIssue(id: 120, name: "Civil Rights Act", categories: [civilRights]),
            makeIssue(id: 121, reason: "Protect civic access", categories: [environment]),
            makeIssue(id: 122, script: "Ask for civil liberties support", categories: [healthcare]),
            makeIssue(id: 123, slug: "civil-budget", categories: [healthcare]),
            makeIssue(id: 124, categories: [Category(name: "Civic Engagement")]),
            makeIssue(id: 125, name: "Healthcare Funding", categories: [healthcare]),
        ]

        let result = IssueCategoryFilter.filteredIssues(
            from: issues,
            searchText: "civ",
            showAllIssues: false,
            selectedCategory: nil
        )

        XCTAssertEqual(result.map(\.id).sorted(), [120, 121, 122, 123, 124])
    }

    func testExistingSortOrderPreserved() {
        //harness:criterion=c-existing-sort-order-preserved
        let issues = [
            makeIssue(id: 130, meta: "CA", categories: [environment], createdAt: 100),
            makeIssue(id: 131, categories: [environment], createdAt: 400),
            makeIssue(id: 132, meta: "NY", categories: [environment], createdAt: 300),
            makeIssue(id: 133, meta: "TX", categories: [civilRights], createdAt: 500),
        ]
        let unfilteredResult = IssueCategoryFilter.filteredIssues(
            from: issues,
            searchText: "",
            showAllIssues: true,
            selectedCategory: nil
        )
        let filteredResult = IssueCategoryFilter.filteredIssues(
            from: issues,
            searchText: "",
            showAllIssues: true,
            selectedCategory: environment
        )

        XCTAssertEqual(
            filteredResult.map(\.id),
            unfilteredResult.filter { $0.categories.contains(environment) }.map(\.id)
        )
    }

    func testChipAccessibilityLabels() {
        //harness:criterion=c-category-chip-voiceover-label
        let options = CategoryFilterOption.options(
            categories: [civilRights, environment],
            selectedCategory: nil
        )

        XCTAssertEqual(options.count, 3)
        for option in options {
            XCTAssertFalse(option.accessibilityLabel.isEmpty)
            XCTAssertFalse(option.accessibilityIdentifier.isEmpty)
        }
    }

    func testActiveOnlyAllCategory() {
        //harness:criterion=c-unit-tests-active-only-all-category
        let issues = [
            makeIssue(id: 140, categories: [civilRights], active: true),
            makeIssue(id: 141, categories: [environment], active: false),
            makeIssue(id: 142, categories: [healthcare], active: true),
        ]

        let result = IssueCategoryFilter.filteredIssues(
            from: issues,
            searchText: "",
            showAllIssues: false,
            selectedCategory: nil
        )

        XCTAssertEqual(result.map(\.id).sorted(), [140, 142])
    }

    func testActiveOnlySelectedCategory() {
        //harness:criterion=c-unit-tests-active-only-selected-category
        let issues = [
            makeIssue(id: 150, categories: [environment], active: true),
            makeIssue(id: 151, categories: [environment], active: false),
            makeIssue(id: 152, categories: [civilRights], active: true),
        ]

        let result = IssueCategoryFilter.filteredIssues(
            from: issues,
            searchText: "",
            showAllIssues: false,
            selectedCategory: environment
        )

        XCTAssertEqual(result.map(\.id), [150])
    }

    func testAllIssuesAllCategory() {
        //harness:criterion=c-unit-tests-all-issues-all-category
        let issues = [
            makeIssue(id: 160, categories: [civilRights], active: true),
            makeIssue(id: 161, categories: [environment], active: false),
            makeIssue(id: 162, categories: [healthcare], active: true),
        ]

        let result = IssueCategoryFilter.filteredIssues(
            from: issues,
            searchText: "",
            showAllIssues: true,
            selectedCategory: nil
        )

        XCTAssertEqual(result.map(\.id), [160, 161, 162])
    }

    func testAllIssuesSelectedCategory() {
        //harness:criterion=c-unit-tests-all-issues-selected-category
        let issues = [
            makeIssue(id: 170, categories: [environment], active: true),
            makeIssue(id: 171, categories: [environment], active: false),
            makeIssue(id: 172, categories: [civilRights], active: true),
        ]

        let result = IssueCategoryFilter.filteredIssues(
            from: issues,
            searchText: "",
            showAllIssues: true,
            selectedCategory: environment
        )

        XCTAssertEqual(result.map(\.id).sorted(), [170, 171])
    }

    func testInlineFixtureConstruction() {
        //harness:criterion=c-unit-tests-use-inline-fixtures
        let issue = makeIssue(
            id: 180,
            name: "Inline fixture",
            categories: [environment],
            active: false
        )

        XCTAssertEqual(issue.id, 180)
        XCTAssertFalse(issue.active)
        XCTAssertEqual(issue.categories, [environment])
    }

    private func makeIssue(
        id: Int,
        meta: String = "",
        name: String? = nil,
        slug: String? = nil,
        reason: String = "",
        script: String = "",
        categories: [Category],
        active: Bool = true,
        createdAt: TimeInterval = 1_700_000_000
    ) -> Issue {
        Issue(
            id: id,
            meta: meta,
            name: name ?? "Issue \(id)",
            slug: slug ?? "issue-\(id)",
            reason: reason,
            script: script,
            categories: categories,
            active: active,
            outcomeModels: [],
            contactType: "reps",
            contactAreas: [],
            createdAt: Date(timeIntervalSince1970: createdAt),
            actions: nil
        )
    }
}
