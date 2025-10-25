//
//  GitHubService.swift
//  GIT IssueTracker Light
//
//  Complete GitHub API integration
//  Generated: 2025 OCT 25 1548
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
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let repositories = try decoder.decode([Repository].self, from: data)
            print("â Fetched \(repositories.count) repositories")
            return repositories
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
        
        let owner = repository.fullName.components(separatedBy: "/")[0]
        let repo = repository.name
        let urlString = "https://api.github.com/repos/\(owner)/\(repo)/issues?state=\(state)&per_page=100"
        
        guard let url = URL(string: urlString) else {
            throw GitHubError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(configManager.config.github.token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        
        print("ð Fetching issues for \(repo)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            print("â HTTP Error: \(httpResponse.statusCode)")
            throw GitHubError.httpError(httpResponse.statusCode)
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            var issues = try decoder.decode([Issue].self, from: data)
            
            // Add repository name to each issue
            for index in issues.indices {
                issues[index].repositoryName = repository.name
            }
            
            print("â Fetched \(issues.count) issues from \(repo)")
            return issues
        } catch {
            print("â Decoding error: \(error)")
            throw GitHubError.decodingError(error)
        }
    }
    
    // MARK: - Fetch All Issues Across All Repos
    
    func fetchAllIssues(from repositories: [Repository]) async throws -> [Issue] {
        var allIssues: [Issue] = []
        
        for repo in repositories {
            do {
                let issues = try await fetchIssues(for: repo, state: "all")
                allIssues.append(contentsOf: issues)
            } catch {
                print("â ï¸ Failed to fetch issues for \(repo.name): \(error)")
                // Continue with other repos even if one fails
            }
        }
        
        print("â Fetched total of \(allIssues.count) issues across all repos")
        return allIssues
    }
    
    // MARK: - Fetch Comments
    
    func fetchComments(for issue: Issue, repository: Repository) async throws -> [Comment] {
        guard !configManager.config.github.token.isEmpty else {
            throw GitHubError.noToken
        }
        
        let owner = repository.fullName.components(separatedBy: "/")[0]
        let repo = repository.name
        let urlString = "https://api.github.com/repos/\(owner)/\(repo)/issues/\(issue.number)/comments"
        
        guard let url = URL(string: urlString) else {
            throw GitHubError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(configManager.config.github.token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        
        print("ð Fetching comments for issue #\(issue.number)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            print("â HTTP Error: \(httpResponse.statusCode)")
            throw GitHubError.httpError(httpResponse.statusCode)
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let comments = try decoder.decode([Comment].self, from: data)
            print("â Fetched \(comments.count) comments")
            return comments
        } catch {
            print("â Decoding error: \(error)")
            throw GitHubError.decodingError(error)
        }
    }
    
    // MARK: - Post Comment
    
    func postComment(to issue: Issue, repository: Repository, body: String) async throws {
        guard !configManager.config.github.token.isEmpty else {
            throw GitHubError.noToken
        }
        
        let owner = repository.fullName.components(separatedBy: "/")[0]
        let repo = repository.name
        let urlString = "https://api.github.com/repos/\(owner)/\(repo)/issues/\(issue.number)/comments"
        
        guard let url = URL(string: urlString) else {
            throw GitHubError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(configManager.config.github.token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let commentBody = ["body": body]
        request.httpBody = try JSONEncoder().encode(commentBody)
        
        print("ð Posting comment to issue #\(issue.number)")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubError.invalidResponse
        }
        
        guard httpResponse.statusCode == 201 else {
            print("â HTTP Error: \(httpResponse.statusCode)")
            throw GitHubError.httpError(httpResponse.statusCode)
        }
        
        print("â Comment posted successfully")
    }
    
    // MARK: - Close Issue
    
    func closeIssue(_ issue: Issue, repository: Repository) async throws {
        try await updateIssueState(issue, repository: repository, state: "closed")
    }
    
    // MARK: - Reopen Issue
    
    func reopenIssue(_ issue: Issue, repository: Repository) async throws {
        try await updateIssueState(issue, repository: repository, state: "open")
    }
    
    // MARK: - Update Issue State
    
    private func updateIssueState(_ issue: Issue, repository: Repository, state: String) async throws {
        guard !configManager.config.github.token.isEmpty else {
            throw GitHubError.noToken
        }
        
        let owner = repository.fullName.components(separatedBy: "/")[0]
        let repo = repository.name
        let urlString = "https://api.github.com/repos/\(owner)/\(repo)/issues/\(issue.number)"
        
        guard let url = URL(string: urlString) else {
            throw GitHubError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(configManager.config.github.token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let updateBody = ["state": state]
        request.httpBody = try JSONEncoder().encode(updateBody)
        
        print("ð Updating issue #\(issue.number) to \(state)")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            print("â HTTP Error: \(httpResponse.statusCode)")
            throw GitHubError.httpError(httpResponse.statusCode)
        }
        
        print("â Issue \(state) successfully")
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

