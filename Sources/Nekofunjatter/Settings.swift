import Foundation

enum PlayerKind: String, CaseIterable {
    case wav
    case eightBit
    case dubstep

    var displayName: String {
        switch self {
        case .wav:      return "ピアノ"
        case .eightBit: return "8bit 風"
        case .dubstep:  return "ダブステップ"
        }
    }
}

final class Settings {
    static let shared = Settings()

    private let defaults = UserDefaults.standard
    private enum Keys {
        static let playerKind = "playerKind"
        static let holdSeconds = "holdSeconds"
        static let thresholdKeys = "thresholdKeys"
        static let blockingEnabled = "blockingEnabled"
    }

    /// 選択肢 (UI からも参照)
    static let thresholdKeyChoices: [Int] = [2, 3, 4, 5]
    static let holdSecondChoices: [TimeInterval] = [0.3, 0.5, 1.0, 2.0]

    var playerKind: PlayerKind {
        get {
            guard let raw = defaults.string(forKey: Keys.playerKind),
                  let kind = PlayerKind(rawValue: raw) else {
                return .eightBit
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

    var thresholdKeys: Int {
        get {
            let v = defaults.integer(forKey: Keys.thresholdKeys)
            return v >= 2 ? v : 2
        }
        set { defaults.set(newValue, forKey: Keys.thresholdKeys) }
    }

    /// 猫検出中にキー入力をブロックするか (デフォルト ON)
    var blockingEnabled: Bool {
        get {
            // UserDefaults.bool は missing を false にしてしまうので object で存在確認
            if defaults.object(forKey: Keys.blockingEnabled) == nil { return true }
            return defaults.bool(forKey: Keys.blockingEnabled)
        }
        set { defaults.set(newValue, forKey: Keys.blockingEnabled) }
    }
}
