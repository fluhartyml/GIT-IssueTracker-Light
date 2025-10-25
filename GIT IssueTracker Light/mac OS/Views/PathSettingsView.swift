//
//  PathSettingsView.swift
//  GIT IssueTracker Light
//
//  Settings view for GitHub credentials
//

import SwiftUI

struct PathSettingsView: View {
    @Bindable var configManager: ConfigManager
    @Environment(\.dismiss) var dismiss
    
    @State private var username: String = ""
    @State private var token: String = ""
    @State private var showingSaved = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Enter your GitHub credentials to access your repositories and issues.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("GitHub Configuration")
                }
                
                Section {
                    TextField("GitHub Username", text: $username)
                        .textContentType(.username)
                    
                    SecureField("Personal Access Token", text: $token)
                        .textContentType(.password)
                } header: {
                    Text("Credentials")
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Generate a Personal Access Token at:")
                        Link("github.com/settings/tokens", destination: URL(string: "https://github.com/settings/tokens")!)
                            .font(.caption)
                        
                        Text("Required scopes: repo, read:user")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section {
                    if showingSaved {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Settings saved successfully!")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSettings()
                    }
                    .disabled(username.isEmpty || token.isEmpty)
                }
            }
            .onAppear {
                username = configManager.config.github.username
                token = configManager.config.github.token
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }
    
    private func saveSettings() {
        configManager.config.github.username = username
        configManager.config.github.token = token
        configManager.save()
        
        showingSaved = true
        
        // Dismiss after showing success message
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
}

#Preview {
    PathSettingsView(configManager: ConfigManager())
}
