import Foundation

// 对 libopus 的 Swift 封装。
// 编码: PCM (Float32, 16k, mono) -> Opus 二进制帧
// 解码: Opus 二进制帧 -> PCM (Float32, 16k, mono)
// 链接: 编译时通过 libopus.a 静态库 (见 GitHub Actions / build_opus.sh)

final class OpusCodec {
    static let sampleRate: Int32 = 16000
    static let channels: Int32 = 1
    static let frameDurationMs: Int32 = 60
    static let frameSize: Int32 = sampleRate * frameDurationMs / 1000 // 960 samples

    private var encoder: OpaquePointer?
    private var decoder: OpaquePointer?

    init?() {
        var error: Int32 = 0

        guard let enc = opus_encoder_create(OpusCodec.sampleRate, OpusCodec.channels, OPUS_APPLICATION_VOIP, &error),
              error == OPUS_OK else {
            return nil
        }
        encoder = enc

        guard let dec = opus_decoder_create(OpusCodec.sampleRate, OpusCodec.channels, &error),
              error == OPUS_OK else {
            opus_encoder_destroy(enc)
            return nil
        }
        decoder = dec
    }

    deinit {
        if let encoder { opus_encoder_destroy(encoder) }
        if let decoder { opus_decoder_destroy(decoder) }
    }

    /// PCM Float32 -> Opus Data
    func encode(_ pcm: [Float]) -> Data? {
        guard let encoder else { return nil }
        var out = [UInt8](repeating: 0, count: 4000)
        let rc = opus_encode_float(encoder, pcm, OpusCodec.frameSize, &out, Int32(out.count))
        guard rc > 0 else { return nil }
        return Data(out.prefix(Int(rc)))
    }

    /// Opus Data -> PCM Float32
    func decode(_ data: Data) -> [Float]? {
        guard let decoder else { return nil }
        var pcm = [Float](repeating: 0, count: Int(OpusCodec.frameSize))
        let rc = data.withUnsafeBytes { ptr in
            opus_decode_float(decoder, ptr.bindMemory(to: UInt8.self).baseAddress, Int32(data.count), &pcm, OpusCodec.frameSize, 0)
        }
        guard rc > 0 else { return nil }
        return Array(pcm.prefix(Int(rc)))
    }
}
