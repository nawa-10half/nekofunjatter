import AppKit

final class MenuBarController: NSObject {
    private let statusItem: NSStatusItem
    private let onSelectPlayer: (PlayerKind) -> Void
    private let onStartPreview: () -> Void
    private let onStopPreview: () -> Void
    private let onForceStop: () -> Void
    private let onOpenAccessibilitySettings: () -> Void
    private let onQuit: () -> Void

    /// プレビュー再生中かどうか (メニュー表示の切替用)
    private var isPreviewing: Bool = false

    init(
        onSelectPlayer: @escaping (PlayerKind) -> Void,
        onStartPreview: @escaping () -> Void,
        onStopPreview: @escaping () -> Void,
        onForceStop: @escaping () -> Void,
        onOpenAccessibilitySettings: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.onSelectPlayer = onSelectPlayer
        self.onStartPreview = onStartPreview
        self.onStopPreview = onStopPreview
        self.onForceStop = onForceStop
        self.onOpenAccessibilitySettings = onOpenAccessibilitySettings
        self.onQuit = onQuit
        super.init()

        if let button = statusItem.button {
            button.title = "🐾"
            button.toolTip = "Nekofunjatter"
        }

        rebuildMenu()
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        let previewTitle = isPreviewing ? "プレビュー停止" : "プレビュー再生"
        let preview = NSMenuItem(title: previewTitle, action: #selector(previewTapped), keyEquivalent: "")
        preview.target = self
        menu.addItem(preview)

        let forceStop = NSMenuItem(title: "今すぐ停止 (キーブロック解除)", action: #selector(forceStopTapped), keyEquivalent: "")
        forceStop.target = self
        menu.addItem(forceStop)

        menu.addItem(.separator())

        let soundHeader = NSMenuItem(title: "音源", action: nil, keyEquivalent: "")
        soundHeader.isEnabled = false
        menu.addItem(soundHeader)

        let current = Settings.shared.playerKind
        for kind in PlayerKind.allCases {
            let item = NSMenuItem(title: kind.displayName, action: #selector(selectPlayer(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = kind.rawValue
            item.state = (kind == current) ? .on : .off
            menu.addItem(item)
        }

        menu.addItem(.separator())

        let access = NSMenuItem(title: "アクセシビリティ設定を開く…", action: #selector(openAccessibility), keyEquivalent: "")
        access.target = self
        menu.addItem(access)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Nekofunjatter を終了", action: #selector(quitTapped), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
    }

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
        // 強制停止時はプレビュー状態もリセット
        isPreviewing = false
        onForceStop()
        rebuildMenu()
    }

    @objc private func selectPlayer(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let kind = PlayerKind(rawValue: raw) else { return }
        // 音源切替時に再生中なら止める
        if isPreviewing {
            onStopPreview()
            isPreviewing = false
        }
        onSelectPlayer(kind)
        rebuildMenu()
    }

    @objc private func openAccessibility() {
        onOpenAccessibilitySettings()
    }

    @objc private func quitTapped() {
        onQuit()
    }
}
