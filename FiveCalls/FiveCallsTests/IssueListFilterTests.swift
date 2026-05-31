// Copyright 5calls. All rights reserved. See LICENSE for details.

import Foundation
import SwiftUI
import XCTest
@testable import FiveCalls

final class IssueListFilterTests: XCTestCase {
    private typealias IssueCategory = FiveCalls.Category

    private let environment = IssueCategory(name: "Environment")
    private let health = IssueCategory(name: "Health")
    private let democracy = IssueCategory(name: "Democracy")

    func testCategoryFilterViewShowsAllFirstAndDerivesDistinctCategoriesFromIssues() {
        //harness:criterion=c-category-filter-shows-all-pill,c-category-filter-pills-derived-from-issues,c-all-pill-default-selected
        let issues = [
            issue(id: 1, name: "Climate Action", categories: [environment, democracy]),
            issue(id: 2, name: "Health Funding", categories: [health]),
            issue(id: 3, name: "Clean Water", categories: [environment]),
        ]
        let inspection = inspectCategoryFilter(issues: issues)

        XCTAssertEqual(inspection.visibleTextStrings.first, "All")
        XCTAssertEqual(inspection.visibleTextStrings.filter { $0 == "All" }.count, 1)
        XCTAssertEqual(inspection.forEachCategories.map(\.name), ["Democracy", "Environment", "Health"])
        XCTAssertTrue(
            inspection.accessibilityTraitRawValues.contains(4),
            "The initially selected All pill should expose SwiftUI's selected accessibility trait."
        )
    }

    func testCategoryFilterViewAppliesAccessibleScalablePillStyling() {
        //harness:criterion=c-category-filter-tap-target,c-category-filter-voiceover-label,c-category-filter-dynamic-type
        let inspection = inspectCategoryFilter(
            issues: [issue(id: 1, name: "Climate Action", categories: [environment])]
        )
        let allPill = inspection.visibleTexts.first { $0.string == "All" }

        XCTAssertTrue(inspection.accessibilityLabels.contains("Issue category filter"))
        XCTAssertTrue(
            inspection.frameMinimums.contains { $0.width >= 44 && $0.height >= 44 },
            "The All pill should declare a minimum 44x44 tap target."
        )
        XCTAssertEqual(allPill?.usesDynamicTextStyle, true)
    }

    func testCategoryFilterViewCanBeInstantiatedWithLoadedIssues() {
        //harness:criterion=c-category-filter-view-exists
        var selectedCategory: IssueCategory?
        let view = CategoryFilterView(
            issues: [
                issue(id: 1, name: "Climate Action", categories: [environment]),
                issue(id: 2, name: "Health Funding", categories: [health]),
            ],
            selectedCategory: Binding(get: { selectedCategory }, set: { selectedCategory = $0 })
        )
        let bodyTypeDescription = String(describing: type(of: view.body))

        XCTAssertNil(selectedCategory)
        XCTAssertFalse(bodyTypeDescription.isEmpty)
    }

    func testSelectingAllPillResetsBindingToNilAndRestoresUnfilteredActiveIssues() throws {
        //harness:criterion=c-selecting-all-pill-resets-to-nil
        let activeEnvironment = issue(id: 1, name: "Climate Action", categories: [environment], active: true)
        let activeHealth = issue(id: 2, name: "Health Funding", categories: [health], active: true)
        let inactiveEnvironment = issue(id: 3, name: "Inactive Climate", categories: [environment], active: false)
        let issues = [activeEnvironment, activeHealth, inactiveEnvironment]
        var selectedCategory: IssueCategory? = environment
        let view = CategoryFilterView(
            issues: issues,
            selectedCategory: Binding(
                get: { selectedCategory },
                set: { selectedCategory = $0 }
            )
        )
        let inspection = CategoryFilterInspection(view.body)
        let allButton = try XCTUnwrap(inspection.buttons.first { $0.title == "All" })

        allButton.action()

        XCTAssertNil(selectedCategory)
        XCTAssertEqual(
            IssueListFilter.filter(
                issues: issues,
                showAllIssues: false,
                searchText: "",
                selectedCategory: selectedCategory
            ),
            [activeEnvironment, activeHealth]
        )
    }

    func testDashboardDefaultsSelectedCategoryToAll() {
        //harness:criterion=c-dashboard-selected-category-state,c-all-pill-default-selected
        let dashboard = Dashboard(selectedIssue: .constant(nil))

        XCTAssertNil(dashboard.selectedCategory)
    }

