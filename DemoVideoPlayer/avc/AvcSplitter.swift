//
//  AvcSplitter.swift
//  DemoVideoPlayer
//
//  Created by TaHoangMinh on 7/10/24.
//

import Foundation
import Foundation

class AvcSplitter: Thread {
    var isRunning: Bool = false
    let player: VtsPlayer
    static let TAG = String(describing: AvcSplitter.self)
    static let NALUStartCode: [UInt8] = [0, 0, 0, 1]
    let gotParams: Bool = false
    let gotPPS: Bool = false
    let gotSPS: Bool = false
    var retry: Int = 0

    init(player: VtsPlayer) {
        self.player = player
        super.init()
    }

    func startSplitter() {
        start()
        self.isRunning = true
    }

    func stopSplitter() {
        self.isRunning = false
    }

    override func main() {
        do {
//            if self.isRunning {
//                while !self.player.isStop && self.isRunning {
            while (true) {
                    if let obj = self.player.rtpQueue.dequeue().1 {
                        self.retry = 0
                        splitRtpPackage(dataStruct: obj as! DataStruct)
                    } else if self.retry < 1 {
                        do {
                            Thread.sleep(forTimeInterval: 0.01)
                        } catch {
                            Thread.current.cancel()
                        }
                        self.retry += 1
                    } else {
                        self.retry = 0
                        self.player.rtpQueue.next()
                    }
                }
//            }
        } catch {
            print(error)
        }
    }

    func splitRtpPackage(dataStruct: DataStruct) {
        let videoData = dataStruct.getVideoData()
        let length = videoData.count
        
        if videoData[1] != 1 {
            stopSplitter()
        } else if length > 8 {
            let copyOfRange = Array(videoData[12...])
            let timeNum = bytesToInt(range: Array(videoData[2..<10]))
            let isParams = (copyOfRange[0] & 31) == 7
            onH264PackageReceived(dataStruct: DataStruct(data: AvcSplitter.concatenateByteArrays(a: AvcSplitter.NALUStartCode, b: copyOfRange), mTimeNum: Int64(timeNum), isParams: isParams))
        }
    }

    func onH264PackageReceived(dataStruct: DataStruct) {
        self.player.dataQueue.enqueue(dataStruct)
    }

    static func concatenateByteArrays(a: [UInt8], b: [UInt8]) -> [UInt8] {
        return a + b
    }

    func bytesToInt(range: [UInt8]) -> Int {
        let data = Data(range)
        return Int(data.withUnsafeBytes { $0.load(as: Int32.self).bigEndian })
    }
}
