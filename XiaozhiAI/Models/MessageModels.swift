import Foundation

// MARK: - 对话消息 (UI 展示用)
enum Role: String, Codable {
    case user
    case assistant
    case system
}

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let role: Role
    let text: String
    let timestamp: Date
}

// MARK: - 云端 JSON 协议消息
enum ServerMessageType: String, Codable {
    case hello, stt, llm, tts, iot, abort
}

struct ServerMessage: Codable {
    let type: ServerMessageType?
    let transport: String?
    let sessionId: String?
    let text: String?
    let emotion: String?
    let state: String?
    let reason: String?
    let audioParams: AudioParams?

    enum CodingKeys: String, CodingKey {
        case type, transport, text, emotion, state, reason
        case sessionId = "session_id"
        case audioParams = "audio_params"
    }
}

struct AudioParams: Codable {
    let format: String?
    let sampleRate: Int?
    let channels: Int?
    let frameDuration: Int?

    enum CodingKeys: String, CodingKey {
        case format
        case sampleRate = "sample_rate"
        case channels
        case frameDuration = "frame_duration"
    }
}

// MARK: - 客户端发送消息构造
struct ClientMessage {
    static func hello() -> [String: Any] {
        return [
            "type": "hello",
            "version": 1,
            "transport": "websocket",
            "audio_params": [
                "format": "opus",
                "sample_rate": 16000,
                "channels": 1,
                "frame_duration": 60
            ]
        ]
    }

    static func listen(state: String, mode: String? = nil, sessionId: String? = nil) -> [String: Any] {
        var dict: [String: Any] = [
            "type": "listen",
            "state": state
        ]
        if let mode { dict["mode"] = mode }
        if let sessionId { dict["session_id"] = sessionId }
        return dict
    }

    static func wakeWordDetected(text: String, sessionId: String? = nil) -> [String: Any] {
        var dict: [String: Any] = [
            "type": "listen",
            "state": "detect",
            "text": text,
            "source": "text"
        ]
        if let sessionId { dict["session_id"] = sessionId }
        return dict
    }

    static func abort(reason: String, sessionId: String? = nil) -> [String: Any] {
        var dict: [String: Any] = [
            "type": "abort",
            "reason": reason
        ]
        if let sessionId { dict["session_id"] = sessionId }
        return dict
    }
}
