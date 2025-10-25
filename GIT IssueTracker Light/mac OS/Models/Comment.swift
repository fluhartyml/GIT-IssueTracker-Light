//
//  Comment.swift
//  GIT IssueTracker Light
//
//  GitHub Comment model for issue discussions
//  Generated: 2025 OCT 25 1546
//

import Foundation

struct Comment: Identifiable, Codable {
    let id: Int
    let body: String
    let createdAt: Date
    let updatedAt: Date
    let user: CommentUser
    
    enum CodingKeys: String, CodingKey {
        case id, body, user
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct CommentUser: Codable {
    let login: String
    let avatarUrl: String
    
    enum CodingKeys: String, CodingKey {
        case login
        case avatarUrl = "avatar_url"
    }
}

// Mock data for previews
extension Comment {
    static let mock = Comment(
        id: 1,
        body: "This is a sample comment for testing",
        createdAt: Date(),
        updatedAt: Date(),
        user: CommentUser(
            login: "fluhartyml",
            avatarUrl: "https://avatars.githubusercontent.com/u/123456"
        )
    )
}

