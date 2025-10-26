//
//  WikiListView.swift
//  GIT IssueTracker Light
//
//  List view for wiki pages (future implementation)
//

import SwiftUI

struct WikiListView: View {
    let repository: Repository
    let pages: [WikiPage]
    @Binding var selectedPage: WikiPage?
    
    var body: some View {
        List(pages, selection: $selectedPage) { page in
            Button(action: {
                selectedPage = page
            }) {
                HStack {
                    Image(systemName: "doc.text.fill")
                        .foregroundStyle(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(page.title)
                            .font(.headline)
                        
                        if let updated = page.lastUpdated {
                            Text("Updated \(updated, style: .relative)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .overlay {
            if pages.isEmpty {
                ContentUnavailableView(
                    "No Wiki Pages",
                    systemImage: "doc.text",
                    description: Text("This wiki doesn't have any pages yet")
                )
            }
        }
    }
}

#Preview {
    WikiListView(
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
        pages: [],
        selectedPage: .constant(nil)
    )
}
