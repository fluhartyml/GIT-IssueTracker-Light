//
//  Issue.swift
//  GIT IssueTracker Light
//
//  GitHub Issue model with repository name tracking
//  Generated: 2025 OCT 25 1545
//

import Foundation

struct Issue: Identifiable, Codable, Hashable {
    let id: Int
    let number: Int
    let title: String
    let body: String?
    let state: String
    let createdAt: Date
    let updatedAt: Date
    let closedAt: Date?
    let comments: Int
    var repositoryName: String = ""
    
    enum CodingKeys: String, CodingKey {
        case id, number, title, body, state, comments
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case closedAt = "closed_at"
    }
    
    var isOpen: Bool {
        state == "open"
    }
    
    var isClosed: Bool {
        state == "closed"
    }
    
    // Color coding for QA workflow
    var statusColor: String {
        if isClosed {
            return "green" // Resolved/archived
        } else if comments > 0 {
            return "yellow" // Active discussion
        } else {
            return "red" // New/untouched
        }
    }
}

// Mock data for previews
extension Issue {
    static let mock = Issue(
        id: 1,
        number: 1,
        title: "Sample Issue",
        body: "This is a sample issue for testing",
        state: "open",
        createdAt: Date(),
        updatedAt: Date(),
        closedAt: nil,
        comments: 3,
        repositoryName: "sample-repo"
    )
}

