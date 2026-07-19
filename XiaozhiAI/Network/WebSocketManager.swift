import Foundation

// MARK: - 对话状态
enum ConversationState: Equatable {
    case idle
    case connecting
    case listening
    case processing
    case speaking
    case error(String)
}

// MARK: - WebSocket 事件回调
protocol WebSocketManagerDelegate: AnyObject {
    func onConnectionStateChanged(_ connected: Bool)
    func onServerMessage(_ message: ServerMessage)
    func onBinaryAudio(_ data: Data)
    func onError(_ error: Error)
}

final class WebSocketManager {
    weak var delegate: WebSocketManagerDelegate?

    private var task: URLSessionWebSocketTask?
    private var session: URLSession!
    private var isHandshakeComplete = false
    private var sessionId: String?
    private var handshakeTimer: Timer?
    private let handshakeTimeout: TimeInterval = 10

    private let config: XiaozhiConfig
    private let queue = DispatchQueue(label: "com.xiaozhi.ws")

    init(config: XiaozhiConfig) {
        self.config = config
        self.session = URLSession(configuration: .default, delegate: nil, delegateQueue: nil)
    }

    // MARK: - 连接 + 握手
    func connect() {
        guard let url = URL(string: config.websocketUrl) else {
            delegate?.onError(NSError(domain: "ws", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的 WebSocket 地址"]))
            return
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(config.token)", forHTTPHeaderField: "Authorization")
        request.setValue("1", forHTTPHeaderField: "Protocol-Version")
        request.setValue(config.deviceId, forHTTPHeaderField: "Device-Id")
        request.setValue(config.clientId, forHTTPHeaderField: "Client-Id")

        task = session.webSocketTask(with: request)
        task?.resume()
        isHandshakeComplete = false
        receiveLoop()
        sendHello()
        startHandshakeTimer()
    }

    private func sendHello() {
        send(json: ClientMessage.hello())
    }

    private func startHandshakeTimer() {
        handshakeTimer?.invalidate()
        handshakeTimer = Timer.scheduledTimer(withTimeInterval: handshakeTimeout, repeats: false) { [weak self] _ in
            guard let self, !self.isHandshakeComplete else { return }
            self.delegate?.onError(NSError(domain: "ws", code: -2, userInfo: [NSLocalizedDescriptionKey: "握手超时，无法连接服务"]))
            self.disconnect()
        }
    }

    // MARK: - 接收循环
    private func receiveLoop() {
        task?.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                self.delegate?.onError(error)
                self.delegate?.onConnectionStateChanged(false)
                return
            case .success(let message):
                self.handle(message)
                self.receiveLoop()
            }
        }
    }

    private func handle(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            guard let data = text.data(using: .utf8),
                  let msg = try? JSONDecoder().decode(ServerMessage.self, from: data) else {
                return
            }
            if msg.type == .hello {
                if msg.transport == "websocket" {
                    isHandshakeComplete = true
                    sessionId = msg.sessionId
                    handshakeTimer?.invalidate()
                    delegate?.onConnectionStateChanged(true)
                }
                delegate?.onServerMessage(msg)
            } else {
                delegate?.onServerMessage(msg)
            }
        case .data(let data):
            delegate?.onBinaryAudio(data)
        @unknown default:
            break
        }
    }

    // MARK: - 发送
    func send(json: [String: Any]) {
        guard isHandshakeComplete else { return }
        guard let data = try? JSONSerialization.data(withJSONObject: json),
              let str = String(data: data, encoding: .utf8) else { return }
        task?.send(.string(str)) { [weak self] error in
            if let error { self?.delegate?.onError(error) }
        }
    }

    func sendBinary(_ data: Data) {
        guard isHandshakeComplete else { return }
        task?.send(.data(data)) { [weak self] error in
            if let error { self?.delegate?.onError(error) }
        }
    }

    // MARK: - 业务封装
    func sendStartListening(mode: String = "auto") {
        send(json: ClientMessage.listen(state: "start", mode: mode, sessionId: sessionId))
    }

    func sendStopListening() {
        send(json: ClientMessage.listen(state: "stop", sessionId: sessionId))
    }

    func sendText(_ text: String) {
        send(json: ClientMessage.wakeWordDetected(text: text, sessionId: sessionId))
    }

    func sendAbort(reason: String = "user_interrupt") {
        send(json: ClientMessage.abort(reason: reason, sessionId: sessionId))
    }

    // MARK: - 断开
    func disconnect() {
        handshakeTimer?.invalidate()
        task?.cancel(with: .goingAway, reason: nil)
        isHandshakeComplete = false
        delegate?.onConnectionStateChanged(false)
    }
}
