//
//  EditorView[macOS].swift
//  GIT IssueTracker Light
//
//  Markdown editor for issue descriptions
//

import SwiftUI

struct EditorView: View {
    @Binding var text: String
    @Environment(\.dismiss) var dismiss
    
    @State private var showingPreview = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Toolbar
                HStack {
                    Text(showingPreview ? "Preview" : "Edit")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button {
                        showingPreview.toggle()
                    } label: {
                        Label(
                            showingPreview ? "Edit" : "Preview",
                            systemImage: showingPreview ? "pencil" : "eye"
                        )
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                
                Divider()
                
                // Content Area
                if showingPreview {
                    ScrollView {
                        Text(text.isEmpty ? "Nothing to preview" : text)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                } else {
                    TextEditor(text: $text)
                        .font(.body)
                        .padding(8)
                }
            }
            .navigationTitle("Edit Issue")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}

#Preview {
    EditorView(text: .constant("# Sample Markdown\n\nThis is a **preview** of the editor."))
}
