//
//  WikiPageView.swift
//  GIT IssueTracker Light
//
//  Display view for individual wiki pages (future implementation)
//

import SwiftUI

struct WikiPageView: View {
    let page: WikiPage
    let content: String?
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Page header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .font(.title)
                            .foregroundStyle(.blue)
                        
                        Text(page.title)
                            .font(.largeTitle)
                            .bold()
                        
                        Spacer()
                        
                        Button(action: {
                            if let url = URL(string: page.htmlUrl) {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            Label("View on GitHub", systemImage: "safari")
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    if let updated = page.lastUpdated {
                        Text("Last updated \(updated, style: .relative)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                Divider()
                
                // Page content
                if isLoading {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Loading page content...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                } else if let content = content {
                    Text(content)
                        .padding(.horizontal)
                        .textSelection(.enabled)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        
                        Text("Content not available")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        Text("This requires cloning the wiki Git repository")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Button(action: {
                            if let url = URL(string: page.htmlUrl) {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            Label("View on GitHub", systemImage: "safari")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            }
        }
    }
}

#Preview {
    WikiPageView(
        page: WikiPage(
            title: "Home",
            htmlUrl: "https://github.com/user/repo/wiki/Home"
        ),
        content: "# Welcome to the Wiki\n\nThis is a sample wiki page."
    )
}