    func testIssuesListUsesSelectedCategoryBindingForAllIssues() {
        //harness:criterion=c-category-filter-binding-passed-to-issues-list,c-issues-list-delegates-to-filter-helper
        let environmentIssue = issue(id: 1, name: "Climate Action", categories: [environment], active: true)
        let healthIssue = issue(id: 2, name: "Health Funding", categories: [health], active: true)
        let inactiveEnvironmentIssue = issue(id: 3, name: "Inactive Climate", categories: [environment], active: false)
        let state = AppState()
        state.issues = [environmentIssue, healthIssue, inactiveEnvironmentIssue]
        let store = Store(state: state)
        var selectedIssue: Issue?
        var showAllIssues = false
        var searchText = ""
        var selectedCategory: IssueCategory? = environment
        let list = IssuesList(
            store: store,
            selectedIssue: Binding(get: { selectedIssue }, set: { selectedIssue = $0 }),
            showAllIssues: Binding(get: { showAllIssues }, set: { showAllIssues = $0 }),
            searchText: Binding(get: { searchText }, set: { searchText = $0 }),
            selectedCategory: Binding(get: { selectedCategory }, set: { selectedCategory = $0 })
        )

        XCTAssertEqual(list.allIssues, [environmentIssue])

        selectedCategory = nil

        XCTAssertEqual(list.allIssues, [environmentIssue, healthIssue])
    }

    func testNilCategoryPreservesActiveScopeAndStateSpecificOrdering() {
        //harness:criterion=c-filter-nil-category-preserves-order,c-existing-show-all-issues-behavior-preserved
        let olderStateIssue = issue(id: 1, name: "Older State", categories: [environment], meta: "CA", createdAt: 100)
        let newerStateIssue = issue(id: 2, name: "Newer State", categories: [health], meta: "CA", createdAt: 200)
        let federalIssue = issue(id: 3, name: "Federal", categories: [democracy])
        let inactiveIssue = issue(id: 4, name: "Inactive", categories: [environment], active: false)
        let issues = [federalIssue, olderStateIssue, inactiveIssue, newerStateIssue]

        let defaultResult = IssueListFilter.filter(
            issues: issues,
            showAllIssues: false,
            searchText: "",
            selectedCategory: nil
        )
        let allResult = IssueListFilter.filter(
            issues: issues,
            showAllIssues: true,
            searchText: "",
            selectedCategory: nil
        )

        XCTAssertEqual(defaultResult.map(\.id), [2, 1, 3])
        XCTAssertEqual(allResult.map(\.id), [2, 1, 3, 4])
    }

    func testCategoryFilterReturnsOnlyMatchingIssues() {
        //harness:criterion=c-filter-single-category-returns-matching-only,c-filter-excludes-non-matching-category
        let matching = issue(id: 1, name: "Climate Action", categories: [environment])
        let alsoMatching = issue(id: 2, name: "Clean Water", categories: [health, environment])
        let other = issue(id: 3, name: "Health Funding", categories: [health])

        let result = IssueListFilter.filter(
            issues: [matching, alsoMatching, other],
            showAllIssues: true,
            searchText: "",
            selectedCategory: environment
        )

        XCTAssertEqual(result.map(\.id), [matching.id, alsoMatching.id])
        XCTAssertTrue(result.allSatisfy { $0.categories.contains(self.environment) })
        XCTAssertFalse(result.contains(other))
    }

    func testInactiveIssuesRespectShowAllScope() {
        //harness:criterion=c-filter-inactive-excluded-default-mode,c-filter-inactive-included-show-all,c-more-fewer-toggle-composes-with-category
        let active = issue(id: 1, name: "Active Climate", categories: [environment], active: true)
        let inactive = issue(id: 2, name: "Inactive Climate", categories: [environment], active: false)
        let otherCategory = issue(id: 3, name: "Active Health", categories: [health], active: true)

        let defaultResult = IssueListFilter.filter(
            issues: [active, inactive, otherCategory],
            showAllIssues: false,
            searchText: "",
            selectedCategory: environment
        )
        let allResult = IssueListFilter.filter(
            issues: [active, inactive, otherCategory],
            showAllIssues: true,
            searchText: "",
            selectedCategory: environment
        )

        XCTAssertEqual(defaultResult, [active])
        XCTAssertEqual(allResult, [active, inactive])
    }

