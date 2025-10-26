//
//  WikiView.swift
//  GIT IssueTracker Light
//
//  Main wiki interface view
//

import SwiftUI

struct WikiView: View {
    let repositories: [Repository]
    @State private var selectedRepository: Repository?
    @State private var wikiService: WikiService?
    @State private var wikiInfo: WikiInfo?
    @State private var isLoading = false
    
    var body: some View {
        NavigationSplitView {
            // SIDEBAR: Repository list for wiki
            wikiRepositoryList
        } detail: {
            // MAIN AREA: Wiki content
            if let repo = selectedRepository {
                wikiDetailView(for: repo)
            } else {
                wikiPlaceholder
            }
        }
    }
    
    // MARK: - Repository List
    
    private var wikiRepositoryList: some View {
        List(repositories, id: \.id, selection: $selectedRepository) { repo in
            Button(action: {
                selectedRepository = repo
                Task {
                    await loadWikiInfo(for: repo)
                }
            }) {
                HStack {
                    Image(systemName: "folder.fill")
                        .foregroundStyle(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(repo.name)
                            .font(.headline)
                        
                        if repo.hasWiki == true {
                            Label("Wiki Available", systemImage: "book.closed.fill")
                                .font(.caption2)
                                .foregroundStyle(.green)
                        } else {
                            Label("No Wiki", systemImage: "book.closed")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Wiki Detail View
    
    private func wikiDetailView(for repository: Repository) -> some View {
        VStack(spacing: 20) {
            if isLoading {
                ProgressView("Loading wiki info...")
            } else if let info = wikiInfo, info.isAvailable {
                wikiAvailableView(repository: repository, info: info)
            } else {
                wikiNotAvailableView(repository: repository)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            await loadWikiInfo(for: repository)
        }
    }
    
    // MARK: - Wiki Available View
    
    private func wikiAvailableView(repository: Repository, info: WikiInfo) -> some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue)
                
                Text("\(repository.name) Wiki")
                    .font(.title)
                    .bold()
                
                Text("This repository has a wiki available")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
                .frame(maxWidth: 400)
            
            // Info box
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.blue)
                    Text("GitHub Wiki Access")
                        .font(.headline)
                }
                
                Text("GitHub wikis are stored as separate Git repositories. To view and edit wiki content, you can:")
                    .font(.body)
                    .foregroundStyle(.secondary)
                
                VStack(alignment: .leading, spacing: 8) {
                    Label("View wiki in your browser", systemImage: "safari")
                    Label("Clone the wiki repository", systemImage: "arrow.down.circle")
                    Label("Edit pages on GitHub.com", systemImage: "pencil")
                }
                .font(.caption)
                .padding(.leading, 8)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
            .frame(maxWidth: 500)
            
            // Action buttons
            VStack(spacing: 12) {
                Button(action: {
                    wikiService?.openWikiInBrowser(for: repository)
                }) {
                    Label("Open Wiki in Browser", systemImage: "safari")
                        .frame(maxWidth: 300)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                if let wikiUrl = info.wikiUrl {
                    Button(action: {
                        let cloneUrl = wikiUrl + ".git"
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(cloneUrl, forType: .string)
                    }) {
                        Label("Copy Wiki Clone URL", systemImage: "doc.on.doc")
                            .frame(maxWidth: 300)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
        }
        .padding()
    }
    
    // MARK: - Wiki Not Available View
    
    private func wikiNotAvailableView(repository: Repository) -> some View {
        VStack(spacing: 30) {
            Image(systemName: "book.closed")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text("No Wiki Available")
                .font(.title)
                .bold()
            
            Text("This repository doesn't have a wiki enabled")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Divider()
                .frame(maxWidth: 400)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("To enable the wiki:")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("1. Go to repository Settings on GitHub")
                    Text("2. Check 'Wikis' in the Features section")
                    Text("3. Create your first wiki page")
                }
                .font(.body)
                .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
            .frame(maxWidth: 500)
            
            Button(action: {
                if let url = URL(string: "https://github.com/\(repository.fullName)/settings") {
                    NSWorkspace.shared.open(url)
                }
            }) {
                Label("Open Repository Settings", systemImage: "gear")
                    .frame(maxWidth: 300)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .padding()
    }
    
    // MARK: - Placeholder
    
    private var wikiPlaceholder: some View {
        ContentUnavailableView(
            "Select a Repository",
            systemImage: "book.closed",
            description: Text("Choose a repository to view its wiki")
        )
    }
    
    // MARK: - Helper Functions
    
    private func loadWikiInfo(for repository: Repository) async {
        guard let service = wikiService else { return }
        
        isLoading = true
        
        do {
            wikiInfo = try await service.checkWikiAvailability(for: repository)
        } catch {
            print("Error loading wiki info: \(error)")
        }
        
        isLoading = false
    }
}

#Preview {
    WikiView(repositories: [])
}
