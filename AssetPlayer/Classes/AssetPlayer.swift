//
//  AssetPlayer.swift
//  KoalaTeaPlayer
//
//  Created by Craig Holliday on 9/26/17.
//

import Foundation
import AVFoundation
import MediaPlayer

public protocol AssetPlayerDelegate: class {
    // Setup
    func currentAssetDidChange(_ player: AssetPlayer)
    func playerIsSetup(_ player: AssetPlayer)

    // Playback
    func playerPlaybackStateDidChange(_ player: AssetPlayer)
    func playerCurrentTimeDidChange(_ player: AssetPlayer)
    /// Current time change but in milliseconds
    func playerCurrentTimeDidChangeInMilliseconds(_ player: AssetPlayer)
    func playerPlaybackDidEnd(_ player: AssetPlayer)

    // Buffering
    func playerIsLikelyToKeepUp(_ player: AssetPlayer)
    // This is the time in seconds that the video has been buffered.
    // If implementing a UIProgressView, user this value / player.maximumDuration to set progress.
    func playerBufferTimeDidChange(_ player: AssetPlayer)
}

extension AssetPlayerDelegate {
    func playerIsLikelyToKeepUp(_ player: AssetPlayer) {}
    func playerBufferTimeDidChange(_ player: AssetPlayer) {}
}

public enum AssetPlayerPlaybackState: Equatable {
    case setup(asset: AssetProtocol)
    case playing, paused, interrupted, buffering, finished, none
    case failed(error: Error?)
    
    public static func ==(lhs: AssetPlayerPlaybackState, rhs: AssetPlayerPlaybackState) -> Bool {
        switch (lhs, rhs) {
        case (.setup(let lKey), .setup(let rKey)):
            return lKey.urlAsset.url == rKey.urlAsset.url
        case (.playing, .playing):
            return true
        case (.paused, .paused):
            return true
        case (.interrupted, .interrupted):
            return true
        case (.failed(let lKey), .failed(let rKey)):
            return lKey?.localizedDescription == rKey?.localizedDescription
        case (.buffering, .buffering):
            return true
        case (.finished, .finished):
            return true
        case (.none, .none):
            return true
        default:
            return false
        }
    }
}

/*
 KVO context used to differentiate KVO callbacks for this class versus other
 classes in its class hierarchy.
 */
private var AssetPlayerKVOContext = 0

extension AssetPlayer {
    private struct Constants {
        // Keys required for a playable item
        static let AssetKeysRequiredToPlay = [
            "playable",
            "hasProtectedContent"
        ]
    }
}

public class AssetPlayer: NSObject {
    /// Player delegate.
    public weak var delegate: AssetPlayerDelegate?
    
    // MARK: Options
    public var isPlayingLocalVideo = true
    public var startTimeForLoop: Double = 0
    public var shouldLoop: Bool = false
    
    // Mark: Time Properties
    public var currentTime: Double = 0

    public var bufferedTime: Float = 0 {
        didSet {
            self.delegate?.playerBufferTimeDidChange(self)
        }
    }
    
    public var timeElapsedText: String = ""
    public var durationText: String = ""

    public var timeLeftText: String {
        let timeLeft = duration - currentTime
        return self.createTimeString(time: Float(timeLeft))
    }

    public var maxSecondValue: Float = 0

    public var duration: Double {
        guard let currentItem = player.currentItem else { return 0.0 }

        return CMTimeGetSeconds(currentItem.duration)
    }

    public var rate: Float = 1.0 {
        willSet {
            guard newValue != self.rate else { return }
        }
        didSet {
            player.rate = rate
            self.setAudioTimePitch(by: rate)
        }
    }
    
    // MARK: AV Properties
    
    /// AVPlayer to pass in to any PlayerView's
    @objc public let player = AVPlayer()

    private var currentAVAudioTimePitchAlgorithm: AVAudioTimePitchAlgorithm = .timeDomain {
        willSet {
            guard newValue != self.currentAVAudioTimePitchAlgorithm else { return }
        }
        didSet {
            self.avPlayerItem?.audioTimePitchAlgorithm = self.currentAVAudioTimePitchAlgorithm
        }
    }

    private func setAudioTimePitch(by rate: Float) {
        guard rate <= 2.0 else {
            self.currentAVAudioTimePitchAlgorithm = .spectral
            return
        }
        self.currentAVAudioTimePitchAlgorithm = .timeDomain
    }
    
    public var avPlayerItem: AVPlayerItem? = nil {
        willSet {
            if avPlayerItem != nil {
                // Remove observers before changing player item
                self.removePlayerItemObservers()
            }
        }
        didSet {
            if avPlayerItem != nil {
                self.addPlayerItemObservers()
            }
            /*
             If needed, configure player item here before associating it with a player.
             (example: adding outputs, setting text style rules, selecting media options)
             */
            player.replaceCurrentItem(with: self.avPlayerItem)
        }
    }
    
