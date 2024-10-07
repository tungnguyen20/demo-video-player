import Foundation
import AVFoundation
import Starscream

class AvcWebSocketStreamPlayer: NSObject {
    private var displayLayer: AVSampleBufferDisplayLayer
    private var socket: WebSocket
    weak var delegate: AvcWebSocketStreamPlayerDelegate?
    
    private var videoFormatDescription: CMVideoFormatDescription?
    private var currentPTS: CMTime = .zero
    
    init(webSocketURL: URL, videoView: UIView) {
        var request = URLRequest(url: webSocketURL)
        request.timeoutInterval = 5
        self.socket = WebSocket(request: request)
        
        self.displayLayer = AVSampleBufferDisplayLayer()
        self.displayLayer.videoGravity = .resizeAspect
        self.displayLayer.frame = videoView.bounds
        
        super.init()
        
        self.socket.delegate = self
        videoView.layer.addSublayer(self.displayLayer)
    }
    
    func start() {
        print("Connecting to WebSocket...")
        socket.connect()
    }
    
    func stop() {
        print("Disconnecting WebSocket and stopping player...")
        socket.disconnect()
        displayLayer.flushAndRemoveImage()
    }
    
    func decodeAndDisplayH264Frames(_ data: Data) {
        // Your H.264 frame data, you should provide this from your source
        let h264Data = data
        
        guard let streamSettings = extractSPSAndPPS(from: h264Data.map { $0 }) else {
            print("Failed to extract SPS and PPS")
            return
        }
        
        guard let sps = streamSettings.sps, let pps = streamSettings.pps else {
            print("SPS or PPS is nil")
            return
        }
        
        // Convert SPS and PPS to byte pointers (needed for CMVideoFormatDescription)
        let spsPointer = UnsafePointer<UInt8>((sps as NSData).bytes.bindMemory(to: UInt8.self, capacity: sps.count))
        let ppsPointer = UnsafePointer<UInt8>((pps as NSData).bytes.bindMemory(to: UInt8.self, capacity: pps.count))

        
        // Create CMFormatDescription
        var formatDesc: CMFormatDescription?
        let status = CMVideoFormatDescriptionCreateFromH264ParameterSets(
            allocator: kCFAllocatorDefault,
            parameterSetCount: 2,
            parameterSetPointers: [spsPointer, ppsPointer], // SPS, PPS pointers
            parameterSetSizes: [sps.count, pps.count],           // SPS, PPS sizes
            nalUnitHeaderLength: 4,
            formatDescriptionOut: &formatDesc
        )

        print(status)
        
        guard status == noErr, let formatDescription = formatDesc else {
            print("Failed to create format description")
            return
        }

        // Create a CMSampleBuffer with H.264 data
        var blockBuffer: CMBlockBuffer?
        CMBlockBufferCreateWithMemoryBlock(
            allocator: kCFAllocatorDefault,
            memoryBlock: nil,
            blockLength: h264Data.count,
            blockAllocator: kCFAllocatorDefault,
            customBlockSource: nil,
            offsetToData: 0,
            dataLength: h264Data.count,
            flags: 0,
            blockBufferOut: &blockBuffer
        )

        guard let buffer = blockBuffer else {
            print("Failed to create block buffer")
            return
        }

        var sampleBuffer: CMSampleBuffer?
        var timingInfo = CMSampleTimingInfo(duration: CMTime.invalid, presentationTimeStamp: CMTime.zero, decodeTimeStamp: CMTime.invalid)

        CMSampleBufferCreate(
            allocator: kCFAllocatorDefault,
            dataBuffer: buffer,
            dataReady: true,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: formatDescription,
            sampleCount: 1,
            sampleTimingEntryCount: 1,
            sampleTimingArray: &timingInfo,
            sampleSizeEntryCount: 1,
            sampleSizeArray: [h264Data.count],
            sampleBufferOut: &sampleBuffer
        )

        guard let sample = sampleBuffer else {
            print("Failed to create sample buffer")
            return
        }

        // Enqueue sample buffer to the display layer
        displayLayer.enqueue(sample)
    }
}

extension AvcWebSocketStreamPlayer: WebSocketDelegate {
    func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        switch event {
        case .binary(let data):
            // print data in hex
//            print(data.map { String(format: "%02x", $0) }.joined(separator: " "))
            decodeAndDisplayH264Frames(data)
        case .text(let string):
            print("Websocket \(string)")
        case .connected(_):
            print("WebSocket connected")
            client.write(string: "Hello")
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

protocol AvcWebSocketStreamPlayerDelegate: AnyObject {
    func playerDidConnect()
    func playerDidDisconnect()
    func playerDidEncounterError(_ error: Error)
}

struct StreamSettings {
    var sps: Data?
    var pps: Data?
}

func extractSPSAndPPS(from buffer: [UInt8]) -> StreamSettings? {
    if buffer.count < 5 {
        return nil
    }
    let sps = [Array(buffer.dropFirst(4)).first!]
    let pps = Array(buffer.dropFirst(5))
    return StreamSettings(sps: Data(sps), pps: Data(pps))
}
