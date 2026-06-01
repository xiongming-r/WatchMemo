import SwiftUI

struct ProviderSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var inbox: PhoneInboxViewModel

    @State private var selectedProvider: ProviderRuntimeSettings.SelectedProvider = .fake
    @State private var endpointText = ""
    @State private var modelText = ""
    @State private var apiKeyText = ""
    @State private var hasSavedKey = false
    @State private var statusText: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Provider") {
                    Picker("Mode", selection: $selectedProvider) {
                        Text("Fake").tag(ProviderRuntimeSettings.SelectedProvider.fake)
                        Text("OpenAI-compatible").tag(ProviderRuntimeSettings.SelectedProvider.openAICompatible)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Remote") {
                    TextField("Endpoint", text: $endpointText)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                    TextField("Model", text: $modelText)
                        .textInputAutocapitalization(.never)
                    SecureField(hasSavedKey ? "API key saved" : "API key", text: $apiKeyText)
                        .textInputAutocapitalization(.never)

                    if hasSavedKey {
                        Button("Remove saved API key", role: .destructive) {
                            removeKey()
                        }
                    }
                }

                if let statusText {
                    Section {
                        Text(statusText)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Provider")
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
        let settings = inbox.providerSettings
        selectedProvider = settings.selectedProvider
        endpointText = settings.endpointURL.absoluteString
        modelText = settings.model
        hasSavedKey = inbox.hasSavedAPIKey
        apiKeyText = ""
        statusText = nil
    }

    private func save() {
        let trimmedEndpoint = endpointText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedModel = modelText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedKey = apiKeyText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let endpointURL = URL(string: trimmedEndpoint),
              let scheme = endpointURL.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              endpointURL.host?.isEmpty == false,
              !trimmedModel.isEmpty else {
            statusText = "Endpoint and model are required"
            return
        }

        guard selectedProvider != .openAICompatible || hasSavedKey || !trimmedKey.isEmpty else {
            statusText = "API key is required"
            return
        }

        let settings = ProviderRuntimeSettings(
            selectedProvider: selectedProvider,
            endpointURL: endpointURL,
            model: trimmedModel
        )

        do {
            try inbox.saveProviderSettings(settings, apiKey: trimmedKey)
            hasSavedKey = inbox.hasSavedAPIKey
            apiKeyText = ""
            statusText = "Saved"
            dismiss()
        } catch {
            statusText = error.localizedDescription
        }
    }

    private func removeKey() {
        do {
            try inbox.deleteAPIKey()
            hasSavedKey = false
            apiKeyText = ""
            statusText = "API key removed"
        } catch {
            statusText = error.localizedDescription
        }
    }
}