    func testSearchAndCategoryCompose() {
        //harness:criterion=c-filter-search-then-category,c-search-composes-with-category
        let climateEnvironment = issue(id: 1, name: "Climate Action", categories: [environment])
        let climateHealth = issue(id: 2, name: "Climate Health", categories: [health])
        let votingEnvironment = issue(id: 3, name: "Voting Rights", categories: [environment])
        let inactiveClimateEnvironment = issue(id: 4, name: "Climate Inactive", categories: [environment], active: false)

        let defaultResult = IssueListFilter.filter(
            issues: [climateEnvironment, climateHealth, votingEnvironment, inactiveClimateEnvironment],
            showAllIssues: false,
            searchText: "Clim",
            selectedCategory: environment
        )
        let allResult = IssueListFilter.filter(
            issues: [climateEnvironment, climateHealth, votingEnvironment, inactiveClimateEnvironment],
            showAllIssues: true,
            searchText: "Clim",
            selectedCategory: environment
        )

        XCTAssertEqual(defaultResult, [climateEnvironment])
        XCTAssertEqual(allResult, [climateEnvironment, inactiveClimateEnvironment])
    }

    func testSearchBelowThresholdIgnoresTextBeforeApplyingCategory() {
        //harness:criterion=c-filter-search-below-threshold-ignores-text
        let startsWithAb = issue(id: 1, name: "Abc Climate", categories: [environment])
        let noSearchMatch = issue(id: 2, name: "Clean Water", categories: [environment])
        let wrongCategory = issue(id: 3, name: "Ab Health", categories: [health])
        let issues = [startsWithAb, noSearchMatch, wrongCategory]

        let shortSearch = IssueListFilter.filter(
            issues: issues,
            showAllIssues: true,
            searchText: "Ab",
            selectedCategory: environment
        )
        let emptySearch = IssueListFilter.filter(
            issues: issues,
            showAllIssues: true,
            searchText: "",
            selectedCategory: environment
        )

        XCTAssertEqual(shortSearch, emptySearch)
        XCTAssertEqual(shortSearch.map(\.id), [startsWithAb.id, noSearchMatch.id])
    }

    func testNilCategorySearchMatchesExistingFieldsWithoutCategoryNarrowing() {
        //harness:criterion=c-existing-search-behavior-preserved
        let nameMatch = issue(id: 1, name: "Climate Action", categories: [environment])
        let reasonMatch = issue(id: 2, name: "Health Funding", categories: [health], reason: "Climate resilience grants")
        let scriptMatch = issue(id: 3, name: "Voting Rights", categories: [democracy], script: "Ask for climate safeguards")
        let noMatch = issue(id: 4, name: "Broadband Access", categories: [democracy])

        let result = IssueListFilter.filter(
            issues: [nameMatch, reasonMatch, scriptMatch, noMatch],
            showAllIssues: true,
            searchText: "Clim",
            selectedCategory: nil
        )

        XCTAssertEqual(result.map(\.id), [nameMatch.id, reasonMatch.id, scriptMatch.id])
    }

    func testNilCategorySearchMatchesSlugAndCategoryFieldsWithoutCategoryNarrowing() {
        //harness:criterion=c-existing-search-behavior-preserved
        let slugMatch = issue(id: 1, name: "Broadband Access", categories: [health], slug: "climate-broadband")
        let categoryMatch = issue(id: 2, name: "Clean Water", categories: [environment])
        let noMatch = issue(id: 3, name: "Voting Rights", categories: [democracy])

        let result = IssueListFilter.filter(
            issues: [slugMatch, categoryMatch, noMatch],
            showAllIssues: true,
            searchText: "Clim",
            selectedCategory: nil
        )

        XCTAssertEqual(result, [slugMatch, categoryMatch])
    }

    func testResetCategoryIfNeededPreservesStillPresentCategory() {
        //harness:criterion=c-safe-reset-does-not-trigger-on-valid-category
        let selected = IssueListFilter.resetCategoryIfNeeded(
            issues: [issue(id: 1, name: "Climate Action", categories: [environment])],
            selectedCategory: environment
        )

        XCTAssertEqual(selected, environment)
    }

    func testResetCategoryIfNeededClearsMissingCategory() {
        //harness:criterion=c-safe-reset-when-category-disappears
        let reset = IssueListFilter.resetCategoryIfNeeded(
            issues: [issue(id: 2, name: "Health Funding", categories: [health])],
            selectedCategory: environment
        )

        XCTAssertNil(reset)
    }

    func testCategorySourceIssuesPreservesActiveScopeUsedByFilterControl() {
        //harness:criterion=c-more-fewer-toggle-composes-with-category,c-existing-show-all-issues-behavior-preserved
        let activeEnvironment = issue(id: 1, name: "Active Climate", categories: [environment], active: true)
        let inactiveEnvironment = issue(id: 2, name: "Inactive Climate", categories: [environment], active: false)
        let issues = [activeEnvironment, inactiveEnvironment]

        XCTAssertEqual(
            IssueListFilter.categorySourceIssues(issues: issues, showAllIssues: false),
            [activeEnvironment]
        )
        XCTAssertEqual(
            IssueListFilter.categorySourceIssues(issues: issues, showAllIssues: true),
            [activeEnvironment, inactiveEnvironment]
        )
    }

