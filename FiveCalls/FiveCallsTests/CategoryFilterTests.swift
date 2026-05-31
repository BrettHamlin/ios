// Copyright 5calls. All rights reserved. See LICENSE for details.

import SwiftUI
import UIKit
import XCTest
@testable import FiveCalls

typealias Category = FiveCalls.Category

final class CategoryFilterTests: XCTestCase {
    private let budget = FiveCalls.Category(name: "Budget")
    private let environment = FiveCalls.Category(name: "Environment")
    private let immigration = FiveCalls.Category(name: "Immigration")
    private let health = FiveCalls.Category(name: "Health")

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

    @MainActor
    func testCategoryFilterBarStartsWithAllSelection() throws {
        //harness:criterion=c-category-filter-bar-all-default,c-category-filter-state-local
        var selectedCategory: FiveCalls.Category? = nil
        let binding = Binding<FiveCalls.Category?>(
            get: { selectedCategory },
            set: { selectedCategory = $0 }
        )

        let bar = CategoryFilterBar(
            issues: [makeIssue(id: 1, categories: [budget])],
            selectedCategory: binding
        )
        let nodes = hostedAccessibilityNodes(for: bar)
        let allNode = try XCTUnwrap(nodes.first { $0.label == "Filter by All" })

        XCTAssertNil(binding.wrappedValue)
        XCTAssertNil(selectedCategory)
        XCTAssertTrue(allNode.traits.contains(.selected))
    }

    @MainActor
    func testDashboardRendersCategoryFilterBetweenSearchAndIssuesList() throws {
        //harness:criterion=c-category-filter-bar-placement
        let state = AppState()
        state.issues = [
            makeIssue(id: 1, name: "Budget issue", categories: [budget]),
        ]
        let store = Store(state: state, middlewares: [])
        let dashboard = Dashboard(selectedIssue: .constant(nil))
            .environmentObject(store)

        let nodes = hostedAccessibilityNodes(for: dashboard, size: CGSize(width: 390, height: 900))
        let labels = nodes.map(\.label)
        let searchIndex = try XCTUnwrap(firstIndex(in: labels, containing: "Search all issues"))
        let filterIndex = try XCTUnwrap(labels.firstIndex(of: "Issue category filter"))
        let issueIndex = try XCTUnwrap(labels.firstIndex { $0.contains("Budget issue") })

        XCTAssertLessThan(searchIndex, filterIndex)
        XCTAssertLessThan(filterIndex, issueIndex)
    }

    @MainActor
    func testCategoryFilterBarHasAtLeastMinimumTouchTargetHeight() throws {
        //harness:criterion=c-category-filter-bar-touch-target
        let bar = CategoryFilterBar(
            issues: [makeIssue(id: 1, categories: [Category(name: "A")])],
            selectedCategory: .constant(nil)
        )
        let nodes = hostedAccessibilityNodes(for: bar)
        let chipNodes = [
            try XCTUnwrap(nodes.first { $0.label == "Filter by All" }),
            try XCTUnwrap(nodes.first { $0.label == "Filter by A" }),
        ]

        for node in chipNodes {
            XCTAssertGreaterThanOrEqual(node.frame.width, 44, node.label)
            XCTAssertGreaterThanOrEqual(node.frame.height, 44, node.label)
        }
    }

    @MainActor
    func testLocalizedCategoryFilterLabelsHaveFallbackDisplayText() {
        //harness:criterion=c-category-filter-all-localized,c-category-filter-bar-accessibility-label,c-category-filter-bar-voiceover-control-label
        let allLabel = localizedAppString(forKey: "Category filter all option")
        let controlLabel = localizedAppString(forKey: "Category filter control accessibility label")
        let chipFormat = localizedAppString(forKey: "Category filter option accessibility label")
        let chipLabel = String(format: chipFormat, budget.name)
        let nodes = hostedAccessibilityNodes(
            for: CategoryFilterBar(
                issues: [makeIssue(id: 1, categories: [budget])],
                selectedCategory: .constant(nil)
            )
        )

        XCTAssertEqual(CategoryFilterOption.all.name, allLabel)
        XCTAssertFalse(allLabel.isEmpty)
        XCTAssertNotEqual(allLabel, "Category filter all option")
        XCTAssertFalse(controlLabel.isEmpty)
        XCTAssertNotEqual(controlLabel, "Category filter control accessibility label")
        XCTAssertFalse(chipLabel.isEmpty)
        XCTAssertNotEqual(chipFormat, "Category filter option accessibility label")
        XCTAssertTrue(chipLabel.contains(budget.name))
        XCTAssertTrue(nodes.contains { $0.label == controlLabel })
        XCTAssertTrue(nodes.contains { $0.label == String(format: chipFormat, allLabel) })
        XCTAssertTrue(nodes.contains { $0.label == chipLabel })
    }

