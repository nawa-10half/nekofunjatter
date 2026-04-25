import Foundation
import AVFoundation

/// バンドル同梱の音声ファイル (WAV / MP3 など) をループ再生するプレイヤー。
final class WavPlayer: Player {
    private var audioPlayer: AVAudioPlayer?

    init(resourceName: String, fileExtension: String = "wav") {
        guard let url = Self.resourceURL(name: resourceName, extension: fileExtension) else {
            NSLog("WavPlayer: \(resourceName).\(fileExtension) が見つかりません")
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

    private static func resourceURL(name: String, extension ext: String) -> URL? {
        if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Audio") {
            return url
        }
        return Bundle.main.url(forResource: name, withExtension: ext)
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
