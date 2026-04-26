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

        let detector = CatDetector(
            thresholdKeys: 2,
            holdDuration: settings.holdSeconds,
            onTrigger: { [weak self] in
                self?.startCatMode()
            },
            onRelease: { [weak self] in
                self?.endCatMode()
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
            onStartPreview: { [weak self] in
                self?.currentPlayer?.play()
            },
            onStopPreview: { [weak self] in
                self?.currentPlayer?.stop()
            },
            onForceStop: { [weak self] in
                self?.endCatMode()
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

    private func startCatMode() {
        currentPlayer?.play()
        keyMonitor?.isBlocking = true
        scheduleBlockingTimeout()
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
