import AVKit

extension AVPlayerItem.Status: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .unknown: return "AVPlayerItem.Status.unknown"
        case .failed: return "AVPlayerItem.Status.failed"
        case .readyToPlay: return "AVPlayerItem.Status.readyToPlay"
        }
    }
}

extension AVPlayer.Status: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .unknown: return "AVPlayer.Status.unknown"
        case .failed: return "AVPlayer.Status.failed"
        case .readyToPlay: return "AVPlayer.Status.readyToPlay"
        }
    }
}

extension AVPlayerLooper.Status: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .unknown: return "AVPlayerLooper.Status.unknown"
        case .cancelled: return "AVPlayerLooper.Status.cancelled"
        case .failed: return "AVPlayerLooper.Status.failed"
        case .ready: return "AVPlayerLooper.Status.ready"
        }
    }
}

extension AVPlayer.TimeControlStatus: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .paused: return "AVPlayer.TimeControlStatus.paused"
        case .playing: return "AVPlayer.TimeControlStatus.playing"
        case .waitingToPlayAtSpecifiedRate: return "AVPlayer.TimeControlStatus.waitingToPlayAtSpecifiedRate"
        }
    }
}

extension AVPlayer.WaitingReason: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .evaluatingBufferingRate: return "AVPlayer.WaitingReason.evaluatingBufferingRate"
        case .noItemToPlay: return "AVPlayer.WaitingReason.noItemToPlay"
        case .toMinimizeStalls: return "AVPlayer.WaitingReason.toMinimizeStalls"
        default: return "Unknown AVPlayer.WaitingReason"
        }
    }
}
