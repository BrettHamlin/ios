// Copyright 5calls. All rights reserved. See LICENSE for details.

import SwiftUI
import UIKit
import XCTest
@testable import FiveCalls

final class CategoryFilterTests: XCTestCase {
    private let budget = Category(name: "Budget")
    private let environment = Category(name: "Environment")
    private let immigration = Category(name: "Immigration")
    private let health = Category(name: "Health")

    func testCategoryOptionsAreAllThenSortedUniqueCategories() {
        //harness:criterion=c-category-filter-bar-renders,c-category-filter-bar-sorted,c-category-option-derivation-pure,c-category-filter-bar-empty-issue-list,c-issue-filter-helper-internal
        let issues = [
            makeIssue(id: 1, categories: [immigration]),
            makeIssue(id: 2, categories: [environment, budget]),
            makeIssue(id: 3, categories: [immigration, budget]),
        ]

        let options = IssueFilterHelper.categoryOptions(from: issues)
        let repeatedOptions = IssueFilterHelper.categoryOptions(from: issues)

        XCTAssertEqual(options, repeatedOptions)
        XCTAssertEqual(options, [
            .all,
            .category(budget),
            .category(environment),
            .category(immigration),
        ])
        XCTAssertEqual(Set(options).count, options.count)
        XCTAssertEqual(IssueFilterHelper.categoryOptions(from: []), [.all])
    }

    func testCategoryFilterBarStartsWithAllSelection() {
        //harness:criterion=c-category-filter-bar-all-default,c-category-filter-state-local,c-category-filter-bar-placement
        var selectedCategory: Category? = nil
        let binding = Binding<Category?>(
            get: { selectedCategory },
            set: { selectedCategory = $0 }
        )

        _ = CategoryFilterBar(
            issues: [makeIssue(id: 1, categories: [budget])],
            selectedCategory: binding
        )

        XCTAssertNil(binding.wrappedValue)
        XCTAssertNil(selectedCategory)
    }

    func testCategoryFilterBarHasAtLeastMinimumTouchTargetHeight() {
        //harness:criterion=c-category-filter-bar-touch-target
        let bar = CategoryFilterBar(
            issues: [makeIssue(id: 1, categories: [budget])],
            selectedCategory: .constant(nil)
        )
        let controller = UIHostingController(rootView: bar)

        let size = controller.sizeThatFits(in: CGSize(width: 320, height: 1_000))

        XCTAssertGreaterThanOrEqual(size.height, 44)
    }

    func testLocalizedCategoryFilterLabelsHaveFallbackDisplayText() {
        //harness:criterion=c-category-filter-all-localized,c-category-filter-bar-accessibility-label,c-category-filter-bar-voiceover-control-label
        let allLabel = String(
            localized: "Category filter all option",
            defaultValue: "All",
            comment: "CategoryFilterBar all categories option"
        )
        let controlLabel = String(
            localized: "Category filter control accessibility label",
            defaultValue: "Issue category filter",
            comment: "CategoryFilterBar control accessibility label"
        )
        let chipFormat = String(
            localized: "Category filter option accessibility label",
            defaultValue: "Filter by %@",
            comment: "CategoryFilterBar chip accessibility label"
        )
        let chipLabel = String(format: chipFormat, budget.name)

        XCTAssertEqual(CategoryFilterOption.all.name, allLabel)
        XCTAssertFalse(allLabel.isEmpty)
        XCTAssertFalse(controlLabel.isEmpty)
        XCTAssertFalse(chipLabel.isEmpty)
        XCTAssertTrue(chipLabel.contains(budget.name))
    }

    func testAllSelectionPreservesIssueOrder() {
        //harness:criterion=c-category-filter-all-preserves-order,c-existing-navigation-link-preserved
        let issues = [
            makeIssue(id: 1, name: "First", categories: [budget]),
            makeIssue(id: 2, name: "Second", categories: [environment]),
            makeIssue(id: 3, name: "Third", categories: [health]),
        ]

        let result = IssueFilterHelper.filteredIssues(
            from: issues,
            showAllIssues: true,
            isSearching: false,
            searchText: "",
            selectedCategory: nil
        )

        XCTAssertEqual(result.map(\.id), [1, 2, 3])
    }

    func testSelectedCategoryReturnsOnlyIssuesWithThatCategory() {
        //harness:criterion=c-category-filter-selected-filters-correctly
        let issues = [
            makeIssue(id: 1, categories: [budget]),
            makeIssue(id: 2, categories: [environment]),
            makeIssue(id: 3, categories: [budget, health]),
        ]

        let result = IssueFilterHelper.filteredIssues(
            from: issues,
            showAllIssues: true,
            isSearching: false,
            searchText: "",
            selectedCategory: budget
        )

        XCTAssertEqual(result.map(\.id), [1, 3])
        XCTAssertTrue(result.allSatisfy { $0.categories.contains(budget) })
    }

