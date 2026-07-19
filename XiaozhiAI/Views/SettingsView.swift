import SwiftUI

struct SettingsView: View {
    @ObservedObject var vm: ConversationViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var otaUrl: String
    @State private var websocketUrl: String
    @State private var token: String
    @State private var showToken = false
    @State private var voiceFeedback = true
    @State private var animationLevel = "标准"
    @State private var selectedModel = "Aura-Narrative-v1"

    init(vm: ConversationViewModel) {
        self.vm = vm
        _otaUrl = State(initialValue: vm.config.otaUrl)
        _websocketUrl = State(initialValue: vm.config.websocketUrl)
        _token = State(initialValue: vm.config.token)
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: AuraSpacing.lg) {
                    titleSection
                    apiConfigSection
                    characterSection
                    accountSection
                    saveButton
                }
                .padding(.horizontal, AuraSpacing.containerPadding)
                .padding(.top, 100)
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Title
    private var titleSection: some View {
        VStack(spacing: AuraSpacing.xs) {
            HStack {
                HStack(spacing: AuraSpacing.xs) {
                    Circle()
                        .fill(Color.auraPrimary)
                        .frame(width: 32, height: 32)
                        .overlay(Text("智").font(.auraLabelSm).foregroundColor(.white))
                    Text("小智")
                        .font(.auraHeadlineSm)
                        .foregroundColor(.auraPrimary)
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.auraOnSurfaceVariant)
                }
            }

            HStack {
                Text("设置")
                    .font(.auraDisplayLg)
                    .foregroundColor(.auraPrimary)
                Spacer()
            }
        }
    }

    // MARK: - API 配置 Section
    private var apiConfigSection: some View {
        VStack(spacing: 0) {
            sectionHeader(icon: "antenna.radiowaves.left.and.right", title: "API 配置", color: .auraPrimary)

            VStack(spacing: 0) {
                settingsField(
                    label: "OTA 地址",
                    placeholder: "https://api.tenclass.net/xiaozhi/ota/",
                    text: $otaUrl
                )
                Divider().padding(.leading, AuraSpacing.md)

                settingsField(
                    label: "WebSocket",
                    placeholder: "激活后自动填充",
                    text: $websocketUrl
                )
                Divider().padding(.leading, AuraSpacing.md)

                secureField(
                    label: "API 密钥",
                    placeholder: "sk-...",
                    text: $token,
                    isVisible: $showToken
                )
                Divider().padding(.leading, AuraSpacing.md)

                modelPicker
            }
        }
        .glassCard()
    }

    // MARK: - 角色设置 Section
    private var characterSection: some View {
        VStack(spacing: 0) {
            sectionHeader(icon: "face.smiling", title: "角色设置", color: .auraSecondary)

            VStack(spacing: 0) {
                toggleRow(
                    label: "语音反馈",
                    subtitle: "允许角色语音回复",
                    isOn: $voiceFeedback
                )
                Divider().padding(.leading, AuraSpacing.md)

                pickerRow(
                    label: "动画等级",
                    subtitle: "控制表情丰富程度",
                    selection: $animationLevel,
                    options: ["标准", "丰富", "简约"]
                )
            }
        }
        .glassCard()
    }

    // MARK: - 账号 Section
    private var accountSection: some View {
        VStack(spacing: 0) {
            sectionHeader(icon: "person.circle", title: "账号", color: .auraTertiary)

            VStack(spacing: 0) {
                infoRow(
                    label: "设备 ID",
                    value: String(vm.config.deviceId.prefix(16)) + "..."
                )
                Divider().padding(.leading, AuraSpacing.md)

                infoRow(label: "Client ID", value: String(vm.config.clientId.prefix(16)) + "...")

                Divider().padding(.leading, AuraSpacing.md)

                Button {
                    vm.config.otaUrl = otaUrl
                    Task { await vm.activate() }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("通过 OTA 激活")
                                .font(.auraLabelMd)
                                .foregroundColor(.auraPrimary)
                            Text("自动获取 WebSocket 地址和密钥")
                                .font(.auraLabelSm)
                                .foregroundColor(.auraOnSurfaceVariant)
                        }
                        Spacer()
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.auraPrimary)
                    }
                    .padding(AuraSpacing.md)
                }
            }
        }
        .glassCard()
    }

    // MARK: - Save Button
    private var saveButton: some View {
        Button {
            vm.config.otaUrl = otaUrl
            vm.config.websocketUrl = websocketUrl
            vm.config.token = token
            ConfigManager.shared.save(vm.config)
            if !vm.isConnected && !websocketUrl.isEmpty {
                vm.connect()
            }
            dismiss()
        } label: {
            HStack(spacing: AuraSpacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                Text("保存并连接")
                    .font(.auraLabelMd)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AuraSpacing.md)
            .background(Color.auraPrimary)
            .clipShape(Capsule())
            .shadow(color: .auraPrimary.opacity(0.4), radius: 14, x: 0, y: 4)
        }
    }

    // MARK: - Reusable Components

    private func sectionHeader(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: AuraSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
            Text(title)
                .font(.auraHeadlineSm)
                .foregroundColor(.auraOnSurface)
            Spacer()
        }
        .padding(.horizontal, AuraSpacing.md)
        .padding(.vertical, AuraSpacing.sm)
        .overlay(alignment: .bottom) {
            Color.auraOutlineVariant.opacity(0.3).frame(height: 1)
        }
    }

    private func settingsField(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.auraLabelMd)
                .foregroundColor(.auraOnSurfaceVariant)
            TextField(placeholder, text: text)
                .font(.auraBodyMd)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal, AuraSpacing.md)
                .padding(.vertical, AuraSpacing.sm)
                .background(Color.auraSurfaceLow)
                .clipShape(RoundedRectangle(cornerRadius: AuraRadius.lg, style: .continuous))
        }
        .padding(AuraSpacing.md)
    }

    private func secureField(label: String, placeholder: String, text: Binding<String>, isVisible: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.auraLabelMd)
                .foregroundColor(.auraOnSurfaceVariant)
            HStack {
                if isVisible.wrappedValue {
                    TextField(placeholder, text: text)
                } else {
                    SecureField(placeholder, text: text)
                }
                Button {
                    isVisible.wrappedValue.toggle()
                } label: {
                    Image(systemName: isVisible.wrappedValue ? "eye.fill" : "eye.slash.fill")
                        .foregroundColor(.auraOnSurfaceVariant)
                }
            }
            .font(.auraBodyMd)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding(.horizontal, AuraSpacing.md)
            .padding(.vertical, AuraSpacing.sm)
            .background(Color.auraSurfaceLow)
            .clipShape(RoundedRectangle(cornerRadius: AuraRadius.lg, style: .continuous))
        }
        .padding(AuraSpacing.md)
    }

    private var modelPicker: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("模型选择")
                .font(.auraLabelMd)
                .foregroundColor(.auraOnSurfaceVariant)
            Picker("模型", selection: $selectedModel) {
                Text("Aura-Narrative-v1").tag("Aura-Narrative-v1")
                Text("Companion-Lite").tag("Companion-Lite")
                Text("Expressive-Pro").tag("Expressive-Pro")
            }
            .pickerStyle(.menu)
            .font(.auraBodyMd)
            .tint(.auraPrimary)
            .padding(.horizontal, AuraSpacing.md)
            .padding(.vertical, AuraSpacing.sm)
            .background(Color.auraSurfaceLow)
            .clipShape(RoundedRectangle(cornerRadius: AuraRadius.lg, style: .continuous))
        }
        .padding(AuraSpacing.md)
    }

    private func toggleRow(label: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.auraLabelMd)
                    .foregroundColor(.auraOnSurface)
                Text(subtitle)
                    .font(.auraBodyMd)
                    .font(.system(size: 14))
                    .foregroundColor(.auraOnSurfaceVariant)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .tint(.auraPrimary)
        }
        .padding(AuraSpacing.md)
    }

    private func pickerRow(label: String, subtitle: String, selection: Binding<String>, options: [String]) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.auraLabelMd)
                    .foregroundColor(.auraOnSurface)
                Text(subtitle)
                    .font(.auraBodyMd)
                    .font(.system(size: 14))
                    .foregroundColor(.auraOnSurfaceVariant)
            }
            Spacer()
            Picker("", selection: selection) {
                ForEach(options, id: \.self) { opt in
                    Text(opt).tag(opt)
                }
            }
            .pickerStyle(.menu)
            .tint(.auraPrimary)
        }
        .padding(AuraSpacing.md)
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.auraLabelMd)
                .foregroundColor(.auraOnSurface)
            Spacer()
            Text(value)
                .font(.auraLabelSm)
                .foregroundColor(.auraOnSurfaceVariant)
        }
        .padding(AuraSpacing.md)
    }
}
