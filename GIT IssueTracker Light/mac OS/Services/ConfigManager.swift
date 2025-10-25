//
//  ConfigManager.swift
//  GIT IssueTracker Light
//
//  Manages app configuration and GitHub credentials
//

import Foundation

struct AppConfig: Codable {
    var github: GitHubConfig
    
    struct GitHubConfig: Codable {
        var username: String
        var token: String
    }
}

@Observable
class ConfigManager {
    var config: AppConfig
    
    private let configURL: URL
    
    init() {
        // Store config in Application Support directory
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("GIT IssueTracker Light")
        
        // Create folder if it doesn't exist
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
        
        configURL = appFolder.appendingPathComponent("config.json")
        
        // Load existing config or create default
        if let data = try? Data(contentsOf: configURL),
           let loadedConfig = try? JSONDecoder().decode(AppConfig.self, from: data) {
            self.config = loadedConfig
        } else {
            self.config = AppConfig(
                github: AppConfig.GitHubConfig(
                    username: "",
                    token: ""
                )
            )
        }
    }
    
    func save() {
        do {
            let data = try JSONEncoder().encode(config)
            try data.write(to: configURL)
        } catch {
            print("Failed to save config: \(error)")
        }
    }
}

