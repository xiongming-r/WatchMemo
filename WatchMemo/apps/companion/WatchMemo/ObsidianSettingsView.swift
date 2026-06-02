import SwiftUI

struct ObsidianSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var inbox: PhoneInboxViewModel

    @State private var vaultName = ""
    @State private var folderPath = ""
    @State private var openAfterExport = true
    @State private var statusText: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Obsidian") {
                    TextField("Vault name", text: $vaultName)
                        .textInputAutocapitalization(.never)
                    TextField("Folder path", text: $folderPath)
                        .textInputAutocapitalization(.never)
                    Toggle("Open after export", isOn: $openAfterExport)
                }

                if let statusText {
                    Section {
                        Text(statusText)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Obsidian")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                }
            }
            .onAppear {
                load()
            }
        }
    }

    private func load() {
        let settings = inbox.obsidianSettings
        vaultName = settings.vaultName
        folderPath = settings.folderPath
        openAfterExport = settings.openAfterExport
        statusText = nil
    }

    private func save() {
        let settings = ObsidianExportSettings(
            vaultName: vaultName.trimmingCharacters(in: .whitespacesAndNewlines),
            folderPath: folderPath.trimmingCharacters(in: .whitespacesAndNewlines),
            openAfterExport: openAfterExport
        )

        do {
            try inbox.saveObsidianSettings(settings)
            statusText = "Saved"
            dismiss()
        } catch {
            statusText = error.localizedDescription
        }
    }
}
