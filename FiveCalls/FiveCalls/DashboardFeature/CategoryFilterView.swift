// Copyright 5calls. All rights reserved. See LICENSE for details.

import SwiftUI

struct CategoryFilterView: View {
    let issues: [Issue]
    @Binding var selectedCategory: Category?

    private var categories: [Category] {
        IssueListFilter.categories(in: issues)
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryButton(
                    title: String(
                        localized: "All",
                        comment: "Category filter all pill label"
                    ),
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }

                ForEach(categories, id: \.self) { category in
                    categoryButton(
                        title: category.name,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            String(
                localized: "Issue category filter",
                comment: "Category filter accessibility label"
            )
        )
    }

    private func categoryButton(
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? .white : Color.fivecallsDarkBlueText)
                .lineLimit(1)
                .padding(.horizontal, 14)
                .frame(minWidth: 44, minHeight: 44)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.fivecallsDarkBlue : Color(.systemGray6))
                )
                .overlay(
                    Capsule()
                        .stroke(Color.fivecallsDarkBlue.opacity(isSelected ? 0 : 0.25), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
