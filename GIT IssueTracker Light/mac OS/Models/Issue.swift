//
//  Issue.swift
//  GIT IssueTracker Light
//
//  GitHub issue data model
//

import Foundation

struct Issue: Codable, Identifiable, Hashable {
    let id: Int
    let number: Int
    let title: String
    let body: String?
    let state: String
    let user: IssueUser
    let createdAt: Date
    let updatedAt: Date
    let closedAt: Date?
    let comments: Int?
    let htmlUrl: String
    
    enum CodingKeys: String, CodingKey {
        case id, number, title, body, state, user, comments
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case closedAt = "closed_at"
        case htmlUrl = "html_url"
    }
}

struct IssueUser: Codable, Hashable {
    let login: String
    let avatarUrl: String
    
    enum CodingKeys: String, CodingKey {
        case login
        case avatarUrl = "avatar_url"
    }
}

// Mock data for previews
extension Issue {
    static let mock = Issue(
        id: 1,
        number: 42,
        title: "Sample Issue Title",
        body: "This is a sample issue description with some details.",
        state: "open",
        user: IssueUser(login: "fluhartyml", avatarUrl: "https://avatars.githubusercontent.com/u/961824"),
        createdAt: Date(),
        updatedAt: Date(),
        closedAt: nil,
        comments: 5,
        htmlUrl: "https://github.com/user/repo/issues/42"
    )
}

