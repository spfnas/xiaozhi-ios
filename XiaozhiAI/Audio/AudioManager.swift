import Foundation
import AVFoundation

// MARK: - 音频管理: 录音 (PCM) + 播放 (PCM)
// 录音: AVAudioEngine 输入 -> 转为 16k mono Float32 -> Opus 编码 -> 回调
// 播放: Opus 解码 -> 16k mono Float32 -> AVAudioEngine 输出

protocol AudioManagerDelegate: AnyObject {
    func onRecordedOpusFrame(_ data: Data)
}

final class AudioManager {
    weak var delegate: AudioManagerDelegate?

    private let engine = AVAudioEngine()
    private var codec: OpusCodec?
    private var inputNode: AVAudioNode?
    private var playerNode: AVAudioPlayerNode?
    private let playerFormat: AVAudioFormat
    private var isRecording = false

    // 重采样/格式转换
    private var converter: AVAudioConverter?

    init() {
        self.codec = OpusCodec()
        let hwFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                     sampleRate: 16000,
                                     channels: 1,
                                     interleaved: false)!
        self.playerFormat = hwFormat
    }

    // MARK: - 权限
    func requestPermission(completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    // MARK: - 配置 session
    private func configureSession(forRecording record: Bool) {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord,
                                    mode: .voiceChat,
                                    options: [.defaultToSpeaker, .allowBluetooth])
            try session.setPreferredSampleRate(16000)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("AVAudioSession config error: \(error)")
        }
    }

    // MARK: - 开始录音
    func startRecording() {
        guard let codec else { return }
        configureSession(forRecording: true)
        engine.stop()
        engine.reset()

        let input = engine.inputNode
        let inputFormat = input.outputFormat(forBus: 0)

        // 目标格式: 16k mono float32
        let targetFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                         sampleRate: 16000,
                                         channels: 1,
                                         interleaved: false)!
        converter = AVAudioConverter(from: inputFormat, to: targetFormat)

        input.installTap(onBus: 0, bufferSize: 2048, format: inputFormat) { [weak self] buffer, _ in
            guard let self, self.isRecording else { return }
            self.processInputBuffer(buffer, targetFormat: targetFormat, codec: codec)
        }

        engine.prepare()
        do {
            try engine.start()
            isRecording = true
        } catch {
            print("engine start error: \(error)")
        }
    }

    private func processInputBuffer(_ buffer: AVAudioPCMBuffer, targetFormat: AVAudioFormat, codec: OpusCodec) {
        guard let converter else { return }
        let capacity = AVAudioFrameCount(OpusCodec.frameSize)
        guard let outBuf = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: capacity) else { return }

        var error: NSError?
        var consumed = false
        converter.convert(to: outBuf, error: &error) { _, statusPtr in
            if consumed {
                statusPtr.pointee = .noDataNow
                return nil
            }
            consumed = true
            statusPtr.pointee = .haveData
            return buffer
        }
        if let error { print("convert error: \(error)"); return }

        guard let floatData = outBuf.floatChannelData else { return }
        let frames = Int(outBuf.frameLength)
        guard frames == Int(OpusCodec.frameSize) else { return }
        let pcm = Array(UnsafeBufferPointer(start: floatData[0], count: frames))
        if let opusData = codec.encode(pcm) {
            delegate?.onRecordedOpusFrame(opusData)
        }
    }

    func stopRecording() {
        isRecording = false
        engine.inputNode.removeTap(onBus: 0)
    }

    // MARK: - 播放
    func playOpus(_ data: Data) {
        guard let codec else { return }
        guard let pcm = codec.decode(data) else { return }
        if playerNode == nil {
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: playerFormat)
            playerNode = node
        }
        guard let player = playerNode else { return }

        let frameCapacity = AVAudioFrameCount(pcm.count)
        guard let buf = AVAudioPCMBuffer(pcmFormat: playerFormat, frameCapacity: frameCapacity) else { return }
        buf.frameLength = frameCapacity
        if let floatData = buf.floatChannelData {
            for i in 0..<pcm.count {
                floatData[0][i] = pcm[i]
            }
        }

        if !engine.isRunning {
            engine.prepare()
            try? engine.start()
        }
        if !player.isPlaying { player.play() }
        player.scheduleBuffer(buf, completionHandler: nil)
    }

    func stopPlaying() {
        playerNode?.stop()
    }

    // MARK: - 停止全部
    func stopAll() {
        stopRecording()
        stopPlaying()
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
