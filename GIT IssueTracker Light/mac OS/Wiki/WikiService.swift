//
//  WikiService.swift
//  GIT IssueTracker Light
//
//  Service layer for GitHub Wiki API interactions
//

import Foundation
import AppKit

class WikiService {
    private let configManager: ConfigManager
    
    init(configManager: ConfigManager) {
        self.configManager = configManager
    }
    
    // MARK: - Check if Repository has Wiki
    
    func checkWikiAvailability(for repository: Repository) async throws -> WikiInfo {
        // GitHub API returns has_wiki in repository data
        let hasWiki = repository.hasWiki ?? false
        let wikiUrl = hasWiki ? "https://github.com/\(repository.fullName)/wiki" : nil
        
        return WikiInfo(
            repository: repository,
            hasWiki: hasWiki,
            wikiUrl: wikiUrl
        )
    }
    
    // MARK: - Fetch Wiki Pages List
    
    func fetchWikiPages(for repository: Repository) async throws -> [WikiPage] {
        // GitHub doesn't have a direct API for wiki pages list
        // We need to clone the wiki repo or scrape the wiki URL
        // For now, return mock data and open wiki in browser
        
        guard repository.hasWiki == true else {
            throw WikiError.wikiNotEnabled
        }
        
        // This would require cloning the wiki Git repo
        // For v1, we'll just provide a link to open in browser
        return []
    }
    
    // MARK: - Fetch Wiki Page Content
    
    func fetchWikiPageContent(repository: Repository, pageName: String) async throws -> WikiContent {
        // Would require wiki Git repo access
        throw WikiError.notImplemented
    }
    
    // MARK: - Create/Update Wiki Page
    
    func updateWikiPage(repository: Repository, pageName: String, content: String) async throws {
        // Would require wiki Git repo access
        throw WikiError.notImplemented
    }
    
    // MARK: - Open Wiki in Browser
    
    func openWikiInBrowser(for repository: Repository) {
        let wikiUrl = "https://github.com/\(repository.fullName)/wiki"
        if let url = URL(string: wikiUrl) {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Wiki Errors

enum WikiError: LocalizedError {
    case wikiNotEnabled
    case notImplemented
    case invalidRepository
    
    var errorDescription: String? {
        switch self {
        case .wikiNotEnabled:
            return "This repository does not have a wiki enabled"
        case .notImplemented:
            return "This feature requires direct wiki Git repo access (coming soon)"
        case .invalidRepository:
            return "Invalid repository"
        }
    }
}
