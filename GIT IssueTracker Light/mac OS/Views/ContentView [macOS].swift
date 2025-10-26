//
//  ContentView[macOS].swift
//  GIT IssueTracker Light
//
//  Main interface with Wiki integration
//

import SwiftUI

struct ContentView: View {
    @State private var configManager = ConfigManager()
    @State private var gitHubService: GitHubService?
    @State private var wikiService: WikiService?
    
    @State private var repositories: [Repository] = []
    @State private var allIssues: [Issue] = []
    @State private var selectedRepository: Repository?
    @State private var selectedIssue: Issue?
    
    @State private var selectedTab: NavigationTab = .repos
    @State private var navigationStack: [NavigationState] = []
    @State private var showingSettings = false
    @State private var showingCreateIssue = false
    @State private var isLoadingRepos = false
    @State private var isLoadingIssues = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationSplitView {
            // Left sidebar
            VStack(spacing: 0) {
                // Segmented control for tabs
                Picker("", selection: $selectedTab) {
                    Text("Repos").tag(NavigationTab.repos)
                    Text("Issues").tag(NavigationTab.issues)
                    Text("Wiki").tag(NavigationTab.wiki)
                }
                .pickerStyle(.segmented)
                .padding()
                
                Divider()
                
                // Content based on selected tab
                switch selectedTab {
                case .repos:
                    repositoryListView
                case .issues:
                    allIssuesListView
                case .wiki:
                    WikiView(repositories: repositories)
                        .onAppear {
                            if wikiService == nil {
                                wikiService = WikiService(configManager: configManager)
                            }
                        }
                }
            }
            .frame(minWidth: 250)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gear")
                    }
                }
            }
        } detail: {
            // Right main area
            if let navigationState = navigationStack.last {
                switch navigationState {
                case .repositoryDetail(let repo):
                    repositoryDetailView(repo: repo)
                case .issueDetail(let issue):
                    issueDetailView(issue: issue)
                }
            } else {
                ContentUnavailableView(
                    "Select a Repository",
                    systemImage: "doc.text",
                    description: Text("Choose a repository from the list to view its details")
                )
            }
        }
        .sheet(isPresented: $showingSettings) {
            PathSettingsView(configManager: configManager)
        }
        .sheet(isPresented: $showingCreateIssue) {
            if let repo = selectedRepository {
                CreateIssueSheet(repository: repo, gitHubService: gitHubService) {
                    Task {
                        await loadAllIssues()
                    }
                }
            }
        }
        .task {
            if gitHubService == nil {
                gitHubService = GitHubService(configManager: configManager)
            }
            if wikiService == nil {
                wikiService = WikiService(configManager: configManager)
            }
            await loadRepositories()
        }
    }
    
    // MARK: - Repository List View
    
    private var repositoryListView: some View {
        ScrollView {
            if isLoadingRepos {
                ProgressView("Loading repositories...")
                    .padding()
            } else if repositories.isEmpty {
                ContentUnavailableView(
                    "No Repositories",
                    systemImage: "folder",
                    description: Text("No repositories found for this account")
                )
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(repositories) { repo in
                        RepositoryRow(repository: repo)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectRepository(repo)
                            }
                    }
                }
                .padding(.horizontal, 8)
            }
        }
    }
    
    // MARK: - All Issues List View
    
    private var allIssuesListView: some View {
        ScrollView {
            if isLoadingIssues {
                ProgressView("Loading issues...")
                    .padding()
            } else if allIssues.isEmpty {
                ContentUnavailableView(
                    "No Issues",
                    systemImage: "checkmark.circle",
                    description: Text("No issues found across your repositories")
                )
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(allIssues) { issue in
                        IssueRow(issue: issue)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectIssue(issue)
                            }
                    }
                }
                .padding(.horizontal, 8)
            }
        }
        .task {
            await loadAllIssues()
        }
    }
    
    // MARK: - Repository Detail View
    
    private func repositoryDetailView(repo: Repository) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Back button
            if navigationStack.count > 1 {
                Button(action: navigateBack) {
                    Label("Back", systemImage: "chevron.left")
                }
                .buttonStyle(.plain)
            }
            
            // Repository info
            VStack(alignment: .leading, spacing: 8) {
                Text(repo.name)
                    .font(.largeTitle)
                    .bold()
                
                if let description = repo.description {
                    Text(description)
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 16) {
                    if let language = repo.language {
                        Label(language, systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                    Label("\(repo.stargazersCount)", systemImage: "star")
                    Label("\(repo.forksCount)", systemImage: "tuningfork")
                    if let openCount = repo.openIssuesCount {
                        Label("\(openCount)", systemImage: "exclamationmark.circle")
                            .foregroundStyle(openCount > 0 ? .red : .secondary)
                            .onTapGesture {
                                // Navigate to issues for this repo
                                if let firstIssue = allIssues.first(where: { $0.repositoryName == repo.name && $0.isOpen }) {
                                    selectIssue(firstIssue)
                                }
                            }
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Divider()
            
            // Open issues for this repository
            Text("Open Issues")
                .font(.headline)
            
            let repoIssues = allIssues.filter { $0.repositoryName == repo.name && $0.isOpen }
                                      .sorted(by: { $0.number < $1.number })
            
            if !repoIssues.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(repoIssues) { issue in
                            IssueRow(issue: issue)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectIssue(issue)
                                }
                        }
                    }
                }
            } else {
                ContentUnavailableView(
                    "No Open Issues",
                    systemImage: "checkmark.circle",
                    description: Text("This repository has no open issues")
                )
            }
            
            Spacer()
            
            // Action buttons
            HStack {
                Button("Open on GitHub") {
                    if let url = URL(string: repo.htmlUrl) {
                        NSWorkspace.shared.open(url)
                    }
                }
                
                Button("Copy Clone URL") {
                    let cloneURL = "https://github.com/\(repo.fullName).git"
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(cloneURL, forType: .string)
                }
                
                Button("Create New Issue") {
                    showingCreateIssue = true
                }
            }
            .padding()
        }
        .padding()
    }
    
    // MARK: - Issue Detail View
    
    private func issueDetailView(issue: Issue) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Back button
                Button(action: navigateBack) {
                    Label("Back", systemImage: "chevron.left")
                }
                .buttonStyle(.plain)
                
                // Issue header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("#\(issue.number)")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        
                        Text(issue.state.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(issue.isOpen ? Color.green : Color.red)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                    
                    Text(issue.title)
                        .font(.largeTitle)
                        .bold()
                    
                    if let body = issue.body, !body.isEmpty {
                        Text(body)
                            .padding(.top, 8)
                    }
                }
                
                Divider()
                
                // Comments from GitHub
                if let repo = repositories.first(where: { $0.name == issue.repositoryName }) {
                    CommentsView(
                        issue: issue,
                        repository: repo,
                        gitHubService: gitHubService
                    )
                    .id(issue.id)
                }
                
                Spacer()
                
                // Action buttons
                HStack {
                    if issue.isOpen {
                        Button("Close Issue") {
                            Task {
                                await closeIssue(issue)
                            }
                        }
                    } else {
                        Button("Reopen Issue") {
                            Task {
                                await reopenIssue(issue)
                            }
                        }
                    }
                }
                .padding()
            }
            .padding()
        }
    }
    
    // MARK: - Navigation Functions
    
    private func selectRepository(_ repo: Repository) {
        navigationStack.append(.repositoryDetail(repo))
        selectedRepository = repo
    }
    
    private func selectIssue(_ issue: Issue) {
        navigationStack.append(.issueDetail(issue))
        selectedIssue = issue
        
        // Auto-switch to Issues tab when viewing an issue
        if selectedTab != .issues {
            selectedTab = .issues
        }
    }
    
    private func navigateBack() {
        if !navigationStack.isEmpty {
            navigationStack.removeLast()
        }
        
        if let last = navigationStack.last {
            switch last {
            case .repositoryDetail(let repo):
                selectedRepository = repo
                selectedIssue = nil
            case .issueDetail(let issue):
                selectedIssue = issue
            }
        } else {
            selectedRepository = nil
            selectedIssue = nil
        }
    }
    
    // MARK: - Data Loading
    
    private func loadRepositories() async {
        isLoadingRepos = true
        defer { isLoadingRepos = false }
        
        guard let service = gitHubService else { return }
        
        do {
            repositories = try await service.fetchRepositories()
            await loadAllIssues()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func loadAllIssues() async {
        isLoadingIssues = true
        defer { isLoadingIssues = false }
        
        guard let service = gitHubService else { return }
        
        do {
            allIssues = try await service.fetchAllIssues(from: repositories)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func closeIssue(_ issue: Issue) async {
        guard let service = gitHubService,
              let repo = repositories.first(where: { $0.name == issue.repositoryName }) else { return }
        
        do {
            try await service.closeIssue(issue, repository: repo)
            await loadAllIssues()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func reopenIssue(_ issue: Issue) async {
        guard let service = gitHubService,
              let repo = repositories.first(where: { $0.name == issue.repositoryName }) else { return }
        
        do {
            try await service.reopenIssue(issue, repository: repo)
            await loadAllIssues()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Navigation Types

enum NavigationTab: String, CaseIterable {
    case repos = "Repos"
    case issues = "Issues"
    case wiki = "Wiki"
}

enum NavigationState: Equatable {
    case repositoryDetail(Repository)
    case issueDetail(Issue)
}

// MARK: - Supporting Views

struct RepositoryRow: View {
    let repository: Repository
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(repository.name)
                .font(.headline)
            
            if let description = repository.description {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            HStack(spacing: 12) {
                Label("\(repository.stargazersCount)", systemImage: "star")
                if let openCount = repository.openIssuesCount {
                    Label("\(openCount)", systemImage: "exclamationmark.circle")
                        .foregroundStyle(openCount > 0 ? .red : .secondary)
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct IssueRow: View {
    let issue: Issue
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(issue.title)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    Text("#\(issue.number)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let repoName = issue.repositoryName.split(separator: "/").last {
                        Text(String(repoName))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Circle()
                .fill(issue.isOpen ? Color.green : Color.red)
                .frame(width: 8, height: 8)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct CommentsView: View {
    let issue: Issue
    let repository: Repository
    let gitHubService: GitHubService?
    
    @State private var comments: [Comment] = []
    @State private var isLoading = false
    @State private var newCommentBody = ""
    @State private var isPosting = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Comments from GitHub (\(comments.count))")
                .font(.headline)
            
            if isLoading {
                ProgressView()
            } else if comments.isEmpty {
                Text("No comments yet")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(comments) { comment in
                    CommentRow(comment: comment)
                }
            }
            
            Divider()
            
            // Add comment
            VStack(alignment: .leading, spacing: 8) {
                Text("Add Comment")
                    .font(.subheadline)
                    .bold()
                
                TextEditor(text: $newCommentBody)
                    .frame(height: 100)
                    .border(Color.secondary.opacity(0.3))
                
                Button(action: postComment) {
                    if isPosting {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text("Post Comment")
                    }
                }
                .disabled(newCommentBody.isEmpty || isPosting)
            }
        }
        .task {
            await loadComments()
        }
    }
    
    private func loadComments() async {
        isLoading = true
        defer { isLoading = false }
        
        guard let service = gitHubService else { return }
        
        do {
            comments = try await service.fetchComments(for: issue, repository: repository)
        } catch {
            print("Error loading comments: \(error)")
        }
    }
    
    private func postComment() {
        guard !newCommentBody.isEmpty, let service = gitHubService else { return }
        
        isPosting = true
        
        Task {
            do {
                try await service.postComment(to: issue, repository: repository, body: newCommentBody)
                newCommentBody = ""
                await loadComments()
            } catch {
                print("Error posting comment: \(error)")
            }
            isPosting = false
        }
    }
}

struct CommentRow: View {
    let comment: Comment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(comment.user.login)
                    .font(.subheadline)
                    .bold()
                
                Spacer()
                
                Text(comment.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(comment.body)
                .font(.body)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct CreateIssueSheet: View {
    let repository: Repository
    let gitHubService: GitHubService?
    let onCreated: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var issueBody = ""
    @State private var isCreating = false
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                
                TextEditor(text: $issueBody)
                    .frame(height: 200)
            }
            .navigationTitle("Create Issue")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createIssue()
                    }
                    .disabled(title.isEmpty || isCreating)
                }
            }
        }
        .frame(width: 500, height: 400)
    }
    
    private func createIssue() {
        guard let service = gitHubService else { return }
        
        isCreating = true
        
        Task {
            do {
                try await service.createIssue(in: repository, title: title, body: issueBody.isEmpty ? nil : issueBody)
                onCreated()
                dismiss()
            } catch {
                print("Error creating issue: \(error)")
            }
            isCreating = false
        }
    }
}

#Preview {
    ContentView()
}

