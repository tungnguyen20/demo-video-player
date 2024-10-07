//
//  HEVCPlayer.swift
//  PN
//
//  Created by Tung on 5/10/24.
//  Copyright © 2024 PN. All rights reserved.
//

import Foundation
import MobileVLCKit
import Starscream

class HevcWebSocketStreamPlayer: NSObject {
    private var mediaPlayer: VLCMediaPlayer
    private var socket: WebSocket
    weak var delegate: HevcWebSocketStreamPlayerDelegate?
    
    private let fileManager = FileManager.default
    private var inputStream: InputStream?
    private var outputStream: OutputStream?
    
    // HevcSplitter properties
    private static let NALUStartCode: [UInt8] = [0, 0, 0, 1]
    private var countIdr: Int = 0
    private var countPframe: Int = 0
    private var idrSet: Data?
    private var nalTemp: Int = 0
    private var pSet: Data?
    private var vspSet: Data?
    private var gotParams: Bool = false
    private var gotVPS: Bool = false
    private var gotPPS: Bool = false
    private var gotSPS: Bool = false
    private var retry: Int = 0
    
    init(webSocketURL: URL, videoView: UIView) {
        self.mediaPlayer = VLCMediaPlayer()
        self.mediaPlayer.drawable = videoView
        
        // Initialize WebSocket
        var request = URLRequest(url: webSocketURL)
        request.timeoutInterval = 5
        self.socket = WebSocket(request: request)
        
        // Create streams for feeding data to VLC
        var inputStream: InputStream?
        var outputStream: OutputStream?
        Stream.getBoundStreams(withBufferSize: 1024 * 1024, inputStream: &inputStream, outputStream: &outputStream)
        
        self.inputStream = inputStream
        self.outputStream = outputStream
        
        super.init()
        
        self.socket.delegate = self
        self.mediaPlayer.delegate = self
    }
    
    func start() {
        print("Connecting to WebSocket...")
        inputStream?.open()
        outputStream?.open()
        socket.connect()
        
        // Set up VLCMedia with the InputStream
        if let inputStream = inputStream {
            let media = VLCMedia(stream: inputStream)
            mediaPlayer.media = media
            
            // Set some media options that might help
            media.addOption("--no-audio")
            media.addOption("--network-caching=1000")
            media.addOption("--codec=hevc")
            
            print("Starting playback...")
            mediaPlayer.play()
        }
    }
    
    func stop() {
        print("Disconnecting WebSocket and stopping player...")
        socket.disconnect()
        mediaPlayer.stop()
        inputStream?.close()
        outputStream?.close()
    }
    
