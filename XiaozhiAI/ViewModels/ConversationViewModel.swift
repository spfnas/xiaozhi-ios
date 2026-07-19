import Foundation
import SwiftUI
import Combine

@MainActor
final class ConversationViewModel: ObservableObject {
    @Published var state: ConversationState = .idle
    @Published var messages: [ChatMessage] = []
    @Published var isConnected = false
    @Published var isAutoMode = false
    @Published var statusText: String = "未连接"
    @Published var emotion: String = "happy"
    @Published var config: XiaozhiConfig

    private var ws: WebSocketManager?
    private let audio = AudioManager()
    private var hasMicPermission = false

    init() {
        self.config = ConfigManager.shared.load()
        audio.delegate = self
        setupWebSocket()
    }

    private func setupWebSocket() {
        let ws = WebSocketManager(config: config)
        ws.delegate = self
        self.ws = ws
    }

    // MARK: - OTA 激活
    func activate() async {
        statusText = "正在激活..."
        do {
            let (wsUrl, token) = try await OtaService.shared.activate(
                otaUrl: config.otaUrl,
                deviceId: config.deviceId,
                clientId: config.clientId
            )
            config.websocketUrl = wsUrl
            config.token = token
            ConfigManager.shared.save(config)
            setupWebSocket()
            statusText = "激活成功，可开始对话"
        } catch {
            statusText = "激活失败: \(error.localizedDescription)"
        }
    }

    // MARK: - 权限
    func requestMic() {
        audio.requestPermission { [weak self] granted in
            self?.hasMicPermission = granted
            if !granted {
                self?.statusText = "需要麦克风权限才能语音对话"
            }
        }
    }

    // MARK: - 连接 + 对话控制
    func connect() {
        guard !config.websocketUrl.isEmpty else {
            statusText = "请先完成 OTA 激活"
            return
        }
        state = .connecting
        statusText = "连接中..."
        ws?.connect()
    }

    func startManualListening() {
        isAutoMode = false
        state = .listening
        audio.startRecording()
        ws?.sendStartListening(mode: "manual")
    }

    func startAutoConversation() {
        isAutoMode = true
        state = .listening
        audio.startRecording()
        ws?.sendStartListening(mode: "auto")
    }

    func stopAuto() {
        isAutoMode = false
        audio.stopRecording()
        ws?.sendStopListening()
        state = .idle
    }

    func sendText(_ text: String) {
        guard !text.isEmpty else { return }
        append(.user, text)
        ws?.sendText(text)
        state = .processing
    }

    func interrupt() {
        audio.stopPlaying()
        audio.stopRecording()
        ws?.sendAbort(reason: "user_interrupt")
        isAutoMode = false
        state = .idle
    }

    func disconnect() {
        ws?.disconnect()
        audio.stopAll()
        isAutoMode = false
        state = .idle
    }

    // MARK: - UI 辅助
    private func append(_ role: Role, _ text: String) {
        messages.append(ChatMessage(role: role, text: text, timestamp: Date()))
    }

    private func updateStatus() {
        switch state {
        case .idle: statusText = isConnected ? "已连接 (空闲)" : "未连接"
        case .connecting: statusText = "连接中..."
        case .listening: statusText = "聆听中..."
        case .processing: statusText = "思考中..."
        case .speaking: statusText = "回复中..."
        case .error(let msg): statusText = "错误: \(msg)"
        }
    }
}

// MARK: - WebSocket 回调
extension ConversationViewModel: WebSocketManagerDelegate {
    func onConnectionStateChanged(_ connected: Bool) {
        isConnected = connected
        if connected {
            state = .idle
        } else {
            state = .idle
            audio.stopAll()
        }
        updateStatus()
    }

    func onServerMessage(_ message: ServerMessage) {
        switch message.type {
        case .stt:
            if let text = message.text, !text.isEmpty {
                append(.user, text)
            }
        case .llm:
            if let emo = message.emotion, !emo.isEmpty {
                emotion = emo
            }
            if let text = message.text, !text.isEmpty {
                append(.assistant, text)
            }
        case .tts:
            switch message.state {
            case "sentence_start":
                if let text = message.text, !text.isEmpty {
                    append(.assistant, text)
                }
                state = .speaking
            case "start":
                state = .speaking
            case "stop":
                if isAutoMode {
                    // 自动模式: 进入下一轮聆听
                    state = .listening
                    audio.startRecording()
                    ws?.sendStartListening(mode: "auto")
                } else {
                    state = .idle
                }
            default:
                break
            }
        case .hello:
            break
        default:
            break
        }
        updateStatus()
    }

    func onBinaryAudio(_ data: Data) {
        // 仅在非聆听状态播放，避免回声
        if state != .listening {
            audio.playOpus(data)
        }
    }

    func onError(_ error: Error) {
        state = .error(error.localizedDescription)
        updateStatus()
    }
}

// MARK: - 录音回调
extension ConversationViewModel: AudioManagerDelegate {
    func onRecordedOpusFrame(_ data: Data) {
        guard state == .listening else { return }
        ws?.sendBinary(data)
    }
}
