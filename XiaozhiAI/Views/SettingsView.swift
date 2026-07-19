import SwiftUI

struct SettingsView: View {
    @ObservedObject var vm: ConversationViewModel
    @State private var otaUrl: String
    @State private var websocketUrl: String
    @State private var token: String

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
                VStack(spacing: 18) {
                    headerCard
                    configCard
                    actionButtons
                    tipCard
                }
                .padding(16)
            }
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerCard: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(AngularGradient(colors: [.pink, .orange, .yellow, .pink], center: .center))
                .frame(width: 56, height: 56)
                .overlay(Text("🤖").font(.system(size: 28)))
            VStack(alignment: .leading, spacing: 4) {
                Text("小智 AI")
                    .font(.headline)
                Text("实时语音对话客户端")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var configCard: some View {
        VStack(spacing: 0) {
            row("OTA 地址", text: $otaUrl, placeholder: "https://api.tenclass.net/xiaozhi/ota/")
            Divider().padding(.leading, 16)
            row("WebSocket", text: $websocketUrl, placeholder: "激活后自动填充")
            Divider().padding(.leading, 16)
            row("Token", text: $token, placeholder: "激活后自动填充", secure: true)
            Divider().padding(.leading, 16)
            HStack {
                Text("Device-Id")
                    .foregroundColor(.secondary)
                Spacer()
                Text(vm.config.deviceId.prefix(12) + "...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func row(_ title: String, text: Binding<String>, placeholder: String, secure: Bool = false) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
                .frame(width: 72, alignment: .leading)
            if secure {
                SecureField(placeholder, text: text)
            } else {
                TextField(placeholder, text: text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }
        .padding(16)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                vm.config.otaUrl = otaUrl
                vm.config.websocketUrl = websocketUrl
                vm.config.token = token
                ConfigManager.shared.save(vm.config)
            } label: {
                Text("保存配置")
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            Button {
                vm.config.otaUrl = otaUrl
                Task { await vm.activate() }
            } label: {
                Text("通过 OTA 激活")
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .foregroundColor(.white)
                    .background(Color.pink)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    private var tipCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("使用提示", systemImage: "lightbulb.fill")
                .font(.subheadline.bold())
                .foregroundColor(.pink)
            Text("默认 OTA 地址: https://api.tenclass.net/xiaozhi/ota/")
                .font(.caption)
                .foregroundColor(.secondary)
            Text("激活成功后返回主页，点击底部麦克风即可开始对话。")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
