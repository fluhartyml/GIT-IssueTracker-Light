//
//  Comment.swift
//  GIT IssueTracker Light
//
//  GitHub issue comment data model
//

import Foundation

struct Comment: Codable, Identifiable, Hashable {
    let id: Int
    let body: String
    let user: IssueUser
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case body
        case user
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// Mock data for previews
extension Comment {
    static let mock = Comment(
        id: 1,
        body: "This is a great idea! I'll work on implementing this feature.",
        user: IssueUser(login: "fluhartyml", avatarUrl: "https://avatars.githubusercontent.com/u/961824"),
        createdAt: Date().addingTimeInterval(-86400 * 2),
        updatedAt: Date().addingTimeInterval(-86400 * 2)
    )
    
    static let mock2 = Comment(
        id: 2,
        body: "Thanks for the quick response! Looking forward to seeing this.",
        user: IssueUser(login: "contributor", avatarUrl: "https://avatars.githubusercontent.com/u/1"),
        createdAt: Date().addingTimeInterval(-86400),
        updatedAt: Date().addingTimeInterval(-86400)
    )
}

