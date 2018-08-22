//
//  VideoPlayerView.swift
//  AssetPlayer
//
//  Created by Craig Holliday on 8/11/18.
//

import Foundation
import AVFoundation

public class VideoPlayerView: UIView {
    weak var delegate: AssetPlayerDelegate?

    public var assetPlayer: AssetPlayer?
    var playerView: PlayerView?

//    override init(frame: CGRect) {
//        super.init(frame: frame)
//    }
//
//    required public init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }

    public func setupPlayer(with video: VideoAsset) {
        self.assetPlayer = AssetPlayer(videoAsset: video)
        self.assetPlayer?.isPlayingLocalVideo = true
        self.assetPlayer?.shouldLoop = true
        self.assetPlayer?.pause()

//        self.playerView = assetPlayer?.playerView
        playerView?.frame = self.frame

//        self.assetPlayer?.playerDelegate = self

//        self.addSubview(self.playerView!)

        let playerview1 = PlayerView(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
        playerview1.backgroundColor = .red
        playerview1.playerLayer.player = assetPlayer?.player
        self.addSubview(playerview1)

        let playerview2 = PlayerView(frame: CGRect(x: 0, y: 100, width: 200, height: 100))
        playerview2.backgroundColor = .yellow
        playerview2.playerLayer.player = assetPlayer?.player
        self.addSubview(playerview2)

        let playerview3 = PlayerView(frame: CGRect(x: 0, y: 200, width: 200, height: 100))
        playerview3.backgroundColor = .orange
        playerview3.playerLayer.player = assetPlayer?.player
        self.addSubview(playerview3)

        let playerview4 = PlayerView(frame: CGRect(x: 0, y: 300, width: 200, height: 100))
        playerview4.backgroundColor = .orange
        playerview4.playerLayer.player = assetPlayer?.player
        self.addSubview(playerview4)

        let playerview5 = PlayerView(frame: CGRect(x: 0, y: 400, width: 200, height: 100))
        playerview5.backgroundColor = .orange
        playerview5.playerLayer.player = assetPlayer?.player
        self.addSubview(playerview5)

        let playerview6 = PlayerView(frame: CGRect(x: 0, y: 500, width: 200, height: 100))
        playerview6.backgroundColor = .orange
        playerview6.playerLayer.player = assetPlayer?.player
        self.addSubview(playerview6)
    }
}

extension VideoPlayerView: AssetPlayerDelegate {
    public func playerCurrentTimeDidChangeInMilliseconds(_ player: AssetPlayer) {
        self.delegate?.playerCurrentTimeDidChangeInMilliseconds(player)
    }

    public func currentAssetDidChange(_ player: AssetPlayer) {
        self.delegate?.currentAssetDidChange(player)
    }

    public func playerIsSetup(_ player: AssetPlayer) {
        self.delegate?.playerIsSetup(player)
    }

    public func playerPlaybackStateDidChange(_ player: AssetPlayer) {
        self.delegate?.playerPlaybackStateDidChange(player)
    }

    public func playerCurrentTimeDidChange(_ player: AssetPlayer) {
        self.delegate?.playerCurrentTimeDidChange(player)
    }

    public func playerPlaybackDidEnd(_ player: AssetPlayer) {
        self.delegate?.playerPlaybackDidEnd(player)
    }

    public func playerIsLikelyToKeepUp(_ player: AssetPlayer) {
        self.delegate?.playerIsLikelyToKeepUp(player)
    }

    public func playerBufferTimeDidChange(_ player: AssetPlayer) {
        self.delegate?.playerBufferTimeDidChange(player)
    }
}