    func testGroupingUsesExistingCategoryViewModelForNilAndSelectedCategory() {
        //harness:criterion=c-grouping-unchanged-nil-category,c-grouping-unchanged-with-category
        let environmentOnly = issue(id: 1, name: "Climate Action", categories: [environment])
        let shared = issue(id: 2, name: "Clean Clinics", categories: [environment, health])
        let healthOnly = issue(id: 3, name: "Health Funding", categories: [health])
        let issues = [environmentOnly, shared, healthOnly]

        let unfiltered = IssueListFilter.filter(
            issues: issues,
            showAllIssues: true,
            searchText: "",
            selectedCategory: nil
        )
        let environmentFiltered = IssueListFilter.filter(
            issues: issues,
            showAllIssues: true,
            searchText: "",
            selectedCategory: environment
        )

        XCTAssertEqual(groupSummary(for: unfiltered), [
            "Environment": [environmentOnly.id, shared.id],
            "Health": [shared.id, healthOnly.id],
        ])
        XCTAssertEqual(groupSummary(for: environmentFiltered), [
            "Environment": [environmentOnly.id, shared.id],
            "Health": [shared.id],
        ])
    }

    func testLocalizableStringsContainCategoryFilterEntries() throws {
        //harness:criterion=c-localizable-all-pill-string,c-localizable-filter-accessibility-label
        let strings = try localizableStrings()

        XCTAssertEqual(localizedValue(for: "All", in: strings), "All")
        XCTAssertEqual(localizedValue(for: "Issue category filter", in: strings), "Issue category filter")
    }

    private func issue(
        id: Int,
        name: String,
        categories: [IssueCategory],
        active: Bool = true,
        meta: String = "",
        reason: String? = nil,
        script: String? = nil,
        slug: String? = nil,
        createdAt: TimeInterval? = nil
    ) -> Issue {
        Issue(
            id: id,
            meta: meta,
            name: name,
            slug: slug ?? "issue-\(id)",
            reason: reason ?? "Reason for \(name)",
            script: script ?? "Script for \(name)",
            categories: categories,
            active: active,
            outcomeModels: [],
            contactType: "reps",
            contactAreas: ["US House"],
            createdAt: Date(timeIntervalSince1970: createdAt ?? TimeInterval(id)),
            actions: nil
        )
    }

    private func groupSummary(for issues: [Issue]) -> [String: [Int]] {
        let viewModel = AllIssuesViewModel(issues: issues)

        return Dictionary(
            uniqueKeysWithValues: viewModel.categorizedIssues.map { categoryViewModel in
                (categoryViewModel.name, categoryViewModel.issues.map(\.id))
            }
        )
    }

