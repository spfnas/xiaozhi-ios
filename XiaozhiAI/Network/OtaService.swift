import Foundation

// MARK: - OTA 响应模型 (对齐小智官方 OTA 接口)
struct OtaResponse: Codable {
    let code: Int?
    let message: String?
    let data: OtaData?
}

struct OtaData: Codable {
    let version: String?
    let websocketUrl: String?
    let token: String?

    enum CodingKeys: String, CodingKey {
        case version
        case websocketUrl = "websocket_url"
        case token
    }
}

// MARK: - OTA 服务
final class OtaService {
    static let shared = OtaService()
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        self.session = URLSession(configuration: config)
    }

    /// 向 OTA 地址请求激活，返回 websocket url + token
    func activate(otaUrl: String, deviceId: String, clientId: String) async throws -> (websocketUrl: String, token: String) {
        guard var components = URLComponents(string: otaUrl) else {
            throw OtaError.invalidUrl
        }
        components.queryItems = [
            URLQueryItem(name: "device_id", value: deviceId),
            URLQueryItem(name: "client_id", value: clientId)
        ]
        guard let url = components.url else { throw OtaError.invalidUrl }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw OtaError.httpError
        }

        let decoded = try JSONDecoder().decode(OtaResponse.self, from: data)
        guard let d = decoded.data,
              let ws = d.websocketUrl, !ws.isEmpty,
              let token = d.token, !token.isEmpty else {
            throw OtaError.invalidResponse
        }
        return (ws, token)
    }

    enum OtaError: Error {
        case invalidUrl
        case httpError
        case invalidResponse
    }
}
