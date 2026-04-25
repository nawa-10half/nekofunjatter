import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBar: MenuBarController?
    private var keyMonitor: KeyMonitor?
    private var detector: CatDetector?
    private var currentPlayer: Player?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let settings = Settings.shared

        currentPlayer = makePlayer(for: settings.playerKind)

        let detector = CatDetector(
            thresholdKeys: 2,
            holdDuration: settings.holdSeconds,
            onTrigger: { [weak self] in
                self?.currentPlayer?.play()
            },
            onRelease: { [weak self] in
                self?.currentPlayer?.stop()
            }
        )
        self.detector = detector

        let monitor = KeyMonitor(
            onKeyDown: { keyCode in detector.keyDown(keyCode) },
            onKeyUp: { keyCode in detector.keyUp(keyCode) }
        )
        self.keyMonitor = monitor

        menuBar = MenuBarController(
            onSelectPlayer: { [weak self] kind in
                guard let self else { return }
                Settings.shared.playerKind = kind
                self.currentPlayer?.stop()
                self.currentPlayer = self.makePlayer(for: kind)
            },
            onPreview: { [weak self] in
                self?.currentPlayer?.play()
            },
            onOpenAccessibilitySettings: {
                KeyMonitor.openAccessibilitySettings()
            },
            onQuit: {
                NSApp.terminate(nil)
            }
        )

        monitor.start()
    }

    private func makePlayer(for kind: PlayerKind) -> Player {
        switch kind {
        case .wav:      return WavPlayer(resourceName: "Neko_Funjatta")
        case .eightBit: return WavPlayer(resourceName: "Neko_Funjatta_8bit")
        case .dubstep:  return WavPlayer(resourceName: "neko_Dubstep", fileExtension: "mp3")
        }
    }
}
