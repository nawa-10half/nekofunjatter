import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    /// ブロック開始から強制解除するまでの最大時間 (デッドロック防止)
    private static let maxBlockingDuration: TimeInterval = 60

    private var menuBar: MenuBarController?
    private var keyMonitor: KeyMonitor?
    private var detector: CatDetector?
    private var currentPlayer: Player?
    private var blockingTimeoutTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let settings = Settings.shared

        currentPlayer = makePlayer(for: settings.playerKind)

        rebuildDetector()

        let monitor = KeyMonitor(
            // detector を再生成しても繋がるよう self.detector? 経由で参照
            onKeyDown: { [weak self] keyCode in self?.detector?.keyDown(keyCode) },
            onKeyUp:   { [weak self] keyCode in self?.detector?.keyUp(keyCode) }
        )
        self.keyMonitor = monitor

        menuBar = MenuBarController(
            onSelectPlayer: { [weak self] kind in
                guard let self else { return }
                Settings.shared.playerKind = kind
                self.currentPlayer?.stop()
                self.currentPlayer = self.makePlayer(for: kind)
            },
            onStartPreview: { [weak self] in
                self?.currentPlayer?.play()
            },
            onStopPreview: { [weak self] in
                self?.currentPlayer?.stop()
            },
            onForceStop: { [weak self] in
                self?.endCatMode()
            },
            onDetectionSettingsChanged: { [weak self] in
                self?.rebuildDetector()
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

    private func rebuildDetector() {
        let s = Settings.shared
        detector = CatDetector(
            thresholdKeys: s.thresholdKeys,
            holdDuration: s.holdSeconds,
            onTrigger: { [weak self] in self?.startCatMode() },
            onRelease: { [weak self] in self?.endCatMode() }
        )
    }

    private func startCatMode() {
        currentPlayer?.play()
        if Settings.shared.blockingEnabled {
            keyMonitor?.isBlocking = true
            scheduleBlockingTimeout()
        }
    }

    private func endCatMode() {
        currentPlayer?.stop()
        keyMonitor?.isBlocking = false
        blockingTimeoutTimer?.invalidate()
        blockingTimeoutTimer = nil
    }

    private func scheduleBlockingTimeout() {
        blockingTimeoutTimer?.invalidate()
        let timer = Timer(timeInterval: Self.maxBlockingDuration, repeats: false) { [weak self] _ in
            self?.endCatMode()
        }
        RunLoop.main.add(timer, forMode: .common)
        blockingTimeoutTimer = timer
    }

    private func makePlayer(for kind: PlayerKind) -> Player {
        switch kind {
        case .wav:      return WavPlayer(resourceName: "Neko_Funjatta")
        case .eightBit: return WavPlayer(resourceName: "Neko_Funjatta_8bit")
        case .dubstep:  return WavPlayer(resourceName: "neko_Dubstep", fileExtension: "mp3")
        }
    }
}
