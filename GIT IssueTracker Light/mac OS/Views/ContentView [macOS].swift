//
//  ContentView.swift
//  GIT IssueTracker Light
//
//  Main interface with segmented navigation, All Issues view, and comments system
//  Generated: 2025 OCT 25 1550
//

import SwiftUI

struct ContentView: View {
    @State private var configManager = ConfigManager()
    @State private var gitHubService: GitHubService?
    
    @State private var repositories: [Repository] = []
    @State private var allIssues: [Issue] = []
    @State private var selectedRepository: Repository?
    @State private var selectedIssue: Issue?
    
    @State private var selectedTab: NavigationTab = .repos
    @State private var showingSettings = false
    @State private var isLoadingRepos = false
    @State private var isLoadingIssues = false
    @State private var errorMessage: String?
    
    enum NavigationTab {
        case repos, issues, wiki
    }
    
    var body: some View {
        NavigationSplitView {
            // PANE B - Left sidebar with segmented control
            VStack(spacing: 0) {
                // Segmented control for tab switching
                Picker("Navigation", selection: $selectedTab) {
                    Text("Repos").tag(NavigationTab.repos)
                    Text("Issues").tag(NavigationTab.issues)
                    Text("Wiki").tag(NavigationTab.wiki)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content based on selected tab
                switch selectedTab {
                case .repos:
                    repositoryListView
                case .issues:
                    issueNavigatorView
                case .wiki:
                    Text("Wiki - Coming Soon")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("GIT IssueTracker Light")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gear")
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Button(action: { Task { await fetchData() } }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoadingRepos)
                }
            }
        } detail: {
            // PANE A - Main content area
            if selectedTab == .issues || selectedIssue != nil {
                if let issue = selectedIssue, let repo = repositories.first(where: { $0.name == issue.repositoryName }) {
                    issueDetailView(issue: issue, repository: repo)
                } else {
                    allIssuesView
                }
            } else if let repo = selectedRepository {
                repositoryDetailView(repository: repo)
            } else {
                placeholderView
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(configManager: configManager)
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .task {
            gitHubService = GitHubService(configManager: configManager)
            if !configManager.config.github.token.isEmpty {
                await fetchData()
            }
        }
    }
    
    // MARK: - Repository List View
    
    private var repositoryListView: some View {
        List(repositories, selection: $selectedRepository) { repo in
            NavigationLink(value: repo) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundStyle(.blue)
                        Text(repo.name)
                            .font(.headline)
                    }
                    
                    if let description = repo.description {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    
                    HStack(spacing: 12) {
                        if let language = repo.language {
                            Label(language, systemImage: "chevron.left.forwardslash.chevron.right")
                                .font(.caption2)
                        }
                        if let openIssues = repo.openIssuesCount, openIssues > 0 {
                            Label("\(openIssues)", systemImage: "exclamationmark.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(.red)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .overlay {
            if isLoadingRepos {
                ProgressView("Loading repositories...")
            } else if repositories.isEmpty {
                ContentUnavailableView(
                    "No Repositories",
                    systemImage: "folder.badge.questionmark",
                    description: Text("Configure your GitHub credentials in settings")
                )
            }
        }
    }
    
    // MARK: - Issue Navigator View (Pane B - older on top)
    
    private var issueNavigatorView: some View {
        List(allIssues.sorted(by: { $0.createdAt < $1.createdAt }), // OLDER ON TOP
             id: \.id,
             selection: $selectedIssue) { issue in
            Button(action: { selectedIssue = issue }) {
                HStack {
                    Circle()
                        .fill(colorForStatus(issue.statusColor))
                        .frame(width: 8, height: 8)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("#\(issue.number) - \(issue.title)")
                            .font(.headline)
                            .lineLimit(1)
                        
                        Text(issue.repositoryName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        HStack {
                            if issue.comments > 0 {
                                Label("\(issue.comments)", systemImage: "bubble.left")
                                    .font(.caption2)
                            }
                            Text(issue.createdAt, style: .relative)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if issue.isClosed {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
            }
            .buttonStyle(.plain)
            .background(selectedIssue?.id == issue.id ? Color.accentColor.opacity(0.2) : Color.clear)
        }
        .overlay {
            if isLoadingIssues {
                ProgressView("Loading issues...")
            } else if allIssues.isEmpty {
                ContentUnavailableView(
                    "No Issues",
                    systemImage: "checklist",
                    description: Text("No issues found across your repositories")
                )
            }
        }
    }
    
    // MARK: - All Issues View (Pane A - newer on top)
    
    private var allIssuesView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                Text("All Issues")
                    .font(.largeTitle)
                    .bold()
                    .padding(.horizontal)
                    .padding(.top)
                
                ForEach(allIssues.sorted(by: { $0.createdAt > $1.createdAt }), id: \.id) { issue in // NEWER ON TOP
                    Button(action: { selectedIssue = issue }) {
                        HStack(alignment: .top, spacing: 12) {
                            Circle()
                                .fill(colorForStatus(issue.statusColor))
                                .frame(width: 12, height: 12)
                                .padding(.top, 4)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("#\(issue.number)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(issue.repositoryName)
                                        .font(.caption)
                                        .foregroundStyle(.blue)
                                    Spacer()
                                    if issue.isClosed {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                            .font(.caption)
                                    }
                                }
                                
                                Text(issue.title)
                                    .font(.headline)
                                    .multilineTextAlignment(.leading)
                                
                                HStack {
                                    if issue.comments > 0 {
                                        Label("\(issue.comments) comments", systemImage: "bubble.left")
                                            .font(.caption)
                                    }
                                    Text("Created " + issue.createdAt.formatted(date: .abbreviated, time: .omitted))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
            }
            .padding(.bottom)
        }
        .overlay {
            if isLoadingIssues {
                ProgressView("Loading issues...")
            }
        }
    }
    
    // MARK: - Issue Detail View
    
    private func issueDetailView(issue: Issue, repository: Repository) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Back button
                Button(action: { selectedIssue = nil }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
                .padding(.top)
                
                // Issue header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Circle()
                            .fill(colorForStatus(issue.statusColor))
                            .frame(width: 12, height: 12)
                        Text("#\(issue.number)")
                            .font(.title2)
                            .bold()
                        Text(repository.name)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if issue.isClosed {
                            Label("Closed", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            Label("Open", systemImage: "exclamationmark.circle.fill")
                                .foregroundStyle(.red)
                        }
                    }
                    
                    Text(issue.title)
                        .font(.title)
                        .bold()
                    
                    Text("Created " + issue.createdAt.formatted(date: .long, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                
                Divider()
                
                // Issue body
                if let body = issue.body, !body.isEmpty {
                    Text(body)
                        .padding(.horizontal)
                        .textSelection(.enabled)
                } else {
                    Text("No description provided")
                        .foregroundStyle(.secondary)
                        .italic()
                        .padding(.horizontal)
                }
                
                Divider()
                
                // Action buttons
                HStack {
                    if issue.isOpen {
                        Button("Close Issue") {
                            Task {
                                do {
                                    try await gitHubService?.closeIssue(issue, repository: repository)
                                    await fetchData() // Refresh data
                                } catch {
                                    errorMessage = error.localizedDescription
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Button("Reopen Issue") {
                            Task {
                                do {
                                    try await gitHubService?.reopenIssue(issue, repository: repository)
                                    await fetchData() // Refresh data
                                } catch {
                                    errorMessage = error.localizedDescription
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Button("View Comments") {
                        // Navigate to comments view
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal)
                
                Divider()
                
                // Comments section
                CommentsView(issue: issue, repository: repository, gitHubService: gitHubService)
            }
        }
    }
    
    // MARK: - Repository Detail View
    
    private func repositoryDetailView(repository: Repository) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Repository header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "folder.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.blue)
                        
                        VStack(alignment: .leading) {
                            Text(repository.name)
                                .font(.title)
                                .bold()
                            Text(repository.fullName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if let description = repository.description {
                        Text(description)
                            .padding(.top, 4)
                    }
                }
                .padding()
                
                Divider()
                
                // Repository stats
                HStack(spacing: 30) {
                    if let language = repository.language {
                        VStack {
                            Text(language)
                                .font(.title2)
                                .bold()
                            Text("Language")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    VStack {
                        Text("\(repository.stargazersCount)")
                            .font(.title2)
                            .bold()
                        Text("Stars")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    VStack {
                        Text("\(repository.forksCount)")
                            .font(.title2)
                            .bold()
                        Text("Forks")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let openIssues = repository.openIssuesCount {
                        VStack {
                            Text("\(openIssues)")
                                .font(.title2)
                                .bold()
                                .foregroundStyle(openIssues > 0 ? .red : .primary)
                            Text("Open Issues")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                
                Divider()
                
                // Action buttons
                VStack(spacing: 12) {
                    Button("Open on GitHub") {
                        if let url = URL(string: repository.htmlUrl) {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Copy Clone URL") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(repository.htmlUrl + ".git", forType: .string)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
        }
    }
    
    // MARK: - Placeholder View
    
    private var placeholderView: some View {
        ContentUnavailableView(
            "Select a Repository",
            systemImage: "folder.badge.questionmark",
            description: Text("Choose a repository from the sidebar to view details")
        )
    }
    
    // MARK: - Helper Functions
    
    private func colorForStatus(_ status: String) -> Color {
        switch status {
        case "red": return .red
        case "yellow": return .yellow
        case "green": return .green
        default: return .gray
        }
    }
    
    private func fetchData() async {
        guard let service = gitHubService else { return }
        
        isLoadingRepos = true
        
        do {
            repositories = try await service.fetchRepositories()
            
            isLoadingIssues = true
            allIssues = try await service.fetchAllIssues(from: repositories)
            isLoadingIssues = false
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoadingRepos = false
    }
}

// MARK: - Comments View

struct CommentsView: View {
    let issue: Issue
    let repository: Repository
    let gitHubService: GitHubService?
    
    @State private var comments: [Comment] = []
    @State private var newCommentText = ""
    @State private var isLoadingComments = false
    @State private var isPostingComment = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Comments (\(comments.count))")
                .font(.headline)
                .padding(.horizontal)
            
            if isLoadingComments {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if comments.isEmpty {
                Text("No comments yet")
                    .foregroundStyle(.secondary)
                    .italic()
                    .padding(.horizontal)
            } else {
                ForEach(comments) { comment in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(comment.user.login)
                                .font(.headline)
                            Text(comment.createdAt, style: .relative)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Text(comment.body)
                            .textSelection(.enabled)
                    }
                    .padding()
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
            }
            
            Divider()
            
            // New comment input
            VStack(alignment: .leading, spacing: 8) {
                Text("Add Comment")
                    .font(.headline)
                
                TextEditor(text: $newCommentText)
                    .frame(minHeight: 100)
                    .border(Color.gray.opacity(0.3))
                
                HStack {
                    Spacer()
                    Button("Post Comment") {
                        Task {
                            await postComment()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isPostingComment)
                }
            }
            .padding()
        }
        .task {
            await loadComments()
        }
    }
    
    private func loadComments() async {
        guard let service = gitHubService else { return }
        
        isLoadingComments = true
        
        do {
            comments = try await service.fetchComments(for: issue, repository: repository)
        } catch {
            print("Error loading comments: \(error)")
        }
        
        isLoadingComments = false
    }
    
    private func postComment() async {
        guard let service = gitHubService else { return }
        guard !newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isPostingComment = true
        
        do {
            try await service.postComment(to: issue, repository: repository, body: newCommentText)
            newCommentText = ""
            await loadComments() // Reload comments
        } catch {
            print("Error posting comment: \(error)")
        }
        
        isPostingComment = false
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var configManager: ConfigManager
    
    var body: some View {
        Form {
            Section("GitHub Credentials") {
                TextField("Username", text: $configManager.config.github.username)
                SecureField("Personal Access Token", text: $configManager.config.github.token)
                
                Text("Generate a token at: github.com/settings/tokens")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Save") {
                    configManager.save()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 500, height: 250)
    }
}

#Preview {
    ContentView()
}