    private func splitRtpPackage(_ hevcStruct: DataStruct) {
        guard let videoData = hevcStruct.videoData else { return }
        
        let headerSize = 12
        guard videoData.count > headerSize else { return }
        
        let copyOfRange = Array(videoData[12...])
        let timestampData = Array(videoData[2..<10])
        let timestamp = bytesToInt(timestampData)
        
        // print copy of Range in hex
        print(videoData.map { String(format: "%02X ", $0) }.joined())
        
        // HEVC NAL type is in the first byte, shifted right by 1 bit
        let nalType = (videoData[0] >> 1) & 0x3F
        print("NAL Type: \(nalType)")
        
        if nalType <= 9 || nalType >= 16 {
            if ((nalType <= 21 || nalType >= 32) && nalType <= 40) {
                if nalType != 0 && nalType != 1 {
                    if nalType != 19 && nalType != 20 {
                        switch nalType {
                        case 32: // VPS
                            vspSet = nil
                            vspSet = Data(HevcWebSocketStreamPlayer.NALUStartCode + copyOfRange)
                            gotVPS = true
                            gotSPS = false
                            gotPPS = false
                        case 33: // SPS
                            if gotVPS {
                                vspSet = concatenateData(vspSet, Data(HevcWebSocketStreamPlayer.NALUStartCode + copyOfRange))
                                gotSPS = true
                            }
                        case 34: // PPS
                            if gotSPS {
                                let concatenatedData = concatenateData(vspSet, Data(HevcWebSocketStreamPlayer.NALUStartCode + copyOfRange))
                                vspSet = concatenatedData
                                gotPPS = true
                                gotVPS = false
                                gotSPS = false
                                onHevcPackageReceived(DataStruct(concatenatedData, timestamp, true))
                            }
                        default:
                            break
                        }
                    } else if gotPPS {
                        if nalTemp != 19 && nalTemp != 20 {
                            countIdr = 1
                            idrSet = nil
                            idrSet = Data(HevcWebSocketStreamPlayer.NALUStartCode + copyOfRange)
                        } else {
                            idrSet = concatenateData(idrSet, Data(HevcWebSocketStreamPlayer.NALUStartCode + copyOfRange))
                            countIdr += 1
                        }
                    }
                } else if gotPPS {
                    if nalTemp == 19 || nalTemp == 20 {
                        onHevcPackageReceived(DataStruct(idrSet, timestamp, false))
                        countPframe = 1
                        if countIdr == 1 {
                            onHevcPackageReceived(DataStruct(Data(HevcWebSocketStreamPlayer.NALUStartCode + copyOfRange), timestamp, false))
                        } else if countIdr > 1 {
                            pSet = nil
                            pSet = Data(HevcWebSocketStreamPlayer.NALUStartCode + copyOfRange)
                        }
                    } else {
                        if countIdr == 1 {
                            onHevcPackageReceived(DataStruct(Data(HevcWebSocketStreamPlayer.NALUStartCode + copyOfRange), timestamp, false))
                        } else if countIdr > 1 {
                            if countPframe > 0 {
                                if countPframe < countIdr, let pSetData = pSet {
                                    let concatenatedData = concatenateData(pSetData, Data(HevcWebSocketStreamPlayer.NALUStartCode + copyOfRange))
                                    pSet = concatenatedData
                                    countPframe += 1
                                    if countPframe == countIdr {
                                        onHevcPackageReceived(DataStruct(concatenatedData, timestamp, false))
                                        countPframe -= countIdr
                                    }
                                }
                            } else if countPframe == 0 {
                                pSet = nil
                                pSet = Data(HevcWebSocketStreamPlayer.NALUStartCode + copyOfRange)
                                countPframe += 1
                            }
                        }
                    }
                }
                nalTemp = Int(nalType)
            }
        }
    }
    
    private func onHevcPackageReceived(_ dataStruct: DataStruct) {
        // Write the processed HEVC package to the OutputStream
        if let data = dataStruct.videoData {
            data.withUnsafeBytes { (bufferPointer) in
                let buffer = bufferPointer.bindMemory(to: UInt8.self)
                outputStream?.write(buffer.baseAddress!, maxLength: data.count)
            }
        }
    }
    
    private func concatenateData(_ a: Data?, _ b: Data) -> Data {
        if let a = a {
            var result = a
            result.append(b)
            return result
        }
        return b
    }
    
    private func bytesToInt(_ bytes: [UInt8]) -> Int64 {
        return Int64(bytes.withUnsafeBytes { $0.load(as: UInt32.self) })
    }
}

extension HevcWebSocketStreamPlayer: WebSocketDelegate {
    func didReceive(event: WebSocketEvent, client: any WebSocketClient) {
        switch event {
        case .binary(let data):
            let dataStruct = DataStruct(data, Int64(Date().timeIntervalSince1970 * 1000), false)
            splitRtpPackage(dataStruct)
        case .connected(_):
            print("WebSocket connected")
            client.write(string: "")
            delegate?.playerDidConnect()
        case .disconnected(_, _):
            print("WebSocket disconnected")
            delegate?.playerDidDisconnect()
        case .error(let error):
            print("WebSocket error: \(error?.localizedDescription ?? "Unknown error")")
            delegate?.playerDidEncounterError(error ?? NSError(domain: "WebSocket", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unknown error"]))
        default:
            break
        }
    }
}

extension HevcWebSocketStreamPlayer: VLCMediaPlayerDelegate {
    func mediaPlayerStateChanged(_ aNotification: Notification) {
        print("VLC Media Player state changed to: \(mediaPlayer.state.rawValue)")
        if mediaPlayer.state == .error {
            print("VLC Media Player error:")
        } else if mediaPlayer.state == .playing {
            print("VLC Media Player started playing")
            delegate?.playerDidStartPlaying()
        }
    }
}

protocol HevcWebSocketStreamPlayerDelegate: AnyObject {
    func playerDidConnect()
    func playerDidDisconnect()
    func playerDidStartPlaying()
    func playerDidEncounterError(_ error: Error)
}
