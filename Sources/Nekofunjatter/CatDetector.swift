import CoreGraphics
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
    /// キーが物理的に押されているか。Secure Input 中などは tap に keyUp が届かないので、
    /// この関数で照合して取りこぼしたキーを pressedKeys から除く。
    private let isKeyPhysicallyDown: (Int64) -> Bool

    init(
        thresholdKeys: Int,
        holdDuration: TimeInterval,
        onTrigger: @escaping () -> Void,
        onRelease: @escaping () -> Void,
        isKeyPhysicallyDown: @escaping (Int64) -> Bool = { keyCode in
            CGEventSource.keyState(.combinedSessionState, key: CGKeyCode(keyCode))
        }
    ) {
        self.thresholdKeys = thresholdKeys
        self.holdDuration = holdDuration
        self.onTrigger = onTrigger
        self.onRelease = onRelease
        self.isKeyPhysicallyDown = isKeyPhysicallyDown
    }

    func keyDown(_ keyCode: Int64) {
        pressedKeys.insert(keyCode)
        evaluate()
    }

    func keyUp(_ keyCode: Int64) {
        pressedKeys.remove(keyCode)
        // 取りこぼしたキーが残っていると全キー解放を検知できず、ブロックが解けない
        pruneReleasedKeys()
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
            self.pruneReleasedKeys()
            if self.pressedKeys.count >= self.thresholdKeys {
                self.hasFired = true
                self.onTrigger()
            }
        }
        // .common モードに登録 (default のみだとメニュー操作中などに止まる)
        RunLoop.main.add(timer, forMode: .common)
        holdTimer = timer
    }

    /// keyUp を取りこぼして押下扱いのまま残っているキーを除く
    private func pruneReleasedKeys() {
        pressedKeys = pressedKeys.filter(isKeyPhysicallyDown)
    }

    private func cancelTimer() {
        holdTimer?.invalidate()
        holdTimer = nil
    }
}
