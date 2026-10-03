import AVFoundation

final class SoundManager {
    static let shared = SoundManager()

    private var players: [AVAudioPlayer] = []
    private var nextPlayerIndex = 0

    private init() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, options: [.mixWithOthers])

        let soundData = Self.makeWoodblockSound()
        players = (0..<5).compactMap { _ in
            guard let player = try? AVAudioPlayer(data: soundData) else { return nil }
            player.prepareToPlay()
            player.volume = 0.82
            return player
        }
    }

    func playWoodblock() {
        guard !players.isEmpty else { return }
        let player = players[nextPlayerIndex]
        player.currentTime = 0
        player.play()
        nextPlayerIndex = (nextPlayerIndex + 1) % players.count
    }

    private static func makeWoodblockSound() -> Data {
        let sampleRate = 44_100
        let duration = 0.28
        let sampleCount = Int(Double(sampleRate) * duration)
        var samples = [Int16]()
        samples.reserveCapacity(sampleCount)

        var noiseSeed: UInt32 = 0x5EED1234
        for index in 0..<sampleCount {
            let time = Double(index) / Double(sampleRate)
            let bodyDecay = exp(-time * 18.0)
            let highDecay = exp(-time * 38.0)

            let body = sin(2 * .pi * 620 * time) * 0.54
                + sin(2 * .pi * 1_070 * time) * 0.28
                + sin(2 * .pi * 1_730 * time) * 0.14

            noiseSeed = 1_664_525 &* noiseSeed &+ 1_013_904_223
            let noise = (Double(noiseSeed) / Double(UInt32.max) * 2 - 1)
            let click = time < 0.018 ? noise * highDecay * 0.22 : 0
            let attack = min(1, time / 0.0025)
            let value = max(-1, min(1, (body * bodyDecay + click) * attack))
            samples.append(Int16(value * Double(Int16.max)))
        }

        var data = Data()
        let bytesPerSample: UInt16 = 2
        let dataSize = UInt32(samples.count) * UInt32(bytesPerSample)

        data.appendASCII("RIFF")
        data.appendLittleEndian(UInt32(36) + dataSize)
        data.appendASCII("WAVE")
        data.appendASCII("fmt ")
        data.appendLittleEndian(UInt32(16))
        data.appendLittleEndian(UInt16(1))
        data.appendLittleEndian(UInt16(1))
        data.appendLittleEndian(UInt32(sampleRate))
        data.appendLittleEndian(UInt32(sampleRate) * UInt32(bytesPerSample))
        data.appendLittleEndian(bytesPerSample)
        data.appendLittleEndian(UInt16(16))
        data.appendASCII("data")
        data.appendLittleEndian(dataSize)
        for sample in samples {
            data.appendLittleEndian(sample)
        }
        return data
    }
}

private extension Data {
    mutating func appendASCII(_ string: String) {
        append(contentsOf: string.utf8)
    }

    mutating func appendLittleEndian<T: FixedWidthInteger>(_ value: T) {
        var littleEndianValue = value.littleEndian
        Swift.withUnsafeBytes(of: &littleEndianValue) { append(contentsOf: $0) }
    }
}
