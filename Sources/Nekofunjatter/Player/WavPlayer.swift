import Foundation
import AVFoundation

/// バンドル同梱の WAV ファイルをループ再生するプレイヤー。
final class WavPlayer: Player {
    private var audioPlayer: AVAudioPlayer?

    init(resourceName: String) {
        guard let url = Self.resourceURL(name: resourceName) else {
            NSLog("WavPlayer: \(resourceName).wav が見つかりません")
            return
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1   // 無限ループ
            player.prepareToPlay()
            player.volume = 1.0
            self.audioPlayer = player
        } catch {
            NSLog("WavPlayer: AVAudioPlayer init failed: \(error)")
        }
    }

    private static func resourceURL(name: String) -> URL? {
        if let url = Bundle.main.url(forResource: name, withExtension: "wav", subdirectory: "Audio") {
            return url
        }
        return Bundle.main.url(forResource: name, withExtension: "wav")
    }

    func play() {
        guard let player = audioPlayer else { return }
        player.currentTime = 0
        player.play()
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
    }
}
