import AVKit

/// Manages looped playback for a single video.
class PlaybackController {

    let video: Video
    let player: AVPlayer
    let seeker: PlayerSeeker

    private(set) lazy var observers = PlayerObservations(player: self.player)
    private let looper: AVPlayerLooper

    init(video: Video, player: AVQueuePlayer = .init()) {
        self.video = video
        self.player = player
        self.looper = AVPlayerLooper(player: player, templateItem: AVPlayerItem(asset: video.avAsset))
        self.seeker = PlayerSeeker(player: player)
    }

    // MARK: Status

    /// True when both the player and the current item are ready to play.
    var isReadyToPlay: Bool {
        return (player.status == .readyToPlay) && (currentItem?.status == .readyToPlay)
    }

    /// True if the player is playing or waiting to play.
    /// Check `player.timeControlStatus` for detailed status.
    var isPlaying: Bool {
        return player.rate != 0
    }

    var isSeeking: Bool {
        return seeker.isSeeking
    }

    var currentTime: CMTime {
        return player.currentTime()
    }

    var currentItem: AVPlayerItem? {
        return player.currentItem
    }

    // MARK: Playback

    func playOrPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func play() {
        guard !isPlaying else { return }
        player.play()
    }

    func pause() {
        guard isPlaying else { return }
        player.pause()
    }

    func step(byCount count: Int) {
        pause()
        currentItem?.step(byCount: count)
    }
}