    public var asset: AssetProtocol? {
        didSet {
            guard let newAsset = self.asset else { return }
            
            asynchronouslyLoadURLAsset(newAsset)
        }
    }
    
    // MARK: Observers
    /*
     A token obtained from calling `player`'s `addPeriodicTimeObserverForInterval(_:queue:usingBlock:)`
     method.
     */
    private var timeObserverToken: Any?

    /*
     A token obtained from calling `player`'s `addPeriodicTimeObserverForInterval(_:queue:usingBlock:)`
     method.
     */
    private var timeObserverTokenMilliseconds: Any?
    
    /// The state that the internal `AVPlayer` is in.
    public var state: AssetPlayerPlaybackState {
        didSet {
            guard state != oldValue else {
                return
            }
            
            self.handleStateChange(state)
        }
    }
    
    // MARK: - Life Cycle
    public override init() {
        self.state = .none
    }

    deinit {
        if let timeObserverToken = timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }

        if let timeObserverTokenMilliseconds = timeObserverTokenMilliseconds {
            player.removeTimeObserver(timeObserverTokenMilliseconds)
            self.timeObserverTokenMilliseconds = nil
        }

        player.pause()

        //@TODO: Simplify removing observers
        removeObserver(self, forKeyPath: #keyPath(AssetPlayer.player.currentItem.duration), context: &AssetPlayerKVOContext)
        removeObserver(self, forKeyPath: #keyPath(AssetPlayer.player.rate), context: &AssetPlayerKVOContext)
        removeObserver(self, forKeyPath: #keyPath(AssetPlayer.player.currentItem.status), context: &AssetPlayerKVOContext)

        if avPlayerItem != nil {
            self.removePlayerItemObservers()
        }
    }
    
    // MARK: - Asset Loading
    private func asynchronouslyLoadURLAsset(_ newAsset: AssetProtocol) {
        /*
         Using AVAsset now runs the risk of blocking the current thread (the
         main UI thread) whilst I/O happens to populate the properties. It's
         prudent to defer our work until the properties we need have been loaded.
         */
        newAsset.urlAsset.loadValuesAsynchronously(forKeys: Constants.AssetKeysRequiredToPlay) {
            /*
             The asset invokes its completion handler on an arbitrary queue.
             To avoid multiple threads using our internal state at the same time
             we'll elect to use the main thread at all times, let's dispatch
             our handler to the main queue.
             */
            DispatchQueue.main.async {
                /*
                 `self.asset` has already changed! No point continuing because
                 another `newAsset` will come along in a moment.
                 */
                guard newAsset.urlAsset == self.asset?.urlAsset else { return }

                // @TODO: Handle errors
                /*
                 Test whether the values of each of the keys we need have been
                 successfully loaded.
                 */
                for key in Constants.AssetKeysRequiredToPlay {
                    var error: NSError?

                    if newAsset.urlAsset.statusOfValue(forKey: key, error: &error) == .failed {
                        let stringFormat = NSLocalizedString("error.asset_key_%@_failed.description", comment: "Can't use this AVAsset because one of it's keys failed to load")
                        let _ = String.localizedStringWithFormat(stringFormat, key)
                        
                        self.state = .failed(error: error as Error?)

                        return
                    }
                }

                // We can't play this asset.
                if !newAsset.urlAsset.isPlayable || newAsset.urlAsset.hasProtectedContent {
                    let message = NSLocalizedString("error.asset_not_playable.description", comment: "Can't use this AVAsset because it isn't playable or has protected content")

                    let error = NSError(domain: message, code: -1, userInfo: nil) as Error
                    self.state = .failed(error: error)

                    return
                }
                
                /*
                 We can play this asset. Create a new `AVPlayerItem` and make
                 it our player's current item.
                 */
                self.avPlayerItem = AVPlayerItem(asset: newAsset.urlAsset)
                self.delegate?.currentAssetDidChange(self)
            }
        }
    }
    
    // MARK: Time Formatting
    /*
     A formatter for individual date components used to provide an appropriate
     value for the `startTimeLabel` and `durationLabel`.
     */
    // Lazy init time formatter because create a formatter multiple times is expensive
    lazy var timeRemainingFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.minute, .second]
        
        return formatter
    }()
    
    private func createTimeString(time: Float) -> String {
        let components = NSDateComponents()
        components.second = Int(max(0.0, time))
        
        return timeRemainingFormatter.string(from: components as DateComponents)!
    }
}

