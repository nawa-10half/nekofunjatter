import Foundation

enum PlayerKind: String, CaseIterable {
    case wav
    case eightBit

    var displayName: String {
        switch self {
        case .wav:      return "ピアノ"
        case .eightBit: return "8bit 風"
        }
    }
}

final class Settings {
    static let shared = Settings()

    private let defaults = UserDefaults.standard
    private enum Keys {
        static let playerKind = "playerKind"
        static let holdSeconds = "holdSeconds"
    }

    var playerKind: PlayerKind {
        get {
            guard let raw = defaults.string(forKey: Keys.playerKind),
                  let kind = PlayerKind(rawValue: raw) else {
                return .wav
            }
            return kind
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.playerKind) }
    }

    var holdSeconds: TimeInterval {
        get {
            let v = defaults.double(forKey: Keys.holdSeconds)
            return v > 0 ? v : 0.5
        }
        set { defaults.set(newValue, forKey: Keys.holdSeconds) }
    }
}
