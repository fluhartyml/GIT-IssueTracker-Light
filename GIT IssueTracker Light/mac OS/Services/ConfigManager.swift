//
//  ConfigManager.swift
//  GIT IssueTracker Light
//
//  Secure configuration management for GitHub credentials
//  Generated: 2025 OCT 25 1547
//

import Foundation

struct GitHubConfig: Codable {
    var username: String = ""
    var token: String = ""
}

struct AppConfig: Codable {
    var github: GitHubConfig = GitHubConfig()
}

@Observable
class ConfigManager {
    var config: AppConfig
    
    private let configFileURL: URL = {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        
        let appFolder = appSupport.appendingPathComponent("GIT IssueTracker Light")
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(
            at: appFolder,
            withIntermediateDirectories: true
        )
        
        return appFolder.appendingPathComponent("config.json")
    }()
    
    init() {
        if let data = try? Data(contentsOf: configFileURL),
           let decoded = try? JSONDecoder().decode(AppConfig.self, from: data) {
            self.config = decoded
            print("â Config loaded from: \(configFileURL.path)")
        } else {
            self.config = AppConfig()
            print("ð Using default config, will save to: \(configFileURL.path)")
        }
    }
    
    func save() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(config)
            try data.write(to: configFileURL)
            print("â Config saved successfully")
        } catch {
            print("â Failed to save config: \(error)")
        }
    }
}

