//
//  ContentView[macOS].swift
//  GIT IssueTracker Light
//
//  Main interface with repository and issue management
//

import SwiftUI

struct ContentView: View {
    @State private var configManager = ConfigManager()
    @State private var gitHubService: GitHubService?
    
    @State private var repositories: [Repository] = []
    @State private var selectedRepository: Repository?
    @State private var issues: [Issue] = []
    @State private var selectedIssue: Issue?
    
    @State private var isLoadingRepos = false
    @State private var isLoadingIssues = false
    @State private var errorMessage: String?
    @State private var showingSettings = false
    
    var body: some View {
        NavigationSplitView {
            // MARK: - Sidebar (Repositories & Issues)
            List(selection: $selectedRepository) {
                Section("Repositories") {
                    if isLoadingRepos {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else if repositories.isEmpty {
                        Text("No repositories found")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(repositories) { repo in
                            RepositoryRow(repository: repo)
                                .tag(repo)
                        }
                    }
                }
                
                if let repo = selectedRepository {
                    Section("Issues - \(repo.name)") {
                        if isLoadingIssues {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else if issues.isEmpty {
                            Text("No issues found")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(issues) { issue in
                                IssueRow(issue: issue)
                                    .tag(issue)
                                    .onTapGesture {
                                        selectedIssue = issue
                                    }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Git IssueTracker Lite")
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button {
                        Task {
                            await loadRepositories()
                        }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .disabled(isLoadingRepos)
                }
                
                ToolbarItem {
                    Button {
                        showingSettings = true
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                }
            }
            
        } detail: {
            // MARK: - Detail View
            if let issue = selectedIssue, let repo = selectedRepository {
                IssueDetailView(
                    issue: issue,
                    repository: repo,
                    gitHubService: gitHubService!
                )
            } else if let repo = selectedRepository {
                RepositoryDetailView(repository: repo)
            } else {
                ContentUnavailableView(
                    "Select a Repository",
                    systemImage: "folder",
                    description: Text("Choose a repository from the sidebar to view its issues")
                )
            }
        }
        .sheet(isPresented: $showingSettings) {
            PathSettingsView(configManager: configManager)
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
        .onAppear {
            gitHubService = GitHubService(configManager: configManager)
            Task {
                await loadRepositories()
            }
        }
        .onChange(of: selectedRepository) { oldValue, newValue in
            if let repo = newValue {
                Task {
                    await loadIssues(for: repo)
                }
            } else {
                issues = []
                selectedIssue = nil
            }
        }
    }
    
    // MARK: - Load Data
    
    func loadRepositories() async {
        guard let service = gitHubService else { return }
        
        isLoadingRepos = true
        errorMessage = nil
        
        do {
            repositories = try await service.fetchRepositories()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoadingRepos = false
    }
    
    func loadIssues(for repository: Repository) async {
        guard let service = gitHubService else { return }
        
        isLoadingIssues = true
        errorMessage = nil
        
        do {
            issues = try await service.fetchIssues(for: repository, state: "all")
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoadingIssues = false
    }
}

// MARK: - Repository Row

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
                Label("\(repository.stargazersCount)", systemImage: "star.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                if let language = repository.language {
                    Text(language)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Issue Row

struct IssueRow: View {
    let issue: Issue
    
    var statusColor: Color {
        switch issue.state {
        case "open":
            return .green
        case "closed":
            return .red
        default:
            return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(issue.title)
                    .font(.headline)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Text("#\(issue.number)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("by \(issue.user.login)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let comments = issue.comments, comments > 0 {
                        Label("\(comments)", systemImage: "bubble.left")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Repository Detail View

struct RepositoryDetailView: View {
    let repository: Repository
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(repository.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    if let description = repository.description {
                        Text(description)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Divider()
                
                // Stats
                HStack(spacing: 24) {
                    StatView(label: "Stars", value: "\(repository.stargazersCount)", icon: "star.fill")
                    StatView(label: "Forks", value: "\(repository.forksCount)", icon: "tuningfork")
                    if let issues = repository.openIssuesCount {
                        StatView(label: "Open Issues", value: "\(issues)", icon: "exclamationmark.circle")
                    }
                }
                
                Divider()
                
                // Links
                VStack(alignment: .leading, spacing: 8) {
                    if let language = repository.language {
                        Label(language, systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                    
                    Link(destination: URL(string: repository.htmlUrl)!) {
                        Label("View on GitHub", systemImage: "link")
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct StatView: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Label(value, systemImage: icon)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Issue Detail View

struct IssueDetailView: View {
    let issue: Issue
    let repository: Repository
    let gitHubService: GitHubService
    
    @State private var comments: [Comment] = []
    @State private var isLoadingComments = false
    @State private var newCommentText = ""
    @State private var isPostingComment = false
    @State private var errorMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Issue Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("#\(issue.number)")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        StatusBadge(state: issue.state)
                    }
                    
                    Text(issue.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 12) {
                        Label(issue.user.login, systemImage: "person.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(issue.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Divider()
                
                // Issue Body
                if let body = issue.body, !body.isEmpty {
                    Text(body)
                        .textSelection(.enabled)
                } else {
                    Text("No description provided")
                        .foregroundStyle(.secondary)
                        .italic()
                }
                
                Divider()
                
                // Comments Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Comments (\(comments.count))")
                        .font(.headline)
                    
                    if isLoadingComments {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else if comments.isEmpty {
                        Text("No comments yet")
                            .foregroundStyle(.secondary)
                            .italic()
                    } else {
                        ForEach(comments) { comment in
                            CommentView(comment: comment)
                        }
                    }
                }
                
                Divider()
                
                // Add Comment
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add Comment")
                        .font(.headline)
                    
                    TextEditor(text: $newCommentText)
                        .frame(minHeight: 100)
                        .border(Color.secondary.opacity(0.3))
                    
                    HStack {
                        Spacer()
                        
                        Button("Post Comment") {
                            Task {
                                await postComment()
                            }
                        }
                        .disabled(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isPostingComment)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            Task {
                await loadComments()
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }
    
    func loadComments() async {
        isLoadingComments = true
        
        do {
            comments = try await gitHubService.fetchComments(repository: repository, issueNumber: issue.number)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoadingComments = false
    }
    
    func postComment() async {
        let trimmedText = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        isPostingComment = true
        
        do {
            try await gitHubService.addComment(repository: repository, issueNumber: issue.number, body: trimmedText)
            newCommentText = ""
            await loadComments() // Reload to show new comment
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isPostingComment = false
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let state: String
    
    var color: Color {
        state == "open" ? .green : .red
    }
    
    var body: some View {
        Text(state.capitalized)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

// MARK: - Comment View

struct CommentView: View {
    let comment: Comment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(comment.user.login, systemImage: "person.fill")
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Text(comment.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(comment.body)
                .textSelection(.enabled)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    ContentView()
}

