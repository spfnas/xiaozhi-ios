import SwiftUI

struct ContentView: View {
    @StateObject private var vm = ConversationViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                // 豆包风格柔和渐变背景
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    topHeader
                    messageList
                    bottomBar
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView(vm: vm)) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .onAppear { vm.requestMic() }
    }

    // MARK: - 顶部助手头像 + 状态 (豆包风格)
    private var topHeader: some View {
        VStack(spacing: 8) {
            Spacer().frame(height: 8)
            // 助手头像 (圆形渐变 + 表情)
            ZStack {
                Circle()
                    .fill(
                        AngularGradient(colors: [.pink, .orange, .yellow, .pink],
                                        center: .center)
                    )
                    .frame(width: 88, height: 88)
                    .shadow(color: .black.opacity(0.12), radius: 8, y: 4)

                Text(assistantEmoji)
                    .font(.system(size: 44))
            }
            .scaleEffect(vm.state == .speaking ? 1.06 : 1.0)
            .animation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true), value: vm.state == .speaking)

            Text("小智")
                .font(.title2.bold())

            HStack(spacing: 6) {
                Circle()
                    .fill(vm.isConnected ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                Text(vm.statusText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer().frame(height: 12)
        }
    }

    private var assistantEmoji: String {
        switch vm.emotion {
        case "happy": return "😊"
        case "sad": return "😢"
        case "angry": return "😠"
        case "surprised": return "😲"
        case "thinking": return "🤔"
        default: return "🤖"
        }
    }

    // MARK: - 对话区
    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    ForEach(vm.messages) { msg in
                        MessageBubble(msg: msg)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .onChange(of: vm.messages.count) { _ in
                if let last = vm.messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    // MARK: - 底部操作区 (豆包: 大圆形麦克风 + 自动/打断)
    private var bottomBar: some View {
        VStack(spacing: 14) {
            HStack(spacing: 20) {
                // 自动对话
                smallButton(
                    title: vm.isAutoMode ? "停止" : "自动",
                    icon: vm.isAutoMode ? "stop.fill" : "repeat",
                    active: vm.isAutoMode
                ) {
                    if vm.isAutoMode { vm.stopAuto() } else { vm.startAutoConversation() }
                }

                // 大圆形麦克风 (主按钮)
                Button(action: {
                    if vm.state == .listening { vm.stopAuto() }
                    else { vm.startManualListening() }
                }) {
                    ZStack {
                        Circle()
                            .fill(vm.state == .listening ? Color.red : Color.white)
                            .frame(width: 76, height: 76)
                            .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
                        Image(systemName: vm.state == .listening ? "waveform" : "mic.fill")
                            .font(.system(size: 30, weight: .medium))
                            .foregroundColor(vm.state == .listening ? .white : .pink)
                    }
                }
                .scaleEffect(vm.state == .listening ? 1.08 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: vm.state)

                // 打断
                smallButton(title: "打断", icon: "xmark", active: false) {
                    vm.interrupt()
                }
            }
            Text(hintText)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer().frame(height: 8)
        }
        .padding(.top, 8)
        .background(.ultraThinMaterial)
    }

    private func smallButton(title: String, icon: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(active ? .white : .primary)
            .frame(width: 56, height: 56)
            .background(
                Circle().fill(active ? Color.pink.opacity(0.9) : Color(.tertiarySystemBackground))
            )
        }
    }

    private var hintText: String {
        switch vm.state {
        case .idle: return vm.isConnected ? "点击麦克风开始说话" : "请先在设置中激活"
        case .connecting: return "连接中..."
        case .listening: return "聆听中，点击麦克风停止"
        case .processing: return "正在理解..."
        case .speaking: return "小智正在回复"
        case .error: return "出错了"
        }
    }
}

struct MessageBubble: View {
    let msg: ChatMessage
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if msg.role != .user {
                Circle()
                    .fill(Color.pink.opacity(0.85))
                    .frame(width: 30, height: 30)
                    .overlay(Text("🤖").font(.system(size: 16)))
            }

            Text(msg.text)
                .padding(12)
                .background(msg.role == .user ? Color.pink : Color(.tertiarySystemBackground))
                .foregroundColor(msg.role == .user ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .fixedSize(horizontal: false, vertical: true)

            if msg.role == .user { Spacer(minLength: 0) }
        }
        .frame(maxWidth: .infinity, alignment: msg.role == .user ? .trailing : .leading)
        .padding(.leading, msg.role == .user ? 40 : 0)
        .padding(.trailing, msg.role == .user ? 0 : 40)
    }
}
