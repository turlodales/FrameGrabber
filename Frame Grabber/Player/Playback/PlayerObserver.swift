import AVKit

protocol PlayerObserver: class {
    func player(_ player: AVPlayer, didUpdateStatus status: AVPlayer.Status)
    func player(_ player: AVPlayer, didPeriodicUpdateAtTime time: CMTime)
    func player(_ player: AVPlayer, didUpdateTimeControlStatus status: AVPlayer.TimeControlStatus)
    func player(_ player: AVPlayer, didUpdateRate rate: Float)
    func player(_ player: AVPlayer, didUpdateReasonForWaitingToPlay status: AVPlayer.WaitingReason?)
    func player(_ player: AVPlayer, didUpdateCurrentPlayerItem item: AVPlayerItem?)
    func currentPlayerItem(_ playerItem: AVPlayerItem, didUpdateStatus status: AVPlayerItem.Status)
    func currentPlayerItem(_ playerItem: AVPlayerItem, didUpdateDuration duration: CMTime)
    func currentPlayerItem(_ playerItem: AVPlayerItem, didUpdatePresentationSize size: CGSize)
    func currentPlayerItem(_ playerItem: AVPlayerItem, didUpdateTracks tracks: [AVPlayerItemTrack])
}

extension PlayerObserver {
    func player(_ player: AVPlayer, didUpdateStatus status: AVPlayer.Status) {}
    func player(_ player: AVPlayer, didPeriodicUpdateAtTime time: CMTime) {}
    func player(_ player: AVPlayer, didUpdateTimeControlStatus status: AVPlayer.TimeControlStatus) {}
    func player(_ player: AVPlayer, didUpdateRate rate: Float) {}
    func player(_ player: AVPlayer, didUpdateReasonForWaitingToPlay status: AVPlayer.WaitingReason?) {}
    func player(_ player: AVPlayer, didUpdateCurrentPlayerItem item: AVPlayerItem?) {}
    func currentPlayerItem(_ playerItem: AVPlayerItem, didUpdateStatus status: AVPlayerItem.Status) {}
    func currentPlayerItem(_ playerItem: AVPlayerItem, didUpdateDuration duration: CMTime) {}
    func currentPlayerItem(_ playerItem: AVPlayerItem, didUpdatePresentationSize size: CGSize) {}
    func currentPlayerItem(_ playerItem: AVPlayerItem, didUpdateTracks tracks: [AVPlayerItemTrack]) {}
}

/// Manages observers for a player. Observers are retained weakly.
class PlayerObservations {

    let player: AVPlayer

    private var observers = [ObjectIdentifier: WeakObserver]()
    private let periodicObservationInterval: CMTime
    private var timeObserver: Any?
    private var kvoObservations = [NSKeyValueObservation]()

    init(player: AVPlayer, periodicObservationInterval: TimeInterval = 1/30.0) {
        self.player = player
        self.periodicObservationInterval = CMTime(seconds: periodicObservationInterval)
        startObserving()
    }

    deinit {
        stopObserving()
    }

    func add(_ observer: PlayerObserver) {
        let id = ObjectIdentifier(observer)
        observers[id] = WeakObserver(observer)
    }

    func remove(_ observer: PlayerObserver) {
        let id = ObjectIdentifier(observer)
        observers[id] = nil
    }
}

// MARK: - Private

private extension PlayerObservations {

    func startObserving() {
        timeObserver = player.addPeriodicTimeObserver(forInterval: periodicObservationInterval, queue: nil) { [weak self] time in
            guard let self = self else { return }
            self.notify { $0.player(self.player, didPeriodicUpdateAtTime: time) }
        }

        add(player.observe(\.status) { [weak self] player, _ in
            self?.notify { $0.player(player, didUpdateStatus: player.status) }
        })

        add(player.observe(\.timeControlStatus) { [weak self] player, _ in
            self?.notify { $0.player(player, didUpdateTimeControlStatus: player.timeControlStatus) }
        })

        add(player.observe(\.rate) { [weak self] player, _ in
            self?.notify { $0.player(player, didUpdateRate: player.rate) }
        })

        add(player.observe(\.reasonForWaitingToPlay) { [weak self] player, _ in
            self?.notify { $0.player(player, didUpdateReasonForWaitingToPlay: player.reasonForWaitingToPlay) }
        })

        add(player.observe(\.currentItem) { [weak self] player, _ in
            self?.notify { $0.player(player, didUpdateCurrentPlayerItem: player.currentItem) }
        })

        add(player.observe(\.currentItem?.status) { [weak self] player, _ in
            guard let item = player.currentItem else { return }
            self?.notify { $0.currentPlayerItem(item, didUpdateStatus: item.status) }
        })

        add(player.observe(\.currentItem?.duration) { [weak self] player, _ in
            guard let item = player.currentItem else { return }
            self?.notify { $0.currentPlayerItem(item, didUpdateDuration: item.duration) }
        })

        add(player.observe(\.currentItem?.presentationSize) { [weak self] player, _ in
            guard let item = player.currentItem else { return }
            self?.notify { $0.currentPlayerItem(item, didUpdatePresentationSize: item.presentationSize) }
        })

        add(player.observe(\.currentItem?.tracks) { [weak self] player, _ in
            guard let item = player.currentItem else { return }
            self?.notify { $0.currentPlayerItem(item, didUpdateTracks: item.tracks) }
        })
    }

    func stopObserving() {
        timeObserver.flatMap(player.removeTimeObserver)
        timeObserver = nil
        observers = [:]
        kvoObservations = []
    }

    func add(_ observation: NSKeyValueObservation) {
        kvoObservations.append(observation)
    }

    func notify(block: (PlayerObserver) -> ()) {
        observers.forEach { $0.value.observer.flatMap(block) }
        cleanObservers()
    }

    func cleanObservers() {
        observers = observers.filter {
            $0.value.observer != nil
        }
    }
}

private class WeakObserver {
    weak var observer: PlayerObserver?
    init(_ observer: PlayerObserver) {
        self.observer = observer
    }
}
