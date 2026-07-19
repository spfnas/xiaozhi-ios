import Foundation

struct XiaozhiConfig: Codable {
    var otaUrl: String
    var websocketUrl: String
    var token: String
    var deviceId: String
    var clientId: String

    static let `default` = XiaozhiConfig(
        otaUrl: "https://api.tenclass.net/xiaozhi/ota/",
        websocketUrl: "",
        token: "",
        deviceId: "",
        clientId: UUID().uuidString
    )
}

final class ConfigManager {
    static let shared = ConfigManager()
    private let fileURL: URL

    private init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        self.fileURL = dir.appendingPathComponent("xiaozhi_config.json")
    }

    func load() -> XiaozhiConfig {
        guard let data = try? Data(contentsOf: fileURL),
              let cfg = try? JSONDecoder().decode(XiaozhiConfig.self, from: data) else {
            var cfg = XiaozhiConfig.default
            if cfg.deviceId.isEmpty {
                cfg.deviceId = Self.macAddressFallback()
            }
            return cfg
        }
        var cfg = cfg
        if cfg.deviceId.isEmpty { cfg.deviceId = Self.macAddressFallback() }
        if cfg.clientId.isEmpty { cfg.clientId = UUID().uuidString }
        return cfg
    }

    func save(_ cfg: XiaozhiConfig) {
        guard let data = try? JSONEncoder().encode(cfg) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    // iOS 无法获取真实 MAC，用 identifierForVendor 或 UUID 代替
    private static func macAddressFallback() -> String {
        if let vendor = UIDevice.current.identifierForVendor?.uuidString {
            return vendor.replacingOccurrences(of: "-", with: "")
        }
        return UUID().uuidString.replacingOccurrences(of: "-", with: "")
    }
}
