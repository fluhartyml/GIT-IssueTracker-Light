//
//  WikiModels.swift
//  GIT IssueTracker Light
//
//  Data models for GitHub Wiki integration
//

import Foundation

// MARK: - Wiki Page Model

struct WikiPage: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let title: String
    let htmlUrl: String
    let sha: String?
    let lastUpdated: Date?
    
    // Computed property for filename
    var filename: String {
        title.replacingOccurrences(of: " ", with: "-") + ".md"
    }
    
    init(title: String, htmlUrl: String, sha: String? = nil, lastUpdated: Date? = nil) {
        self.id = UUID().uuidString
        self.title = title
        self.htmlUrl = htmlUrl
        self.sha = sha
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Wiki Content

struct WikiContent: Codable {
    let title: String
    let content: String
    let sha: String
    let htmlUrl: String
    
    enum CodingKeys: String, CodingKey {
        case title = "name"
        case content
        case sha
        case htmlUrl = "html_url"
    }
}

// MARK: - Wiki Repository Info

struct WikiInfo {
    let repository: Repository
    let hasWiki: Bool
    let wikiUrl: String?
    
    var isAvailable: Bool {
        hasWiki && wikiUrl != nil
    }
}
