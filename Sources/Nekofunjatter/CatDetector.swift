import Foundation

/// 「猫が乗った」検知ロジック。
/// しきい値以上のキーが holdDuration 以上押し続けられたら onTrigger を発火。
/// 全キー解放時 (発火後のみ) は onRelease を呼ぶ。
final class CatDetector {
    private let thresholdKeys: Int
    private let holdDuration: TimeInterval
    private let onTrigger: () -> Void
    private let onRelease: () -> Void

    private var pressedKeys: Set<Int64> = []
    private var holdTimer: Timer?
    private var hasFired: Bool = false

    init(
        thresholdKeys: Int,
        holdDuration: TimeInterval,
        onTrigger: @escaping () -> Void,
        onRelease: @escaping () -> Void
    ) {
        self.thresholdKeys = thresholdKeys
        self.holdDuration = holdDuration
        self.onTrigger = onTrigger
        self.onRelease = onRelease
    }

    func keyDown(_ keyCode: Int64) {
        pressedKeys.insert(keyCode)
        evaluate()
    }

    func keyUp(_ keyCode: Int64) {
        pressedKeys.remove(keyCode)
        if pressedKeys.count < thresholdKeys {
            cancelTimer()
        }
        if pressedKeys.isEmpty {
            if hasFired {
                onRelease()
            }
            hasFired = false
        }
    }

    private func evaluate() {
        guard !hasFired else { return }
        guard pressedKeys.count >= thresholdKeys else { return }
        guard holdTimer == nil else { return }

        let timer = Timer(timeInterval: holdDuration, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.holdTimer = nil
            if self.pressedKeys.count >= self.thresholdKeys {
                self.hasFired = true
                self.onTrigger()
            }
        }
        // .common モードに登録 (default のみだとメニュー操作中などに止まる)
        RunLoop.main.add(timer, forMode: .common)
        holdTimer = timer
    }

    private func cancelTimer() {
        holdTimer?.invalidate()
        holdTimer = nil
    }
}
