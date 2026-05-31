// Copyright 5calls. All rights reserved. See LICENSE for details.

import SwiftUI

struct Dashboard: View {
    @EnvironmentObject var store: Store
    @AppStorage("shownNewsletterSignup") var shownNewsletterSignup: Bool = false

    @State var selectedIssueUrl: URL?
    @Binding var selectedIssue: Issue?

    @State var showAllIssues = false
    @State var searchText = ""
    @State var selectedCategory: FiveCalls.Category?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    func usingRegularFonts() -> Bool {
        dynamicTypeSize < DynamicTypeSize.accessibility3
    }

    private var loadedCategoryNames: Set<String> {
        IssueFilterHelper.categoryNames(from: store.state.issues)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            MainHeader()
                .padding(.horizontal, 10)
                .padding(.bottom, 10)

            if !shownNewsletterSignup {
                NewsletterSignup {
                    shownNewsletterSignup = true
                } onSubmit: { email in
                    var district = store.state.district
                    #if !DEBUG
                        var req = URLRequest(url: URL(string: "https://buttondown.com/api/emails/embed-subscribe/5calls")!)
                        req.httpMethod = "POST"
                        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                        var reqBody = "email=\(email)&tag=ios"
                        if let district { reqBody += "&tag=\(district)" }
                        req.httpBody = reqBody.data(using: .utf8)
                        URLSession.shared.dataTask(with: req).resume()
                    #else
                        var subscribeDebug = "DEBUG: would send email sub request to: \(email)"
                        if let district { subscribeDebug += " with district: \(district)" }
                        print(subscribeDebug)
                    #endif

                    shownNewsletterSignup = true
                }
            }

            if usingRegularFonts() {
                Text("What's important to you?", comment: "Dashboard title text")
                    .font(.body)
                    .fontWeight(.bold)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.horizontal, 16)
            }

            SearchBar(searchText: $searchText)

            CategoryFilterBar(issues: store.state.issues, selectedCategory: $selectedCategory)

            IssuesList(
                store: store,
                selectedIssue: $selectedIssue,
                showAllIssues: $showAllIssues,
                searchText: $searchText,
                selectedCategory: $selectedCategory
            )
        }
        .navigationBarHidden(true)
        .onAppear {
            AnalyticsManager.shared.trackPageview(path: "/")

            if let location = store.state.location, store.state.contacts.isEmpty {
                store.dispatch(action: .FetchContacts(location))
            }
        }
        .onOpenURL(perform: { url in
            if store.state.issues.isEmpty {
                selectedIssueUrl = url
            } else {
                selectedIssue = store.state.issues.first(where: { $0.slug == url.lastPathComponent })
            }
        })

        .onChange(of: store.state.issues) {
            if let selectedIssueUrl {
                selectedIssue = store.state.issues.first(where: { $0.slug == selectedIssueUrl.lastPathComponent })
                self.selectedIssueUrl = nil
            }

            validateSelectedCategory()
        }
        .onChange(of: loadedCategoryNames) {
            validateSelectedCategory()
        }
    }

    private func validateSelectedCategory() {
        selectedCategory = IssueFilterHelper.validatedSelectedCategory(
            selectedCategory,
            issues: store.state.issues
        )
    }
}

struct MenuView: View {
    @State var showRemindersSheet = false
    @State var showYourImpact = false
    @State var showAboutSheet = false
    var showingWelcomeScreen: Bool

    var body: some View {
        Menu {
            Button { showRemindersSheet.toggle() } label: {
                Text("Reminders", comment: "Dashboard menu item")
            }
            Button { showYourImpact.toggle() } label: {
                Text("Your Impact", comment: "Dashboard menu item")
            }
            Button { showAboutSheet.toggle() } label: {
                Text("About", comment: "Dashboard menu item")
            }
        } label: {
            Image(systemName: "gear")
                .renderingMode(.template)
                .font(.title)
                .tint(Color.fivecallsDarkBlue)
                .accessibilityLabel(
                    String(
                        localized: "Menu",
                        comment: "Dashboard menu accessibility label"
                    )
                )
        }
        .sheet(isPresented: $showRemindersSheet) {
            ScheduleReminders()
        }
        .sheet(isPresented: $showYourImpact) {
            YourImpact()
        }
        .sheet(isPresented: $showAboutSheet) {
            AboutSheet()
        }
    }
}

