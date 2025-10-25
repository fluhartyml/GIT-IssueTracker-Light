//
//  GitHubService.swift
//  GIT IssueTracker Light
//
//  GitHub API integration with QA issue tracking
//

import Foundation

enum GitHubError: Error {
    case invalidURL
    case noToken
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)
}

class GitHubService {
    private let configManager: ConfigManager
    
    init(configManager: ConfigManager) {
        self.configManager = configManager
    }
    
    // MARK: - Fetch Repositories
    
    func fetchRepositories() async throws -> [Repository] {
        guard !configManager.config.github.token.isEmpty else {
            throw GitHubError.noToken
        }
        
        let username = configManager.config.github.username
        let urlString = "https://api.github.com/users/\(username)/repos?per_page=100&sort=updated"
        
        guard let url = URL(string: urlString) else {
            throw GitHubError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(configManager.config.github.token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        
        print("ð Fetching repositories for user: \(username)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            print("â HTTP Error: \(httpResponse.statusCode)")
            throw GitHubError.httpError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let repos = try decoder.decode([Repository].self, from: data)
            print("â Successfully decoded \(repos.count) repositories")
            return repos
        } catch {
            print("â Decoding error: \(error)")
            throw GitHubError.decodingError(error)
        }
    }
    
    // MARK: - Fetch Issues
    
    func fetchIssues(for repository: Repository, state: String = "all") async throws -> [Issue] {
        guard !configManager.config.github.token.isEmpty else {
            throw GitHubError.noToken
        }
        
        let urlString = "https://api.github.com/repos/\(repository.fullName)/issues?state=\(state)&per_page=100"
        
        guard let url = URL(string: urlString) else {
            throw GitHubError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(configManager.config.github.token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        
        print("ð Fetching issues for \(repository.name)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            print("â HTTP Error: \(httpResponse.statusCode)")
            throw GitHubError.httpError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let issues = try decoder.decode([Issue].self, from: data)
            print("â Successfully decoded \(issues.count) issues for \(repository.name)")
            return issues
        } catch {
            print("â Decoding error: \(error)")
            throw GitHubError.decodingError(error)
        }
    }
    
    // MARK: - Fetch Comments
    
    func fetchComments(repository: Repository, issueNumber: Int) async throws -> [Comment] {
        guard !configManager.config.github.token.isEmpty else {
            throw GitHubError.noToken
        }
        
        let urlString = "https://api.github.com/repos/\(repository.fullName)/issues/\(issueNumber)/comments"
        
        guard let url = URL(string: urlString) else {
            throw GitHubError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(configManager.config.github.token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        
        print("ð¬ Fetching comments for issue #\(issueNumber) in \(repository.name)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            print("â HTTP Error: \(httpResponse.statusCode)")
            throw GitHubError.httpError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let comments = try decoder.decode([Comment].self, from: data)
            print("â Successfully decoded \(comments.count) comments")
            return comments
        } catch {
            print("â Decoding error: \(error)")
            throw GitHubError.decodingError(error)
        }
    }
    
    // MARK: - Add Comment
    
    func addComment(repository: Repository, issueNumber: Int, body: String) async throws {
        guard !configManager.config.github.token.isEmpty else {
            throw GitHubError.noToken
        }
        
        let urlString = "https://api.github.com/repos/\(repository.fullName)/issues/\(issueNumber)/comments"
        
        guard let url = URL(string: urlString) else {
            throw GitHubError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(configManager.config.github.token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: String] = ["body": body]
        request.httpBody = try JSONEncoder().encode(payload)
        
        print("ð¬ Adding comment to issue #\(issueNumber) in \(repository.name)")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubError.invalidResponse
        }
        
        guard httpResponse.statusCode == 201 else {
            print("â HTTP Error: \(httpResponse.statusCode)")
            throw GitHubError.httpError(httpResponse.statusCode)
        }
        
        print("â Successfully added comment to issue #\(issueNumber)")
    }
    
    // MARK: - Close/Reopen Issue
    
    func updateIssueState(repository: Repository, issueNumber: Int, state: String) async throws {
        guard !configManager.config.github.token.isEmpty else {
            throw GitHubError.noToken
        }
        
        let urlString = "https://api.github.com/repos/\(repository.fullName)/issues/\(issueNumber)"
        
        guard let url = URL(string: urlString) else {
            throw GitHubError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(configManager.config.github.token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: String] = ["state": state]
        request.httpBody = try JSONEncoder().encode(payload)
        
        print("ð Updating issue #\(issueNumber) state to: \(state)")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            print("â HTTP Error: \(httpResponse.statusCode)")
            throw GitHubError.httpError(httpResponse.statusCode)
        }
        
        print("â Successfully \(state == "closed" ? "closed" : "reopened") issue #\(issueNumber)")
    }
    
    // MARK: - Create Issue
    
    func createIssue(repository: Repository, title: String, body: String, labels: [String] = []) async throws {
        guard !configManager.config.github.token.isEmpty else {
            throw GitHubError.noToken
        }
        
        let urlString = "https://api.github.com/repos/\(repository.fullName)/issues"
        
        guard let url = URL(string: urlString) else {
            throw GitHubError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(configManager.config.github.token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var payload: [String: Any] = [
            "title": title,
            "body": body
        ]
        
        if !labels.isEmpty {
            payload["labels"] = labels
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        print("â Creating new issue: '\(title)' in \(repository.name)")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubError.invalidResponse
        }
        
        guard httpResponse.statusCode == 201 else {
            print("â HTTP Error: \(httpResponse.statusCode)")
            throw GitHubError.httpError(httpResponse.statusCode)
        }
        
        print("â Successfully created issue '\(title)'")
    }
}

// MARK: - Error Descriptions

extension GitHubError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .noToken:
            return "No GitHub token configured. Please add your token in settings."
        case .invalidURL:
            return "Invalid GitHub API URL"
        case .invalidResponse:
            return "Invalid response from GitHub"
        case .httpError(let code):
            return "GitHub API error: HTTP \(code)"
        case .decodingError(let error):
            return "Failed to decode GitHub response: \(error.localizedDescription)"
        }
    }
}
