import SwiftUI
import UIKit

struct AppSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appSettings: AppSettingsStore

    @ObservedObject var inbox: PhoneInboxViewModel

    @State private var selectedProvider: ProviderRuntimeSettings.SelectedProvider = .fake
    @State private var endpointText = ""
    @State private var modelText = ""
    @State private var apiKeyText = ""
    @State private var hasSavedKey = false
    @State private var vaultName = ""
    @State private var folderPath = ""
    @State private var openAfterExport = true
    @State private var statusText: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.wmBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        settingsHero
                        appearanceSection
                        languageSection
                        providerSection
                        obsidianSection

                        if let statusText {
                            SettingsPanel {
                                Label(statusText, systemImage: "info.circle")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color.wmSecondaryText)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle(t("Settings", "设置"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(t("Close", "关闭")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(t("Save", "保存")) {
                        saveAll()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                load()
            }
        }
    }

    private var settingsHero: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(t("Workspace", "工作区"))
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.wmCyan)
                .textCase(.uppercase)

            Text(t("Tune capture, AI, and note delivery.", "配置记录、AI 整理和笔记投递。"))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Color.wmText)
                .fixedSize(horizontal: false, vertical: true)

            Text(t("Appearance and language changes apply immediately inside WatchMemo.", "外观和语言设置会立即应用到 WatchMemo 的主要界面。"))
                .font(.system(size: 14))
                .foregroundStyle(Color.wmSecondaryText)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.wmCard)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var appearanceSection: some View {
        SettingsPanel(title: t("Appearance", "外观"), systemName: "sun.max") {
            Picker(t("Theme", "主题"), selection: $appSettings.themeMode) {
                ForEach(AppThemeMode.allCases) { themeMode in
                    Text(themeMode.displayName(language: appSettings.language)).tag(themeMode)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var languageSection: some View {
        SettingsPanel(title: t("Language", "语言"), systemName: "globe") {
            Picker(t("App language", "应用语言"), selection: $appSettings.language) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.displayName).tag(language)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var providerSection: some View {
        SettingsPanel(title: t("AI Provider", "AI 服务"), systemName: "sparkles") {
            VStack(alignment: .leading, spacing: 12) {
                Picker(t("Mode", "模式"), selection: $selectedProvider) {
                    Text(t("Fake", "模拟")).tag(ProviderRuntimeSettings.SelectedProvider.fake)
                    Text(t("Audio", "音频理解")).tag(ProviderRuntimeSettings.SelectedProvider.openAICompatible)
                }
                .pickerStyle(.segmented)

                SettingsTextField(
                    title: t("Endpoint", "接口地址"),
                    text: $endpointText,
                    keyboardType: .URL
                )
                SettingsTextField(
                    title: t("Model", "模型"),
                    text: $modelText
                )

                SecureField(hasSavedKey ? t("API key saved", "API Key 已保存") : t("API key", "API Key"), text: $apiKeyText)
                    .textInputAutocapitalization(.never)
                    .padding(12)
                    .background(Color.wmElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                if hasSavedKey {
                    Button(role: .destructive) {
                        removeKey()
                    } label: {
                        Label(t("Remove saved API key", "移除已保存的 API Key"), systemImage: "trash")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var obsidianSection: some View {
        SettingsPanel(title: t("Obsidian Delivery", "Obsidian 投递"), systemName: "books.vertical") {
            VStack(alignment: .leading, spacing: 12) {
                SettingsTextField(title: t("Vault name", "仓库名称"), text: $vaultName)
                SettingsTextField(title: t("Folder path", "文件夹路径"), text: $folderPath)

                Toggle(isOn: $openAfterExport) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(t("Open after export", "导出后打开 Obsidian"))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.wmText)
                        Text(t("Disable this to copy the Obsidian URL only.", "关闭后只复制 Obsidian URL。"))
                            .font(.system(size: 12))
                            .foregroundStyle(Color.wmSecondaryText)
                    }
                }
                .tint(Color.wmCyan)
            }
        }
    }

    private func load() {
        let providerSettings = inbox.providerSettings
        selectedProvider = providerSettings.selectedProvider
        endpointText = providerSettings.endpointURL.absoluteString
        modelText = providerSettings.model
        hasSavedKey = inbox.hasSavedAPIKey
        apiKeyText = ""

        let obsidianSettings = inbox.obsidianSettings
        vaultName = obsidianSettings.vaultName
        folderPath = obsidianSettings.folderPath
        openAfterExport = obsidianSettings.openAfterExport
        statusText = nil
    }

    private func saveAll() {
        let trimmedEndpoint = endpointText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedModel = modelText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedKey = apiKeyText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let endpointURL = URL(string: trimmedEndpoint),
              let scheme = endpointURL.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              endpointURL.host?.isEmpty == false,
              !trimmedModel.isEmpty else {
            statusText = t("Endpoint and model are required", "需要填写接口地址和模型")
            return
        }

        guard selectedProvider != .openAICompatible || hasSavedKey || !trimmedKey.isEmpty else {
            statusText = t("API key is required", "需要填写 API Key")
            return
        }

        do {
            let providerSettings = ProviderRuntimeSettings(
                selectedProvider: selectedProvider,
                endpointURL: endpointURL,
                model: trimmedModel
            )
            try inbox.saveProviderSettings(providerSettings, apiKey: trimmedKey)

            let obsidianSettings = ObsidianExportSettings(
                vaultName: vaultName.trimmingCharacters(in: .whitespacesAndNewlines),
                folderPath: folderPath.trimmingCharacters(in: .whitespacesAndNewlines),
                openAfterExport: openAfterExport
            )
            try inbox.saveObsidianSettings(obsidianSettings)

            hasSavedKey = inbox.hasSavedAPIKey
            apiKeyText = ""
            statusText = t("Settings saved", "设置已保存")
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
            statusText = t("API key removed", "API Key 已移除")
        } catch {
            statusText = error.localizedDescription
        }
    }

    private func t(_ english: String, _ simplifiedChinese: String) -> String {
        appSettings.text(english, simplifiedChinese)
    }
}

private struct SettingsPanel<Content: View>: View {
    var title: String?
    var systemName: String?
    @ViewBuilder var content: Content

    init(title: String? = nil, systemName: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemName = systemName
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let title {
                HStack(spacing: 8) {
                    if let systemName {
                        Image(systemName: systemName)
                    }
                    Text(title)
                }
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.wmCyan)
                .textCase(.uppercase)
            }

            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.wmCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct SettingsTextField: View {
    let title: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        TextField(title, text: $text)
            .textInputAutocapitalization(.never)
            .keyboardType(keyboardType)
            .padding(12)
            .background(Color.wmElevated)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
