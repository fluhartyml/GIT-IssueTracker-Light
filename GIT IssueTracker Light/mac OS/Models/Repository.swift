//
//  Repository.swift
//  GIT IssueTracker Light
//
//  GitHub repository data model
//

import Foundation

struct Repository: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let fullName: String
    let description: String?
    let htmlUrl: String
    let language: String?
    let stargazersCount: Int
    let forksCount: Int
    let openIssuesCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, language
        case fullName = "full_name"
        case htmlUrl = "html_url"
        case stargazersCount = "stargazers_count"
        case forksCount = "forks_count"
        case openIssuesCount = "open_issues_count"
    }
}

// Mock data for previews
extension Repository {
    static let mock = Repository(
        id: 1,
        name: "sample-repo",
        fullName: "fluhartyml/sample-repo",
        description: "A sample repository for testing",
        htmlUrl: "https://github.com/fluhartyml/sample-repo",
        language: "Swift",
        stargazersCount: 42,
        forksCount: 7,
        openIssuesCount: 3
    )
}