    func testAllSelectionPreservesIssueOrder() {
        //harness:criterion=c-category-filter-all-preserves-order
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

        XCTAssertEqual(result, issues)
        XCTAssertEqual(result.map(\.id), [1, 2, 3])
    }

    @MainActor
    func testIssuesListWithAllSelectionFeedsUnfilteredIssuesAndPreservesSelectionBinding() {
        //harness:criterion=c-existing-navigation-link-preserved
        let issues = [
            makeIssue(id: 1, name: "First", categories: [budget]),
            makeIssue(id: 2, name: "Second", categories: [environment]),
            makeIssue(id: 3, name: "Third", categories: [health]),
        ]
        let state = AppState()
        state.issues = issues
        let store = Store(state: state, middlewares: [])
        var selectedIssue: Issue? = issues[1]
        var showAllIssues = true
        var searchText = ""
        var selectedCategory: FiveCalls.Category? = nil

        let list = IssuesList(
            store: store,
            selectedIssue: Binding(
                get: { selectedIssue },
                set: { selectedIssue = $0 }
            ),
            showAllIssues: Binding(
                get: { showAllIssues },
                set: { showAllIssues = $0 }
            ),
            searchText: Binding(
                get: { searchText },
                set: { searchText = $0 }
            ),
            selectedCategory: Binding(
                get: { selectedCategory },
                set: { selectedCategory = $0 }
            )
        )
        let nodes = hostedAccessibilityNodes(for: list, size: CGSize(width: 390, height: 700))
        let labels = nodes.map(\.label)

        XCTAssertEqual(list.allIssues, issues)
        XCTAssertTrue(labels.contains { $0.contains("First") })
        XCTAssertTrue(labels.contains { $0.contains("Second") })
        XCTAssertTrue(labels.contains { $0.contains("Third") })
        XCTAssertEqual(selectedIssue, issues[1])
        XCTAssertNil(selectedCategory)
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

    func testSearchMatchesReasonScriptSlugAndCategoryWhenAllIsSelected() {
        //harness:criterion=c-search-semantics-preserved
        let issues = [
            makeIssue(id: 1, name: "Name match", categories: [health]),
            makeIssue(id: 2, reason: "Reason contains omnibus", categories: [budget]),
            makeIssue(id: 3, script: "Script says omnibus", categories: [environment]),
            makeIssue(id: 4, slug: "omnibus-slug", categories: [immigration]),
            makeIssue(id: 5, name: "Category match only", categories: [Category(name: "Omnibus")]),
            makeIssue(id: 6, name: "No match", categories: [health]),
        ]

        let result = IssueFilterHelper.filteredIssues(
            from: issues,
            showAllIssues: true,
            isSearching: true,
            searchText: "omnibus",
            selectedCategory: nil
        )

        XCTAssertEqual(Set(result.map(\.id)), Set([2, 3, 4, 5]))
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
        categories: [FiveCalls.Category],
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

    private struct AccessibilityNode {
        let label: String
        let frame: CGRect
        let traits: UIAccessibilityTraits
    }

    @MainActor
    private func hostedAccessibilityNodes<Content: View>(
        for view: Content,
        size: CGSize = CGSize(width: 320, height: 240)
    ) -> [AccessibilityNode] {
        let controller = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.frame = window.bounds
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))

        return accessibilityNodes(in: controller.view)
    }

    private func accessibilityNodes(in view: UIView) -> [AccessibilityNode] {
        var result: [AccessibilityNode] = []

        func appendNode(label: String?, frame: CGRect, traits: UIAccessibilityTraits) {
            guard let label, !label.isEmpty else { return }
            result.append(AccessibilityNode(label: label, frame: frame, traits: traits))
        }

        func walk(_ view: UIView) {
            appendNode(
                label: view.accessibilityLabel ?? (view as? UILabel)?.text ?? (view as? UITextField)?.placeholder,
                frame: view.accessibilityFrame == .zero ? view.convert(view.bounds, to: nil) : view.accessibilityFrame,
                traits: view.accessibilityTraits
            )

            view.accessibilityElements?.forEach { element in
                if let accessibilityElement = element as? UIAccessibilityElement {
                    appendNode(
                        label: accessibilityElement.accessibilityLabel,
                        frame: accessibilityElement.accessibilityFrame,
                        traits: accessibilityElement.accessibilityTraits
                    )
                } else if let elementView = element as? UIView {
                    walk(elementView)
                }
            }

            view.subviews.forEach(walk)
        }

        walk(view)
        return result
    }

    private func firstIndex(in labels: [String], containing text: String) -> Int? {
        labels.firstIndex { $0.localizedCaseInsensitiveContains(text) }
    }

    private func localizedAppString(forKey key: String) -> String {
        Bundle(for: AppDelegate.self).localizedString(forKey: key, value: nil, table: nil)
    }
}
