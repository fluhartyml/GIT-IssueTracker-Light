//
//  ContentView[macOS].swift
//  GIT IssueTracker Light
//
//  Main interface with developer debug panel
//  Generated: 2025 OCT 25 1700
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
    @State private var navigationStack: [NavigationState] = []
    @State private var showingSettings = false
    @State private var isLoadingRepos = false
    @State private var isLoadingIssues = false
    @State private var errorMessage: String?
    
    // DEBUG STATE
    @State private var showDebugPanel = true
    @State private var lastSyncTime: Date?
    @State private var apiCallsInProgress = 0
    @State private var lastApiCallDuration: TimeInterval?
    @State private var rateLimitRemaining: Int?
    @State private var rateLimitTotal: Int?
    @State private var errorLog: [DebugError] = []
    
    enum NavigationTab {
        case repos, issues, wiki
    }
    
    enum NavigationState {
        case repositoryDetail(Repository)
        case allIssues
        case issueDetail(Issue, Repository)
    }
    
    struct DebugError: Identifiable {
        let id = UUID()
        let timestamp: Date
        let message: String
    }
    
    var body: some View {
        VStack(spacing: 0) {
            NavigationSplitView {
                // PANE B - Left sidebar
                VStack(spacing: 0) {
                    Picker("", selection: $selectedTab) {
                        Text("Repos").tag(NavigationTab.repos)
                        Text("Issues").tag(NavigationTab.issues)
                        Text("Wiki").tag(NavigationTab.wiki)
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    .labelsHidden()
                    
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
                            if isLoadingRepos {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .frame(width: 16, height: 16)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                        }
                        .disabled(isLoadingRepos)
                    }
                    ToolbarItem(placement: .automatic) {
                        Button(action: { showDebugPanel.toggle() }) {
                            Image(systemName: showDebugPanel ? "ladybug.fill" : "ladybug")
                        }
                        .help("Toggle Debug Panel (⌘D)")
                    }
                }
            } detail: {
                paneAContent
            }
            
            // DEBUG PANEL AT BOTTOM
            if showDebugPanel {
                debugPanel
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
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "d" {
                    showDebugPanel.toggle()
                    return nil
                }
                return event
            }
        }
    }
    
    // MARK: - Debug Panel
    
    private var debugPanel: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 20) {
                // CONNECTION STATUS
                HStack(spacing: 6) {
                    Circle()
                        .fill(apiCallsInProgress > 0 ? Color.yellow : Color.green)
                        .frame(width: 8, height: 8)
                    Text(apiCallsInProgress > 0 ? "SYNCING" : "CONNECTED")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                    .frame(height: 12)
                
                // LAST SYNC
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    if let lastSync = lastSyncTime {
                        Text(timeAgo(from: lastSync))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("NO SYNC YET")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
                
                Divider()
                    .frame(height: 12)
                
                // API RATE LIMIT
                HStack(spacing: 4) {
                    Image(systemName: "gauge.medium")
                        .font(.system(size: 10))
                        .foregroundStyle(rateLimitColor)
                    if let remaining = rateLimitRemaining, let total = rateLimitTotal {
                        Text("API: \(remaining)/\(total)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(rateLimitColor)
                    } else {
                        Text("API: ---")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
                
                Divider()
                    .frame(height: 12)
                
                // RESPONSE TIME
                HStack(spacing: 4) {
                    Image(systemName: "speedometer")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    if let duration = lastApiCallDuration {
                        Text(String(format: "%.0fms", duration * 1000))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("---ms")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
                
                Divider()
                    .frame(height: 12)
                
                // DATA COUNTS
                HStack(spacing: 4) {
                    Image(systemName: "folder")
                        .font(.system(size: 10))
                        .foregroundStyle(.blue)
                    Text("\(repositories.count)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)
                    
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 10))
                        .foregroundStyle(.red)
                    Text("\(allIssues.count)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                    .frame(height: 12)
                
                // ERROR LOG
                if !errorLog.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.orange)
                        Text("\(errorLog.count) ERROR\(errorLog.count == 1 ? "" : "S")")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.orange)
                    }
                    .onTapGesture {
                        showErrorLog()
                    }
                    .help("Click to view error log")
                }
                
                Spacer()
                
                // TOGGLE BUTTON
                Button(action: { showDebugPanel = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Hide debug panel (⌘D)")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(nsColor: .controlBackgroundColor))
        }
    }
    
    private var rateLimitColor: Color {
        guard let remaining = rateLimitRemaining, let total = rateLimitTotal else {
            return .secondary
        }
        let percentage = Double(remaining) / Double(total)
        if percentage > 0.5 {
            return .green
        } else if percentage > 0.2 {
            return .yellow
        } else {
            return .red
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 {
            return "JUST NOW"
        } else if seconds < 3600 {
            let mins = seconds / 60
            return "\(mins)m AGO"
        } else {
            let hours = seconds / 3600
            return "\(hours)h AGO"
        }
    }
    
    private func showErrorLog() {
        let alert = NSAlert()
        alert.messageText = "Error Log"
        alert.informativeText = errorLog.reversed().map { error in
            let time = error.timestamp.formatted(date: .omitted, time: .shortened)
            return "[\(time)] \(error.message)"
        }.joined(separator: "\n")
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Clear Log")
        
        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            errorLog.removeAll()
        }
    }
    
    // MARK: - Pane A Content Router
    
    @ViewBuilder
    private var paneAContent: some View {
        if selectedTab == .wiki {
            // ALWAYS show Wiki placeholder when Wiki tab is selected
            wikiPlaceholderView
        } else if let issue = selectedIssue, let repo = repositories.first(where: { $0.name == issue.repositoryName }) {
            issueDetailView(issue: issue, repository: repo)
        } else if selectedTab == .issues {
            allIssuesView
        } else if let repo = selectedRepository {
            repositoryDetailView(repository: repo)
        } else {
            placeholderView
        }
    }
    
    // MARK: - Repository List View
    
    private var repositoryListView: some View {
        List(repositories, selection: $selectedRepository) { repo in
            Button(action: {
                navigateToRepository(repo)
            }) {
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
            .buttonStyle(.plain)
            .background(selectedRepository?.id == repo.id ? Color.accentColor.opacity(0.2) : Color.clear)
        }
        .overlay {
            if isLoadingRepos {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading repositories...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(nsColor: .windowBackgroundColor).opacity(0.95))
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
            Button(action: {
                if let repo = repositories.first(where: { $0.name == issue.repositoryName }) {
                    navigateToIssue(issue, repository: repo)
                }
            }) {
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
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading issues...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(nsColor: .windowBackgroundColor).opacity(0.95))
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
                
                ForEach(allIssues.sorted(by: { $0.createdAt > $1.createdAt }), id: \.id) { issue in
                    Button(action: {
                        if let repo = repositories.first(where: { $0.name == issue.repositoryName }) {
                            navigateToIssue(issue, repository: repo)
                        }
                    }) {
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
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading issues...")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(nsColor: .windowBackgroundColor).opacity(0.95))
            }
        }
    }
    
    // MARK: - Issue Detail View
    
    private func issueDetailView(issue: Issue, repository: Repository) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Button(action: navigateBack) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
                .padding(.top)
                
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
                
                HStack {
                    if issue.isOpen {
                        Button("Close Issue") {
                            Task {
                                do {
                                    try await gitHubService?.closeIssue(issue, repository: repository)
                                    await fetchData()
                                } catch {
                                    logError("Failed to close issue: \(error.localizedDescription)")
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
                                    await fetchData()
                                } catch {
                                    logError("Failed to reopen issue: \(error.localizedDescription)")
                                    errorMessage = error.localizedDescription
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.horizontal)
                
                Divider()
                
                CommentsView(
                    issue: issue,
                    repository: repository,
                    gitHubService: gitHubService,
                    onCommentPosted: {
                        Task {
                            await fetchData()
                        }
                    }
                )
                .id("\(issue.id)-\(repository.id)")
            }
        }
    }
    
    // MARK: - Repository Detail View
    
    private func repositoryDetailView(repository: Repository) -> some View {
        RepositoryDetailView(
            repository: repository,
            allIssues: allIssues,
            gitHubService: gitHubService,
            onIssueCreated: {
                Task {
                    await fetchData()
                }
            },
            onIssueSelected: { issue in
                navigateToIssue(issue, repository: repository)
            }
        )
    }
    
    // MARK: - Placeholder View
    
    private var placeholderView: some View {
        ContentUnavailableView(
            "Select a Repository",
            systemImage: "folder.badge.questionmark",
            description: Text("Choose a repository from the sidebar to view details")
        )
    }
    
    // MARK: - Wiki Placeholder View
    
    private var wikiPlaceholderView: some View {
        VStack(spacing: 20) {
            Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 128, height: 128)
                .cornerRadius(16)
                .shadow(radius: 8)
            
            Text("Wiki - Coming Soon")
                .font(.title)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Navigation Functions
    
    private func navigateToRepository(_ repository: Repository) {
        selectedRepository = repository
        selectedIssue = nil
        selectedTab = .repos
    }
    
    private func navigateToIssue(_ issue: Issue, repository: Repository) {
        if let currentRepo = selectedRepository {
            navigationStack.append(.repositoryDetail(currentRepo))
        } else if selectedTab == .issues && selectedIssue == nil {
            navigationStack.append(.allIssues)
        }
        
        selectedIssue = issue
        selectedRepository = nil
        selectedTab = .issues
    }
    
    private func navigateBack() {
        guard !navigationStack.isEmpty else {
            selectedIssue = nil
            selectedRepository = nil
            selectedTab = .repos
            return
        }
        
        let previousState = navigationStack.removeLast()
        
        switch previousState {
        case .repositoryDetail(let repo):
            selectedIssue = nil
            selectedRepository = repo
            selectedTab = .repos
        case .allIssues:
            selectedIssue = nil
            selectedRepository = nil
            selectedTab = .issues
        case .issueDetail(let issue, _):
            selectedIssue = issue
            selectedRepository = nil
            selectedTab = .issues
        }
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
    
    private func logError(_ message: String) {
        errorLog.append(DebugError(timestamp: Date(), message: message))
        if errorLog.count > 10 {
            errorLog.removeFirst()
        }
    }
    
    private func fetchData() async {
        guard let service = gitHubService else { return }
        
        apiCallsInProgress += 1
        isLoadingRepos = true
        let startTime = Date()
        
        do {
            repositories = try await service.fetchRepositories()
            
            isLoadingIssues = true
            allIssues = try await service.fetchAllIssues(from: repositories)
            isLoadingIssues = false
            
            lastSyncTime = Date()
            lastApiCallDuration = Date().timeIntervalSince(startTime)
            
            // Mock rate limit (would come from GitHub API headers in real implementation)
            rateLimitRemaining = Int.random(in: 4000...5000)
            rateLimitTotal = 5000
        } catch {
            logError("Fetch failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        isLoadingRepos = false
        apiCallsInProgress -= 1
    }
}

// MARK: - Repository Detail View

struct RepositoryDetailView: View {
    let repository: Repository
    let allIssues: [Issue]
    let gitHubService: GitHubService?
    let onIssueCreated: () -> Void
    let onIssueSelected: (Issue) -> Void
    
    @State private var showingCreateIssue = false
    
    var repositoryOpenIssues: [Issue] {
        allIssues
            .filter { $0.repositoryName == repository.name && $0.isOpen }
            .sorted { $0.createdAt < $1.createdAt }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
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
                        
                        if let openIssues = repository.openIssuesCount, openIssues > 0 {
                            VStack {
                                Text("\(openIssues)")
                                    .font(.title2)
                                    .bold()
                                    .foregroundStyle(.red)
                                Text("Open Issues")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Open Issues")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if repositoryOpenIssues.isEmpty {
                            Text("No open issues for this repository")
                                .foregroundStyle(.secondary)
                                .italic()
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(repositoryOpenIssues) { issue in
                                Button(action: {
                                    onIssueSelected(issue)
                                }) {
                                    HStack(alignment: .top, spacing: 12) {
                                        Circle()
                                            .fill(colorForStatus(issue.statusColor))
                                            .frame(width: 10, height: 10)
                                            .padding(.top, 6)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Text("#\(issue.number)")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                                Text(issue.title)
                                                    .font(.headline)
                                                Spacer()
                                            }
                                            
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
                                    }
                                    .padding()
                                    .background(Color(nsColor: .controlBackgroundColor))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            
            Divider()
            
            HStack(spacing: 12) {
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
                
                Button("Create New Issue") {
                    showingCreateIssue = true
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .sheet(isPresented: $showingCreateIssue) {
            CreateIssueView(
                repository: repository,
                gitHubService: gitHubService,
                onIssueCreated: onIssueCreated
            )
        }
    }
    
    private func colorForStatus(_ status: String) -> Color {
        switch status {
        case "red": return .red
        case "yellow": return .yellow
        case "green": return .green
        default: return .gray
        }
    }
}

// MARK: - Create Issue View

struct CreateIssueView: View {
    let repository: Repository
    let gitHubService: GitHubService?
    let onIssueCreated: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var issueTitle = ""
    @State private var issueBody = ""
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Create New Issue")
                    .font(.headline)
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            
            Form {
                Section {
                    HStack {
                        Text("Repository:")
                            .foregroundStyle(.secondary)
                        Text(repository.name)
                            .bold()
                    }
                }
                
                Section("Title") {
                    TextField("Issue title", text: $issueTitle)
                        .textFieldStyle(.plain)
                }
                
                Section("Description (optional)") {
                    TextEditor(text: $issueBody)
                        .frame(minHeight: 150)
                        .border(Color.gray.opacity(0.3))
                }
            }
            .padding()
            
            HStack {
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                
                Spacer()
                
                if isCreating {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Creating...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Button("Create Issue") {
                    Task {
                        await createIssue()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(issueTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCreating)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .frame(width: 600, height: 500)
    }
    
    private func createIssue() async {
        guard let service = gitHubService else { return }
        guard !issueTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isCreating = true
        errorMessage = nil
        
        do {
            try await service.createIssue(
                in: repository,
                title: issueTitle,
                body: issueBody.isEmpty ? nil : issueBody
            )
            
            onIssueCreated()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isCreating = false
    }
}

// MARK: - Comments View

struct CommentsView: View {
    let issue: Issue
    let repository: Repository
    let gitHubService: GitHubService?
    let onCommentPosted: () -> Void
    
    @State private var comments: [Comment] = []
    @State private var newCommentText = ""
    @State private var isLoadingComments = false
    @State private var isPostingComment = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Comments from GitHub (\(comments.count))")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    Task {
                        await loadComments()
                    }
                }) {
                    if isLoadingComments {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .buttonStyle(.borderless)
                .disabled(isLoadingComments)
            }
            .padding(.horizontal)
            
            if isLoadingComments {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        ProgressView()
                        Text("Loading comments...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding()
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
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Add Comment")
                    .font(.headline)
                
                TextEditor(text: $newCommentText)
                    .frame(minHeight: 100)
                    .border(Color.gray.opacity(0.3))
                
                HStack {
                    Spacer()
                    
                    if isPostingComment {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Posting...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
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
            await loadComments()
            onCommentPosted()
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
                
                HStack(spacing: 4) {
                    Text("Generate a token at:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Button(action: {
                        if let url = URL(string: "https://github.com/settings/tokens") {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        Text("github.com/settings/tokens")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                    .help("Click to open in browser")
                }
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

