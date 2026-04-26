import AppKit

final class MenuBarController: NSObject {
    /// メニューバー用の肉球 (2 つ) アイコンを返す。
    /// バンドル同梱の PDF を template image として読み込み、
    /// ダーク/ライトモードで自動的に色が反転する。
    private static func menuBarIcon() -> NSImage? {
        let url = Bundle.main.url(forResource: "pawprints", withExtension: "pdf", subdirectory: "Icons")
            ?? Bundle.main.url(forResource: "pawprints", withExtension: "pdf")
        if let url, let image = NSImage(contentsOf: url) {
            image.isTemplate = true
            image.size = NSSize(width: 18, height: 18)
            return image
        }
        // フォールバック: SF Symbols の単一肉球
        let fallback = NSImage(systemSymbolName: "pawprint.fill", accessibilityDescription: "Nekofunjatter")
        fallback?.isTemplate = true
        return fallback
    }

    private let statusItem: NSStatusItem
    private let onSelectPlayer: (PlayerKind) -> Void
    private let onPickCustomAudio: () -> Void
    private let onClearCustomAudio: () -> Void
    private let onStartPreview: () -> Void
    private let onStopPreview: () -> Void
    private let onForceStop: () -> Void
    private let onDetectionSettingsChanged: () -> Void
    private let onToggleAutoLaunch: () -> Void
    private let isAutoLaunchEnabled: () -> Bool
    private let onOpenAccessibilitySettings: () -> Void
    private let onQuit: () -> Void

    private var isPreviewing: Bool = false

    init(
        onSelectPlayer: @escaping (PlayerKind) -> Void,
        onPickCustomAudio: @escaping () -> Void,
        onClearCustomAudio: @escaping () -> Void,
        onStartPreview: @escaping () -> Void,
        onStopPreview: @escaping () -> Void,
        onForceStop: @escaping () -> Void,
        onDetectionSettingsChanged: @escaping () -> Void,
        onToggleAutoLaunch: @escaping () -> Void,
        isAutoLaunchEnabled: @escaping () -> Bool,
        onOpenAccessibilitySettings: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.onSelectPlayer = onSelectPlayer
        self.onPickCustomAudio = onPickCustomAudio
        self.onClearCustomAudio = onClearCustomAudio
        self.onStartPreview = onStartPreview
        self.onStopPreview = onStopPreview
        self.onForceStop = onForceStop
        self.onDetectionSettingsChanged = onDetectionSettingsChanged
        self.onToggleAutoLaunch = onToggleAutoLaunch
        self.isAutoLaunchEnabled = isAutoLaunchEnabled
        self.onOpenAccessibilitySettings = onOpenAccessibilitySettings
        self.onQuit = onQuit
        super.init()

        if let button = statusItem.button {
            button.image = Self.menuBarIcon()
            button.toolTip = "Nekofunjatter"
        }

        rebuildMenu()
    }

