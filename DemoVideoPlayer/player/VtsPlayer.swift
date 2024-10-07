//
//  VtsPlayer.swift
//  DemoVideoPlayer
//
//  Created by TaHoangMinh on 7/10/24.
//

import Foundation
import Foundation

class VtsPlayer {
    var avcDecoder: AvcDecoder?
    var avcSplitter: AvcSplitter?
    // MINHTH: TODO
//    var hevcDecoder: HevcDecoder?
//    var hevcSplitter: HevcSplitter?
    var iPlayerState: IPlayerState?
    var isPlaying: Bool = false
    var isStop: Bool = false
    // MINHTH: TODO
//    var methodChannel: MethodChannel?
    var videoView: PhcVideoView?
    var urlSocket: String = ""
    var isRecording: Bool = false
    var rtpQueue: RtpQueue = RtpQueue()
    var dataQueue: DataQueue = DataQueue()
    var videoSocket: VideoSocket! = nil

    protocol IPlayerState {
        func loading()
        func playing()
        func stopVideo()
    }

    func getRtpQueue() -> RtpQueue {
        return self.rtpQueue
    }

    func getDataQueue() -> DataQueue {
        return self.dataQueue
    }

    func initAvcPlayer() {
        self.avcSplitter = AvcSplitter(player: self)
        self.avcDecoder = AvcDecoder(vtsPlayer: self)
    }

    func initHevcPlayer() {
//        self.hevcSplitter = HevcSplitter(self)
//        self.hevcDecoder = HevcDecoder(self)
    }

    init() {
        // MINHTH-TODO
//        self.videoSocket = VideoSocket(self)
        initHevcPlayer()
        initAvcPlayer()
    }

    func setUpPlayer(_ videoView: PhcVideoView, _ urlSocket: String) {
        self.videoView = videoView
        self.urlSocket = urlSocket
        startPlayer()
    }

    func sleep20milSec() {
        do {
            try Thread.sleep(forTimeInterval: 0.01)
        } catch {
            print(error)
        }
    }

    func startHevcPlayer() {
        if self.videoSocket != nil {
            // MINHTH - TODO
//            self.hevcSplitter?.startSplitter()
//            self.hevcDecoder?.start()
        } else {
            sleep20milSec()
            startHevcPlayer()
        }
    }

    func startAvcPlayer() {
        if self.videoSocket != nil {
            self.avcSplitter?.startSplitter()
            self.avcDecoder?.start()
        } else {
            sleep20milSec()
            startAvcPlayer()
        }
    }

    func startPlayer() {
        if let videoSocket = self.videoSocket {
            videoSocket.setupSocket(url: self.urlSocket)
            videoSocket.startSocket()
        }
        startHevcPlayer()
        startAvcPlayer()
        self.videoView?.setupVideoView()
    }

    func releaseHevcPlayer() {
        // MINHTH-TODO
//        if let hevcDecoder = self.hevcDecoder {
//            hevcDecoder.stop()
//            self.hevcDecoder = nil
//        }
//        if let hevcSplitter = self.hevcSplitter {
//            hevcSplitter.stopSplitter()
//            self.hevcSplitter = nil
//        }
    }

    func releaseAvcPlayer() {
        if let avcDecoder = self.avcDecoder {
            avcDecoder.stop()
            self.avcDecoder = nil
        }
        if let avcSplitter = self.avcSplitter {
            avcSplitter.stopSplitter()
            self.avcSplitter = nil
        }
    }

    func releasePlayer() {
        self.isStop = true
        self.isPlaying = false
        if let videoView = self.videoView {
            self.videoView = nil
        }
        let rtpQueue = self.rtpQueue
        rtpQueue.empty()
        rtpQueue.emptyHevc()
    
        if let videoSocket = self.videoSocket {
            videoSocket.stopSocket()
            self.videoSocket = nil
        }
        releaseAvcPlayer()
        releaseHevcPlayer()
        onPlayerStopped()
    }

    func onPlayerPlaying() {
        if !self.isPlaying {
            self.isPlaying = true
//            DispatchQueue.main.async {
//                self.methodChannel?.invokeMethod("sourceLoadDone", arguments: true)
//            }
        }
        if let iPlayerState = self.iPlayerState {
            self.isPlaying = true
            iPlayerState.playing()
        }
    }

    func onPlayerLoading() {
        if let iPlayerState = self.iPlayerState {
            self.isPlaying = false
            iPlayerState.loading()
        }
    }

    func onPlayerStopped() {
        if let iPlayerState = self.iPlayerState {
            self.isPlaying = false
            iPlayerState.stopVideo()
        }
    }
}
