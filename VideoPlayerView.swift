//
//  VideoPlayerView.swift
//  AssetPlayer
//
//  Created by Craig Holliday on 8/11/18.
//

import Foundation

class VideoPlayerView: UIView {
    weak var delegate: AssetPlayerDelegate?

    var assetPlayer: AssetPlayer?
    var playerView: PlayerView?

    override init(frame: CGRect) {
        super.init(frame: frame)

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupPlayer(with video: VideoAsset) {
        self.assetPlayer = AssetPlayer(videoAsset: video)
        self.assetPlayer?.isPlayingLocalVideo = true
        self.assetPlayer?.shouldLoop = true
        self.assetPlayer?.pause()

        self.playerView = assetPlayer?.playerView
        playerView?.frame = self.frame

        self.assetPlayer?.playerDelegate = self

        self.addSubview(self.playerView!)
    }
}

extension VideoPlayerView: AssetPlayerDelegate {
    func playerCurrentTimeDidChangeInMilliseconds(_ player: AssetPlayer) {
        self.delegate?.playerCurrentTimeDidChangeInMilliseconds(player)
    }

    func currentAssetDidChange(_ player: AssetPlayer) {
        self.delegate?.currentAssetDidChange(player)
    }

    func playerIsSetup(_ player: AssetPlayer) {
        self.delegate?.playerIsSetup(player)
    }

    func playerPlaybackStateDidChange(_ player: AssetPlayer) {
        self.delegate?.playerPlaybackStateDidChange(player)
    }

    func playerCurrentTimeDidChange(_ player: AssetPlayer) {
        self.delegate?.playerCurrentTimeDidChange(player)
    }

    func playerPlaybackDidEnd(_ player: AssetPlayer) {
        self.delegate?.playerPlaybackDidEnd(player)
    }

    func playerIsLikelyToKeepUp(_ player: AssetPlayer) {
        self.delegate?.playerIsLikelyToKeepUp(player)
    }

    func playerBufferTimeDidChange(_ player: AssetPlayer) {
        self.delegate?.playerBufferTimeDidChange(player)
    }
}