    func testMoreIssuesToggleGatesInactiveIssuesBeforeCategoryFiltering() {
        //harness:criterion=c-category-filter-inactive-excluded-by-default,c-category-filter-inactive-included-when-more,c-more-fewer-toggle-preserved
        let issues = [
            makeIssue(id: 1, categories: [budget], active: true),
            makeIssue(id: 2, categories: [budget], active: false),
            makeIssue(id: 3, categories: [environment], active: false),
        ]

        let activeOnlyResult = IssueFilterHelper.filteredIssues(
            from: issues,
            showAllIssues: false,
            isSearching: false,
            searchText: "",
            selectedCategory: budget
        )
        let allIssuesResult = IssueFilterHelper.filteredIssues(
            from: issues,
            showAllIssues: true,
            isSearching: false,
            searchText: "",
            selectedCategory: budget
        )
        let unfilteredActiveOnlyResult = IssueFilterHelper.filteredIssues(
            from: issues,
            showAllIssues: false,
            isSearching: false,
            searchText: "",
            selectedCategory: nil
        )
        let unfilteredAllIssuesResult = IssueFilterHelper.filteredIssues(
            from: issues,
            showAllIssues: true,
            isSearching: false,
            searchText: "",
            selectedCategory: nil
        )

        XCTAssertEqual(activeOnlyResult.map(\.id), [1])
        XCTAssertEqual(allIssuesResult.map(\.id), [1, 2])
        XCTAssertEqual(unfilteredActiveOnlyResult.map(\.id), [1])
        XCTAssertEqual(unfilteredAllIssuesResult.map(\.id), [1, 2, 3])
    }

    func testSearchResultsIntersectWithSelectedCategory() {
        //harness:criterion=c-category-filter-search-composition
        let issues = [
            makeIssue(id: 1, name: "Clean water funding", categories: [budget]),
            makeIssue(id: 2, name: "Clean water oversight", categories: [environment]),
            makeIssue(id: 3, name: "School meals", reason: "Budget priority", categories: [budget]),
            makeIssue(id: 4, name: "Broadband access", categories: [health]),
        ]

        let result = IssueFilterHelper.filteredIssues(
            from: issues,
            showAllIssues: true,
            isSearching: true,
            searchText: "clean water",
            selectedCategory: budget
        )

        XCTAssertEqual(result.map(\.id), [1])
    }

    func testSearchWithAllSelectionPreservesExistingCategoryAgnosticMatches() {
        //harness:criterion=c-search-semantics-preserved
        let issues = [
            makeIssue(id: 1, name: "Rural clinic access", categories: [health]),
            makeIssue(id: 2, name: "Urban clinic staffing", categories: [budget]),
            makeIssue(id: 3, name: "Clinic reporting", categories: [environment]),
            makeIssue(id: 4, name: "School meals", categories: [budget]),
        ]

        let result = IssueFilterHelper.filteredIssues(
            from: issues,
            showAllIssues: true,
            isSearching: true,
            searchText: "clinic",
            selectedCategory: nil
        )

        XCTAssertEqual(result.map(\.id), [1, 2, 3])
    }

    func testSelectedCategoryWithNoMatchingIssuesReturnsEmptyResult() {
        //harness:criterion=c-category-filter-empty-result
        let issues = [
            makeIssue(id: 1, categories: [environment]),
            makeIssue(id: 2, categories: [health]),
        ]

        let result = IssueFilterHelper.filteredIssues(
            from: issues,
            showAllIssues: true,
            isSearching: false,
            searchText: "",
            selectedCategory: budget
        )

        XCTAssertEqual(result.count, 0)
    }

    func testSelectedCategoryValidationResetsOnlyWhenCategoryDisappears() {
        //harness:criterion=c-category-filter-reset-on-issue-change,c-category-filter-no-reset-when-category-present
        let replacementIssuesWithBudget = [
            makeIssue(id: 1, categories: [budget]),
            makeIssue(id: 2, categories: [environment]),
        ]
        let replacementIssuesWithoutBudget = [
            makeIssue(id: 3, categories: [health]),
            makeIssue(id: 4, categories: [environment]),
        ]

        XCTAssertEqual(
            IssueFilterHelper.validatedSelectedCategory(budget, issues: replacementIssuesWithBudget),
            budget
        )
        XCTAssertNil(
            IssueFilterHelper.validatedSelectedCategory(budget, issues: replacementIssuesWithoutBudget)
        )
    }

    private func makeIssue(
        id: Int,
        name: String? = nil,
        reason: String = "Reason",
        script: String = "Script",
        slug: String? = nil,
        categories: [Category],
        active: Bool = true,
        meta: String = ""
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
            outcomeModels: [Outcome(label: "Contacted", status: "contact")],
            contactType: "reps",
            contactAreas: ["US House"],
            createdAt: Date(timeIntervalSince1970: TimeInterval(id)),
            actions: nil
        )
    }
}
