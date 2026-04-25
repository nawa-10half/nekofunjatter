import AppKit

final class MenuBarController: NSObject {
    private let statusItem: NSStatusItem
    private let onSelectPlayer: (PlayerKind) -> Void
    private let onPreview: () -> Void
    private let onOpenAccessibilitySettings: () -> Void
    private let onQuit: () -> Void

    init(
        onSelectPlayer: @escaping (PlayerKind) -> Void,
        onPreview: @escaping () -> Void,
        onOpenAccessibilitySettings: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.onSelectPlayer = onSelectPlayer
        self.onPreview = onPreview
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

        let preview = NSMenuItem(title: "プレビュー再生", action: #selector(previewTapped), keyEquivalent: "")
        preview.target = self
        menu.addItem(preview)

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
        onPreview()
    }

    @objc private func selectPlayer(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let kind = PlayerKind(rawValue: raw) else { return }
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
