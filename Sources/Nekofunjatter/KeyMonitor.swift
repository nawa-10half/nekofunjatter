import AppKit
import CoreGraphics

final class KeyMonitor {
    typealias KeyHandler = (Int64) -> Void

    private let onKeyDown: KeyHandler
    private let onKeyUp: KeyHandler
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    /// true の間、keyDown と flagsChanged を吸収する (アプリには届かない)。
    /// keyUp は常に通すので「全キー解放」検知は維持される。
    /// 1 bit の読み書きは atomic なので、CGEventTap コールバック側からの参照と
    /// メインスレッドからの代入のレースは無視できる。
    var isBlocking: Bool = false

    init(onKeyDown: @escaping KeyHandler, onKeyUp: @escaping KeyHandler) {
        self.onKeyDown = onKeyDown
        self.onKeyUp = onKeyUp
    }

    func start() {
        ensureAccessibilityPermission { [weak self] granted in
            guard let self else { return }
            if granted {
                self.installEventTap()
            } else {
                self.showPermissionAlert()
            }
        }
    }

    private func ensureAccessibilityPermission(completion: @escaping (Bool) -> Void) {
        let trusted = AXIsProcessTrusted()
        if trusted {
            completion(true)
            return
        }
        let opts: [String: Any] = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(opts as CFDictionary)

        let timer = Timer(timeInterval: 1.0, repeats: true) { t in
            if AXIsProcessTrusted() {
                t.invalidate()
                completion(true)
            }
        }
        RunLoop.main.add(timer, forMode: .common)
    }

    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "アクセシビリティ権限が必要です"
        alert.informativeText = "猫の踏み打ち検知のため、システム設定 → プライバシーとセキュリティ → アクセシビリティ で Nekofunjatter を許可してください。許可後、自動的に監視が始まります。"
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    static func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    private func installEventTap() {
        // .flagsChanged も含める: ブロック中に修飾キーが「押しっぱなし」状態で
        // フォーカスアプリに残るのを防ぐため
        let mask: CGEventMask = (1 << CGEventType.keyDown.rawValue)
                              | (1 << CGEventType.keyUp.rawValue)
                              | (1 << CGEventType.flagsChanged.rawValue)

        let userInfo = Unmanaged.passUnretained(self).toOpaque()

        let callback: CGEventTapCallBack = { _, type, event, refcon -> Unmanaged<CGEvent>? in
            guard let refcon else { return Unmanaged.passUnretained(event) }
            let monitor = Unmanaged<KeyMonitor>.fromOpaque(refcon).takeUnretainedValue()
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            switch type {
            case .keyDown:
                DispatchQueue.main.async { monitor.onKeyDown(keyCode) }
                if monitor.isBlocking { return nil }   // フォーカスアプリに渡さない
            case .keyUp:
                DispatchQueue.main.async { monitor.onKeyUp(keyCode) }
                // keyUp は常に通す (release 検知 + orphan keyUp は無害)
            case .flagsChanged:
                if monitor.isBlocking { return nil }
            case .tapDisabledByTimeout, .tapDisabledByUserInput:
                if let tap = monitor.eventTap {
                    CGEvent.tapEnable(tap: tap, enable: true)
                }
            default:
                break
            }
            return Unmanaged.passUnretained(event)
        }

        // .defaultTap: コールバックの戻り値で event の通過/破棄を制御できる
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: userInfo
        ) else {
            NSLog("CGEvent.tapCreate failed (権限不足の可能性)")
            return
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        self.eventTap = tap
        self.runLoopSource = source
    }
}
