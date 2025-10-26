//
//  WikiEditorView.swift
//  GIT IssueTracker Light
//
//  Editor for creating and editing wiki pages (future implementation)
//

import SwiftUI

struct WikiEditorView: View {
    let repository: Repository
    let existingPage: WikiPage?
    let onSave: (String, String) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var pageTitle: String
    @State private var pageContent: String
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    init(repository: Repository, existingPage: WikiPage? = nil, onSave: @escaping (String, String) -> Void) {
        self.repository = repository
        self.existingPage = existingPage
        self.onSave = onSave
        
        _pageTitle = State(initialValue: existingPage?.title ?? "")
        _pageContent = State(initialValue: "")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(existingPage == nil ? "Create Wiki Page" : "Edit Wiki Page")
                    .font(.headline)
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            
            // Editor form
            Form {
                Section {
                    HStack {
                        Text("Repository:")
                            .foregroundStyle(.secondary)
                        Text(repository.name)
                            .bold()
                    }
                }
                
                Section("Page Title") {
                    TextField("Enter page title", text: $pageTitle)
                        .textFieldStyle(.plain)
                        .disabled(existingPage != nil) // Can't rename existing pages
                }
                
                Section("Content (Markdown)") {
                    TextEditor(text: $pageContent)
                        .frame(minHeight: 300)
                        .font(.system(.body, design: .monospaced))
                        .border(Color.gray.opacity(0.3))
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.blue)
                            Text("Coming Soon")
                                .font(.headline)
                        }
                        
                        Text("Direct wiki editing requires Git repository access. For now, you can:")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• Edit pages on GitHub.com")
                            Text("• Clone the wiki repository")
                            Text("• Use GitHub's web interface")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 8)
                    }
                    .padding()
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding()
            
            // Footer buttons
            HStack {
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                
                Spacer()
                
                if isSaving {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Saving...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Button("Save Page") {
                    savePage()
                }
                .buttonStyle(.borderedProminent)
                .disabled(pageTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .frame(width: 700, height: 600)
    }
    
    private func savePage() {
        guard !pageTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isSaving = true
        errorMessage = nil
        
        // This would call WikiService to save the page
        // For now, just show not implemented message
        errorMessage = "Wiki editing requires Git repository access (coming in v2.0)"
        
        isSaving = false
        
        // In future: onSave(pageTitle, pageContent)
        // dismiss()
    }
}

#Preview {
    WikiEditorView(
        repository: Repository(
            id: 1,
            name: "Test",
            fullName: "user/test",
            description: "Test repo",
            htmlUrl: "https://github.com",
            language: "Swift",
            stargazersCount: 0,
            forksCount: 0,
            openIssuesCount: 0,
            hasWiki: true
        ),
        onSave: { _, _ in }
    )
}