struct IssuesList: View {
    @ObservedObject var store: Store
    @Binding var selectedIssue: Issue?
    @Binding var showAllIssues: Bool
    @Binding var searchText: String
    @Binding var selectedCategory: FiveCalls.Category?

    var isSearching: Bool {
        searchText.count >= 3
    }

    var allIssues: [Issue] {
        IssueFilterHelper.filteredIssues(
            from: store.state.issues,
            showAllIssues: showAllIssues,
            isSearching: isSearching,
            searchText: searchText,
            selectedCategory: selectedCategory
        )
    }

    private var categorizedIssues: [CategorizedIssuesViewModel] {
        if isSearching || !showAllIssues {
            // For search results or default view, make fake categories to preserve order and show flat list
            return allIssues.map { CategorizedIssuesViewModel(category: FiveCalls.Category(name: "\($0.id)"), issues: [$0]) }
        }

        var result: [CategorizedIssuesViewModel] = []

        // Separate state-specific issues into their own category with the state name
        let stateIssues = allIssues.filter { $0.isStateSpecific }
        let nonStateIssues = allIssues.filter { !$0.isStateSpecific }

        if !stateIssues.isEmpty {
            let stateName = stateIssues.first?.stateNameFromAbbreviation ?? "State"
            result.append(CategorizedIssuesViewModel(category: FiveCalls.Category(name: stateName), issues: stateIssues))
        }

        // Build regular categories from non-state issues only
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

    var body: some View {
        ScrollViewReader { scroll in
            if isSearching, allIssues.isEmpty {
                VStack {
                    Spacer()
                    Text("No issues found", comment: "IssuesList no results title")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("Try a different search term", comment: "IssuesList no results message")
                        .font(.body)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(categorizedIssues, selection: $selectedIssue) { section in
                    Section {
                        ForEach(section.issues) { issue in
                            NavigationLink(value: issue) {
                                IssueListItem(issue: issue, contacts: store.state.contacts)
                            }
                            .listRowSeparatorTint(.fivecallsDarkGray)
                        }
                    } header: {
                        if showAllIssues, !isSearching {
                            Text(section.name.uppercased()).font(.headline)
                                .foregroundStyle(.fivecallsDarkGray)
                        }
                    } footer: {
                        if section == categorizedIssues.last, !isSearching {
                            Button {
                                showAllIssues.toggle()
                                if let issueID = categorizedIssues.first?.issues.first?.id {
                                    scroll.scrollTo(issueID, anchor: .top)
                                }
                            } label: {
                                Text(showAllIssues ?
                                    String(localized: "Fewer Issues", comment: "Issues List button text")
                                    : String(localized: "More Issues", comment: "Issues List button text")
                                )
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.fivecallsDarkBlueText)
                            }
                            .padding(.vertical, 10)
                            .listRowSeparatorTint(.fivecallsDarkGray)
                        }
                    }
                }
                .tint(Color.fivecallsLightBG)
                .listStyle(.plain)
            }
        }
    }
}

#Preview {
    let previewState = {
        let state = AppState()
        state.issues = [
            Issue.basicPreviewIssue,
            Issue.multilinePreviewIssue,
        ]
        state.contacts = [
            Contact.housePreviewContact,
            Contact.senatePreviewContact1,
            Contact.senatePreviewContact2,
        ]
        return state
    }()

    let store = Store(state: previewState, middlewares: [appMiddleware()])

    NavigationStack {
        Dashboard(selectedIssue: .constant(.none)).environmentObject(store)
    }
}
