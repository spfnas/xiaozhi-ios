import SwiftUI

struct ContentView: View {
    @StateObject private var vm = ConversationViewModel()
    @State private var showSettings = false
    @State private var showTextInput = false
    @State private var textInput = ""

    var body: some View {
        ZStack {
            backgroundLayer
            decorativeBlobs
            stageContent
            messageOverlay
            VStack {
                topBar
                Spacer()
            }
            VStack {
                Spacer()
                bottomBar
            }
            if showTextInput {
                textInputOverlay
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack { SettingsView(vm: vm) }
        }
        .onAppear { vm.requestMic() }
        .animation(.interactiveSpring(), value: vm.messages.isEmpty)
    }

    // MARK: - Background
    private var backgroundLayer: some View {
        LinearGradient(
            colors: [.auraBgStart, .auraBgEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Decorative Blobs
    private var decorativeBlobs: some View {
        ZStack {
            Circle()
                .fill(Color.auraPrimaryContainer.opacity(0.25))
                .frame(width: 160, height: 160)
                .blur(radius: 50)
                .offset(x: -80, y: -120)
            Circle()
                .fill(Color.auraSecondaryContainer.opacity(0.2))
                .frame(width: 200, height: 200)
                .blur(radius: 60)
                .offset(x: 100, y: 160)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Stage Content
    private var stageContent: some View {
        VStack(spacing: 0) {
            Spacer()
            if vm.messages.isEmpty {
                VStack(spacing: 0) {
                    welcomeBubble
                    Spacer().frame(height: AuraSpacing.sm)
                    moodChip
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
            Spacer()
            characterView
                .padding(.bottom, 100)
        }
        .padding(.top, 80)
    }

    // MARK: - Welcome Bubble
    private var welcomeBubble: some View {
        Text("你好！我是小智。今天有什么可以帮你的吗？")
            .font(.auraBodyMd)
            .foregroundColor(.auraOnSurface)
            .multilineTextAlignment(.center)
            .padding(.horizontal, AuraSpacing.md)
            .padding(.vertical, AuraSpacing.sm)
            .glassCard()
            .shadow(color: Color(hex: "#8127cf").opacity(0.15), radius: 30, x: 0, y: 8)
            .frame(maxWidth: 280)
    }

    // MARK: - Mood Chip
    private var moodChip: some View {
        HStack(spacing: AuraSpacing.xs) {
            Text(assistantEmoji)
                .font(.system(size: 16))
            Text(emotionLabel)
                .font(.auraLabelSm)
                .foregroundColor(.auraPrimary)
        }
        .padding(.horizontal, AuraSpacing.sm)
        .padding(.vertical, AuraSpacing.xs)
        .glassCard()
    }

    private var emotionLabel: String {
        switch vm.emotion {
        case "happy": return "开心"
        case "sad": return "难过"
        case "angry": return "生气"
        case "surprised": return "惊讶"
        case "thinking": return "思考"
        default: return "愉快"
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

    // MARK: - Character
    private var characterView: some View {
        ZStack {
            Circle()
                .fill(Color.auraPrimaryContainer.opacity(0.3))
                .frame(width: 200, height: 200)
                .blur(radius: 30)

            Circle()
                .fill(
                    AngularGradient(
                        colors: [.auraPrimary, .auraSecondary, .auraPrimaryFixed, .auraPrimary],
                        center: .center
                    )
                )
                .frame(width: 140, height: 140)
                .shadow(color: .auraPrimary.opacity(0.3), radius: 20, y: 8)
                .scaleEffect(vm.state == .speaking ? 1.08 : 1.0)
                .animation(
                    .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                    value: vm.state == .speaking
                )

            Text(assistantEmoji)
                .font(.system(size: 64))
        }
    }

    // MARK: - Message Overlay
    private var messageOverlay: some View {
        Group {
            if !vm.messages.isEmpty {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: AuraSpacing.sm) {
                            ForEach(vm.messages) { msg in
                                MessageBubble(msg: msg)
                            }
                        }
                        .padding(.horizontal, AuraSpacing.containerPadding)
                        .padding(.vertical, AuraSpacing.sm)
                    }
                    .onChange(of: vm.messages.count) { _ in
                        if let last = vm.messages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }
                .padding(.top, 80)
                .padding(.bottom, 100)
                .transition(.opacity)
            }
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
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
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.auraOnSurfaceVariant)
            }
        }
        .padding(.horizontal, AuraSpacing.containerPadding)
        .frame(height: 64)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Color.white.opacity(0.3).frame(height: 1)
        }
    }

    // MARK: - Bottom Bar
    private var bottomBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // Keyboard / Text Input
                Button {
                    withAnimation(.spring()) { showTextInput.toggle() }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: showTextInput ? "keyboard.fill" : "keyboard")
                            .font(.system(size: 26))
                        Text("文字")
                            .font(.auraLabelSm)
                    }
                    .foregroundColor(showTextInput ? .auraPrimary : .auraOnSurfaceVariant)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

                // Mic Button
                Button {
                    if vm.state == .listening {
                        vm.stopAuto()
                    } else {
                        vm.startManualListening()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.auraPrimary)
                            .frame(width: 72, height: 72)
                            .shadow(color: .auraPrimary.opacity(0.4), radius: 16, x: 0, y: 4)
                        Image(systemName: vm.state == .listening ? "waveform" : "mic.fill")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .scaleEffect(vm.state == .listening ? 1.1 : 1.0)
                            .animation(
                                .easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                                value: vm.state == .listening
                            )
                    }
                }
                .offset(y: -20)

                // Call / Interrupt
                Button {
                    vm.interrupt()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: vm.state == .speaking ? "xmark.circle.fill" : "phone.fill")
                            .font(.system(size: 26))
                        Text(vm.state == .speaking ? "打断" : "通话")
                            .font(.auraLabelSm)
                    }
                    .foregroundColor(.auraOnSurfaceVariant)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, AuraSpacing.containerPadding)
            .padding(.top, 12)

            // Status text
            Text(hintText)
                .font(.auraLabelSm)
                .foregroundColor(.auraOnSurfaceVariant.opacity(0.7))
                .padding(.bottom, 8)
        }
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Color.white.opacity(0.3).frame(height: 1)
        }
    }

    // MARK: - Text Input Overlay
    private var textInputOverlay: some View {
        VStack {
            Spacer()
            HStack(spacing: AuraSpacing.sm) {
                TextField("输入消息...", text: $textInput)
                    .font(.auraBodyMd)
                    .padding(.horizontal, AuraSpacing.md)
                    .padding(.vertical, 12)
                    .glassCard()

                Button {
                    guard !textInput.isEmpty else { return }
                    vm.sendText(textInput)
                    textInput = ""
                    showTextInput = false
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.auraPrimary)
                }
            }
            .padding(.horizontal, AuraSpacing.containerPadding)
            .padding(.bottom, 120)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Hint Text
    private var hintText: String {
        switch vm.state {
        case .idle: return vm.isConnected ? "点击麦克风开始说话" : "请先在设置中激活"
        case .connecting: return "连接中..."
        case .listening: return "聆听中"
        case .processing: return "正在理解..."
        case .speaking: return "小智正在回复"
        case .error(let msg): return msg
        }
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let msg: ChatMessage
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if msg.role != .user {
                Circle()
                    .fill(Color.auraPrimary)
                    .frame(width: 30, height: 30)
                    .overlay(Text("🤖").font(.system(size: 16)))
            }
            Text(msg.text)
                .font(.auraBodyMd)
                .padding(12)
                .background(msg.role == .user ? Color.auraPrimary : .ultraThinMaterial)
                .foregroundColor(msg.role == .user ? .white : .auraOnSurface)
                .clipShape(RoundedRectangle(cornerRadius: AuraRadius.xxl, style: .continuous))
                .fixedSize(horizontal: false, vertical: true)
            if msg.role == .user { Spacer(minLength: 0) }
        }
        .frame(maxWidth: .infinity, alignment: msg.role == .user ? .trailing : .leading)
        .padding(.leading, msg.role == .user ? 40 : 0)
        .padding(.trailing, msg.role == .user ? 0 : 40)
    }
}
