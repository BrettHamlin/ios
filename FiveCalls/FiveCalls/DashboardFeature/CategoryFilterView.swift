// Copyright 5calls. All rights reserved. See LICENSE for details.

import SwiftUI

struct CategoryFilterOption: Identifiable, Equatable {
    let category: Category?
    let label: String
    let isSelected: Bool
    let accessibilityLabel: String
    let accessibilityIdentifier: String

    var id: String {
        accessibilityIdentifier
    }

    static func options(categories: [Category], selectedCategory: Category?) -> [CategoryFilterOption] {
        let allOption = CategoryFilterOption(
            category: nil,
            label: String(localized: "All", comment: "Dashboard category filter chip for all categories"),
            isSelected: selectedCategory == nil,
            accessibilityLabel: String(
                localized: "Show all issue categories",
                comment: "Dashboard all category chip accessibility label"
            ),
            accessibilityIdentifier: "category-filter-all"
        )

        return [allOption] + categories.map { category in
            CategoryFilterOption(
                category: category,
                label: category.name,
                isSelected: selectedCategory == category,
                accessibilityLabel: String(
                    format: String(
                        localized: "Show %@ issues",
                        comment: "Dashboard category chip accessibility label"
                    ),
                    category.name
                ),
                accessibilityIdentifier: accessibilityIdentifier(for: category)
            )
        }
    }

    static func select(_ option: CategoryFilterOption, selectedCategory: inout Category?) {
        selectedCategory = option.category
    }

    private static func accessibilityIdentifier(for category: Category) -> String {
        let safeName = category.name
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
        return "category-filter-\(safeName)"
    }
}

struct CategoryFilterView: View {
    let categories: [Category]
    @Binding var selectedCategory: Category?

    static var allChipLabel: String {
        String(localized: "All", comment: "Dashboard category filter chip for all categories")
    }

    var options: [CategoryFilterOption] {
        CategoryFilterOption.options(categories: categories, selectedCategory: selectedCategory)
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(options) { option in
                    chip(
                        label: option.label,
                        isSelected: option.isSelected,
                        accessibilityLabel: option.accessibilityLabel,
                        accessibilityIdentifier: option.accessibilityIdentifier
                    ) {
                        CategoryFilterOption.select(option, selectedCategory: &selectedCategory)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
        .padding(.bottom, 6)
    }

    private func chip(
        label: String,
        isSelected: Bool,
        accessibilityLabel: String,
        accessibilityIdentifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .padding(.horizontal, 14)
                .frame(minHeight: 44)
                .foregroundColor(isSelected ? .white : Color.fivecallsDarkBlueText)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.fivecallsDarkBlue : Color(.systemGray6))
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.fivecallsDarkBlue : Color.fivecallsLightGray, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier(accessibilityIdentifier)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    CategoryFilterView(
        categories: [
            Category(name: "Civil Rights"),
            Category(name: "Environment"),
            Category(name: "Healthcare"),
        ],
        selectedCategory: .constant(Category(name: "Environment"))
    )
}