// MARK: State Management Methods
extension AssetPlayer {
    private func handleStateChange(_ state: AssetPlayerPlaybackState) {
        switch state {
        case .none:
            self.player.pause()
            break
        case .setup(let asset):
            self.asset = asset
            break
        case .playing:
            if #available(iOS 10.0, *) {
                self.player.playImmediately(atRate: self.rate)
            } else {
                // Fallback on earlier versions
                self.player.rate = self.rate
                self.player.play()
            }
            break
        case .paused:
            self.player.pause()
            break
        case .interrupted:
            self.player.pause()
            break
        case .failed:
            self.player.pause()
            break
        case .buffering:
            self.player.pause()
            break
        case .finished:
            guard !shouldLoop else {
                self.seekToTimeInSeconds(startTimeForLoop)
                self.state = .playing
                return
            }
            
            self.player.pause()
//            asset = nil
//            playerItem = nil
//            self.player.replaceCurrentItem(with: nil)
            break
        }
    }
    
    // MARK: - KVO Observation
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        // Make sure the this KVO callback was intended for this view controller.
        guard context == &AssetPlayerKVOContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        if keyPath == #keyPath(AssetPlayer.player.currentItem.duration) {
            // Update timeSlider and enable/disable controls when duration > 0.0
            
            /*
             Handle `NSNull` value for `NSKeyValueChangeNewKey`, i.e. when
             `player.currentItem` is nil.
             */
            let newDuration: CMTime
            if let newDurationAsValue = change?[NSKeyValueChangeKey.newKey] as? NSValue {
                newDuration = newDurationAsValue.timeValue
            }
            else {
                newDuration = kCMTimeZero
            }
            
            let hasValidDuration = newDuration.isNumeric && newDuration.value != 0
            let newDurationSeconds = hasValidDuration ? CMTimeGetSeconds(newDuration) : 0.0
            let currentTime = hasValidDuration ? Float(CMTimeGetSeconds(player.currentTime())) : 0.0
            
            self.maxSecondValue = Float(newDurationSeconds)
            self.timeElapsedText = createTimeString(time: currentTime)
            self.durationText = createTimeString(time: Float(newDurationSeconds))
            
            self.delegate?.playerIsSetup(self)
        }
        else if keyPath == #keyPath(AssetPlayer.player.rate) {
            // Handle any player rate changes
        }
        else if keyPath == #keyPath(AssetPlayer.player.currentItem.status) {
            // Display an error if status becomes `.Failed`.
            
            /*
             Handle `NSNull` value for `NSKeyValueChangeNewKey`, i.e. when
             `player.currentItem` is nil.
             */
            let newStatus: AVPlayerItemStatus
            
            if let newStatusAsNumber = change?[NSKeyValueChangeKey.newKey] as? NSNumber {
                newStatus = AVPlayerItemStatus(rawValue: newStatusAsNumber.intValue)!
            }
            else {
                newStatus = .unknown
            }
            
            if newStatus == .failed {
                self.state = .failed(error: player.currentItem?.error)
            }
        }
            // All Buffer observer values
        else if keyPath == #keyPath(AVPlayerItem.isPlaybackBufferEmpty) {
            // No need to use this keypath if we are playing local video
            guard !isPlayingLocalVideo else { return }
            
            // PlayerEmptyBufferKey
            if let item = self.avPlayerItem {
                if item.isPlaybackBufferEmpty {
                    self.state = .buffering
                }
            }
        }
        else if keyPath == #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp) {
            // No need to use this keypath if we are playing local video
            guard !isPlayingLocalVideo else { return }
            
            // PlayerKeepUpKey
            if let item = self.avPlayerItem {
                if item.isPlaybackLikelyToKeepUp {
                    self.delegate?.playerIsLikelyToKeepUp(self)
                }
            }
        }
        else if keyPath == #keyPath(AVPlayerItem.loadedTimeRanges) {
            // No need to use this keypath if we are playing local video
            guard !isPlayingLocalVideo else { return }
            
            // PlayerLoadedTimeRangesKey
            if let item = self.avPlayerItem {
                let timeRanges = item.loadedTimeRanges
                if let timeRange = timeRanges.first?.timeRangeValue {
                    let bufferedTime: Float = Float(CMTimeGetSeconds(CMTimeAdd(timeRange.start, timeRange.duration)))
                    // Smart Value check for buffered time to switch to playing state
                    // or switch to buffering state
                    let smartValue = (bufferedTime - Float(self.currentTime)) > 5 || bufferedTime.rounded() == Float(self.currentTime.rounded())
                    
                    //@TODO: Clean this up
                    switch smartValue {
                    case true:
                        if self.state != .buffering, self.state != .paused, self.state != .playing {
                            self.state = .playing
                        }
                        break
                    case false:
                        if self.state != .buffering && self.state != .paused {
                            self.state = .buffering
                        }
                        break
                    }
                    self.bufferedTime = Float(bufferedTime)
                }
            }
        }
    }
    
    // Trigger KVO for anyone observing our properties affected by player and player.currentItem
    override public class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        let affectedKeyPathsMappingByKey: [String: Set<String>] = [
            "duration":     [#keyPath(AssetPlayer.player.currentItem.duration)],
            "rate":         [#keyPath(AssetPlayer.player.rate)]
        ]
        
        return affectedKeyPathsMappingByKey[key] ?? super.keyPathsForValuesAffectingValue(forKey: key)
    }
    
    // MARK: Notification Observing Methods
    
    @objc private func handleAVPlayerItemDidPlayToEndTimeNotification(notification: Notification) {
        self.delegate?.playerPlaybackDidEnd(self)
        self.state = .finished
    }
}

