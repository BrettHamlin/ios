// Copyright 5calls. All rights reserved. See LICENSE for details.

import SwiftUI

struct CategoryFilterBar: View {
    let issues: [Issue]
    @Binding var selectedCategory: FiveCalls.Category?

    private var options: [CategoryFilterOption] {
        IssueFilterHelper.categoryOptions(from: issues)
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(options) { option in
                    Button {
                        selectedCategory = option.category
                    } label: {
                        Text(option.name)
                            .font(.subheadline)
                            .fontWeight(isSelected(option) ? .semibold : .regular)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .foregroundColor(isSelected(option) ? .white : Color.fivecallsDarkBlueText)
                            .padding(.horizontal, 14)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .buttonStyle(.plain)
                    .background(isSelected(option) ? Color.fivecallsDarkBlue : Color(.systemGray6))
                    .clipShape(Capsule())
                    .accessibilityLabel(accessibilityLabel(for: option))
                    .accessibilityAddTraits(isSelected(option) ? .isSelected : [])
                }
            }
            .padding(.horizontal, 16)
        }
        .accessibilityLabel(
            String(
                localized: "Category filter control accessibility label",
                defaultValue: "Issue category filter",
                comment: "CategoryFilterBar control accessibility label"
            )
        )
        .padding(.bottom, 8)
    }

    private func isSelected(_ option: CategoryFilterOption) -> Bool {
        selectedCategory?.name == option.category?.name
    }

    private func accessibilityLabel(for option: CategoryFilterOption) -> String {
        String(
            format: String(
                localized: "Category filter option accessibility label",
                defaultValue: "Filter by %@",
                comment: "CategoryFilterBar chip accessibility label"
            ),
            option.name
        )
    }
}

#Preview {
    CategoryFilterBar(
        issues: [
            Issue.basicPreviewIssue,
            Issue.multilinePreviewIssue,
            Issue.stateSpecificPreviewIssue,
        ],
        selectedCategory: .constant(nil)
    )
}