    private func rebuildMenu() {
        let menu = NSMenu()
        let s = Settings.shared

        // ── 再生コントロール ──
        let previewTitle = isPreviewing ? "プレビュー停止" : "プレビュー再生"
        menu.addItem(makeItem(title: previewTitle, action: #selector(previewTapped)))
        menu.addItem(makeItem(title: "今すぐ停止 (キーブロック解除)", action: #selector(forceStopTapped)))
        menu.addItem(.separator())

        // ── 音源 ──
        menu.addItem(disabledHeader("音源"))
        for kind in [PlayerKind.wav, .eightBit] {
            let item = makeItem(title: kind.displayName, action: #selector(selectPlayer(_:)))
            item.representedObject = kind.rawValue
            item.state = (kind == s.playerKind) ? .on : .off
            menu.addItem(item)
        }
        if let url = s.customAudioURL {
            let item = makeItem(title: url.lastPathComponent, action: #selector(selectPlayer(_:)))
            item.representedObject = PlayerKind.custom.rawValue
            item.state = (s.playerKind == .custom) ? .on : .off
            item.toolTip = url.path
            menu.addItem(item)
        }
        menu.addItem(makeItem(title: "カスタム音源を選択…", action: #selector(pickCustomAudioTapped)))
        if s.customAudioURL != nil {
            menu.addItem(makeItem(title: "カスタム音源の選択を解除", action: #selector(clearCustomAudioTapped)))
        }
        menu.addItem(.separator())

        // ── 発動条件 ──
        menu.addItem(disabledHeader("発動条件"))

        // 発動キー数 (サブメニュー)
        let keyCountItem = NSMenuItem(title: "同時押しキー数: \(s.thresholdKeys) キー", action: nil, keyEquivalent: "")
        keyCountItem.submenu = makeKeyCountSubmenu(current: s.thresholdKeys)
        menu.addItem(keyCountItem)

        // 発動までの時間 (サブメニュー)
        let holdItem = NSMenuItem(title: String(format: "ホールド時間: %.1f 秒", s.holdSeconds), action: nil, keyEquivalent: "")
        holdItem.submenu = makeHoldSecondsSubmenu(current: s.holdSeconds)
        menu.addItem(holdItem)

        // ブロック ON/OFF
        let blockItem = makeItem(title: "猫検出中にキー入力をブロック", action: #selector(toggleBlocking))
        blockItem.state = s.blockingEnabled ? .on : .off
        menu.addItem(blockItem)

        menu.addItem(.separator())

        let autoLaunch = makeItem(title: "ログイン時に起動", action: #selector(toggleAutoLaunch))
        autoLaunch.state = isAutoLaunchEnabled() ? .on : .off
        menu.addItem(autoLaunch)

        menu.addItem(makeItem(title: "アクセシビリティ設定を開く…", action: #selector(openAccessibility)))
        menu.addItem(.separator())
        menu.addItem(makeItem(title: "Nekofunjatter を終了", action: #selector(quitTapped), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    // MARK: - Submenus

    private func makeKeyCountSubmenu(current: Int) -> NSMenu {
        let submenu = NSMenu()
        for n in Settings.thresholdKeyChoices {
            let item = makeItem(title: "\(n) キー", action: #selector(selectThresholdKeys(_:)))
            item.tag = n
            item.state = (n == current) ? .on : .off
            submenu.addItem(item)
        }
        return submenu
    }

    private func makeHoldSecondsSubmenu(current: TimeInterval) -> NSMenu {
        let submenu = NSMenu()
        for sec in Settings.holdSecondChoices {
            let item = makeItem(title: String(format: "%.1f 秒", sec), action: #selector(selectHoldSeconds(_:)))
            item.representedObject = sec
            item.state = (abs(sec - current) < 0.01) ? .on : .off
            submenu.addItem(item)
        }
        return submenu
    }

    // MARK: - Helpers

    private func makeItem(title: String, action: Selector, keyEquivalent: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = self
        return item
    }

    private func disabledHeader(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    // MARK: - Actions

    @objc private func previewTapped() {
        if isPreviewing {
            onStopPreview()
        } else {
            onStartPreview()
        }
        isPreviewing.toggle()
        rebuildMenu()
    }

    @objc private func forceStopTapped() {
        isPreviewing = false
        onForceStop()
        rebuildMenu()
    }

    @objc private func selectPlayer(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let kind = PlayerKind(rawValue: raw) else { return }
        if isPreviewing {
            onStopPreview()
            isPreviewing = false
        }
        onSelectPlayer(kind)
        rebuildMenu()
    }

    @objc private func pickCustomAudioTapped() {
        if isPreviewing {
            onStopPreview()
            isPreviewing = false
        }
        onPickCustomAudio()
        rebuildMenu()
    }

    @objc private func clearCustomAudioTapped() {
        if isPreviewing {
            onStopPreview()
            isPreviewing = false
        }
        onClearCustomAudio()
        rebuildMenu()
    }

    @objc private func selectThresholdKeys(_ sender: NSMenuItem) {
        Settings.shared.thresholdKeys = sender.tag
        onDetectionSettingsChanged()
        rebuildMenu()
    }

    @objc private func selectHoldSeconds(_ sender: NSMenuItem) {
        guard let sec = sender.representedObject as? TimeInterval else { return }
        Settings.shared.holdSeconds = sec
        onDetectionSettingsChanged()
        rebuildMenu()
    }

    @objc private func toggleBlocking() {
        Settings.shared.blockingEnabled.toggle()
        rebuildMenu()
    }

    @objc private func toggleAutoLaunch() {
        onToggleAutoLaunch()
        rebuildMenu()
    }

    @objc private func openAccessibility() {
        onOpenAccessibilitySettings()
    }

    @objc private func quitTapped() {
        onQuit()
    }
}