    private func localizableStrings() throws -> [String: Any] {
        let testFileURL = URL(fileURLWithPath: #filePath)
        let resourceURL = testFileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("FiveCalls/Resources/Localizable.xcstrings")
        let data = try Data(contentsOf: resourceURL)
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        return try XCTUnwrap(root["strings"] as? [String: Any])
    }

    private func localizedValue(for key: String, in strings: [String: Any]) -> String? {
        guard
            let entry = strings[key] as? [String: Any],
            let localizations = entry["localizations"] as? [String: Any],
            let english = localizations["en"] as? [String: Any],
            let stringUnit = english["stringUnit"] as? [String: Any]
        else {
            return nil
        }

        return stringUnit["value"] as? String
    }

    private func inspectCategoryFilter(
        issues: [Issue],
        selectedCategory initialSelectedCategory: IssueCategory? = nil
    ) -> CategoryFilterInspection {
        var selectedCategory = initialSelectedCategory
        let view = CategoryFilterView(
            issues: issues,
            selectedCategory: Binding(
                get: { selectedCategory },
                set: { selectedCategory = $0 }
            )
        )

        return CategoryFilterInspection(view.body)
    }

    private struct CategoryFilterInspection {
        private(set) var visibleTexts: [TextInspection] = []
        private(set) var accessibilityLabels: [String] = []
        private(set) var forEachCategories: [IssueCategory] = []
        private(set) var frameMinimums: [(width: Double, height: Double)] = []
        private(set) var accessibilityTraitRawValues: [UInt64] = []
        private(set) var buttons: [ButtonInspection] = []

        var visibleTextStrings: [String] {
            visibleTexts.map(\.string)
        }

        init(_ body: some View) {
            inspect(body)
        }

        private mutating func inspect(_ value: Any) {
            if let text = value as? Text {
                let textInspection = inspectText(text)
                if let string = textInspection.string {
                    if textInspection.hasVisibleModifiers {
                        visibleTexts.append(
                            TextInspection(
                                string: string,
                                usesDynamicTextStyle: textInspection.usesDynamicTextStyle
                            )
                        )
                    } else {
                        accessibilityLabels.append(string)
                    }
                }
                return
            }

            let typeName = String(reflecting: type(of: value))
            if typeName.hasPrefix("SwiftUI.Button"),
               let title = firstVerbatimString(in: value),
               let action = firstAction(in: value) {
                buttons.append(ButtonInspection(title: title, action: action))
            }

            if typeName.contains("_FlexFrameLayout"),
               let minimums = frameMinimums(from: value) {
                frameMinimums.append(minimums)
            }

            if typeName.contains("AccessibilityTraitSet"),
               let rawValue = rawAccessibilityTraitValue(from: value) {
                accessibilityTraitRawValues.append(rawValue)
            }

            if let categories = value as? [IssueCategory] {
                forEachCategories = categories
            }

            guard shouldRecurse(into: value) else {
                return
            }

            for child in Mirror(reflecting: value).children {
                inspect(child.value)
            }
        }

        private func inspectText(_ text: Text) -> (
            string: String?,
            hasVisibleModifiers: Bool,
            usesDynamicTextStyle: Bool
        ) {
            let mirror = Mirror(reflecting: text)
            let string = firstVerbatimString(in: text)
            let modifierCount = mirror.children.first { $0.label == "modifiers" }
                .map { Mirror(reflecting: $0.value).children.count } ?? 0

            return (
                string,
                modifierCount > 0,
                containsTypeName("TextStyleProvider", in: text)
            )
        }

        private func firstVerbatimString(in value: Any) -> String? {
            for child in Mirror(reflecting: value).children {
                if child.label == "verbatim", let string = child.value as? String {
                    return string
                }

                if let string = firstVerbatimString(in: child.value) {
                    return string
                }
            }

            return nil
        }

        private func firstAction(in value: Any) -> (() -> Void)? {
            if let action = value as? () -> Void {
                return action
            }

            guard shouldRecurse(into: value) else {
                return nil
            }

            for child in Mirror(reflecting: value).children {
                if let action = firstAction(in: child.value) {
                    return action
                }
            }

            return nil
        }

        private func containsTypeName(_ needle: String, in value: Any) -> Bool {
            if String(reflecting: type(of: value)).contains(needle) {
                return true
            }

            guard shouldRecurse(into: value) else {
                return false
            }

            return Mirror(reflecting: value).children.contains { child in
                containsTypeName(needle, in: child.value)
            }
        }

        private func frameMinimums(from value: Any) -> (width: Double, height: Double)? {
            var width: Double?
            var height: Double?

            for child in Mirror(reflecting: value).children {
                switch child.label {
                case "minWidth":
                    width = optionalDouble(child.value)
                case "minHeight":
                    height = optionalDouble(child.value)
                default:
                    continue
                }
            }

            guard let width, let height else {
                return nil
            }

            return (width, height)
        }

        private func rawAccessibilityTraitValue(from value: Any) -> UInt64? {
            for child in Mirror(reflecting: value).children {
                if child.label == "rawValue" {
                    if let rawValue = child.value as? UInt64 {
                        return rawValue
                    }
                    if let rawValue = child.value as? Int {
                        return UInt64(rawValue)
                    }
                }

                if let rawValue = rawAccessibilityTraitValue(from: child.value) {
                    return rawValue
                }
            }

            return nil
        }

        private func optionalDouble(_ value: Any) -> Double? {
            let mirror = Mirror(reflecting: value)
            guard mirror.displayStyle == .optional,
                  let unwrapped = mirror.children.first?.value
            else {
                return nil
            }

            if let cgFloat = unwrapped as? CGFloat {
                return Double(cgFloat)
            }
            if let double = unwrapped as? Double {
                return double
            }

            return nil
        }

        private func shouldRecurse(into value: Any) -> Bool {
            switch value {
            case is String, is Int, is Bool, is Double, is CGFloat, is UInt64:
                return false
            default:
                return true
            }
        }
    }

    private struct TextInspection {
        let string: String
        let usesDynamicTextStyle: Bool
    }

    private struct ButtonInspection {
        let title: String
        let action: () -> Void
    }
}