// MARK: Playback Control Methods.
extension AssetPlayer {
    public func perform(action: AssetPlayerActions) {
        switch action {
        case .setup(let asset):
            self.setup(with: asset)
        case .play:
            self.state = .playing
        case .pause:
            self.state = .paused
        case .seekToTimeInSeconds(let time):
            self.seekToTimeInSeconds(time)
        case .changePlayerPlaybackRate(let rate):
            self.changePlayerPlaybackRate(to: rate)
        }
    }
    
    private func setup(with asset: AssetProtocol) {
        /*
         Update the UI when these player properties change.
         
         Use the context parameter to distinguish KVO for our particular observers
         and not those destined for a subclass that also happens to be observing
         these properties.
         */
        addObserver(self, forKeyPath: #keyPath(AssetPlayer.player.currentItem.duration), options: [.new, .initial], context: &AssetPlayerKVOContext)
        addObserver(self, forKeyPath: #keyPath(AssetPlayer.player.rate), options: [.new, .initial], context: &AssetPlayerKVOContext)
        addObserver(self, forKeyPath: #keyPath(AssetPlayer.player.currentItem.status), options: [.new, .initial], context: &AssetPlayerKVOContext)
        
        self.state = .setup(asset: asset)
        
        // Seconds time observer
        let interval = CMTimeMake(1, 1)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { [unowned self] time in
            let timeElapsed = Float(CMTimeGetSeconds(time))
            
            self.currentTime = Double(timeElapsed)
            self.timeElapsedText = self.createTimeString(time: timeElapsed)
            
            self.delegate?.playerCurrentTimeDidChange(self)
        }
        
        // Millisecond time observer
        let millisecondInterval = CMTimeMake(1, 100)
        timeObserverTokenMilliseconds = player.addPeriodicTimeObserver(forInterval: millisecondInterval, queue: DispatchQueue.main) { [unowned self] time in
            let timeElapsed = Float(CMTimeGetSeconds(time))
            
            self.currentTime = Double(timeElapsed)
            self.timeElapsedText = self.createTimeString(time: timeElapsed)
            
            self.delegate?.playerCurrentTimeDidChangeInMilliseconds(self)
        }
    }
    
    private func seekTo(_ newPosition: CMTime) {
        guard asset != nil else { return }
        self.player.seek(to: newPosition, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
    }

    private func seekToTimeInSeconds(_ time: Double) {
        guard asset != nil else { return }
        let newPosition = CMTimeMakeWithSeconds(time, 600)
        self.player.seek(to: newPosition, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
    }

    private func changePlayerPlaybackRate(to newRate: Float) {
        guard asset != nil else { return }
        self.rate = newRate
    }
}

extension AssetPlayer {
    // Player buffer observers
    private func addPlayerItemObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleAVPlayerItemDidPlayToEndTimeNotification(notification:)), name: .AVPlayerItemDidPlayToEndTime, object: avPlayerItem)

        avPlayerItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackBufferEmpty), options: ([.new, .old]), context: &AssetPlayerKVOContext)
        avPlayerItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp), options: ([.new, .old]), context: &AssetPlayerKVOContext)
        avPlayerItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.loadedTimeRanges), options: ([.new, .old]), context: &AssetPlayerKVOContext)
    }

    private func removePlayerItemObservers() {
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: avPlayerItem)

        avPlayerItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackBufferEmpty), context: &AssetPlayerKVOContext)
        avPlayerItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp), context: &AssetPlayerKVOContext)
        avPlayerItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.loadedTimeRanges), context: &AssetPlayerKVOContext)
    }
}

public enum AssetPlayerActions {
    case setup(with: AssetProtocol)
    case play
    case pause
    case seekToTimeInSeconds(time: Double)
    case changePlayerPlaybackRate(to: Float)
}
