//import UIKit
//import AVFoundation
//import Starscream
//
//struct StreamSettings {
//    var sps: Data
//    var pps: Data
//}
//
//class VideoPlayerViewController: UIViewController {
//    private var displayLayer: AVSampleBufferDisplayLayer!
//    private var socket: WebSocket!
//    private var isConfigured = false
//    private var sps: Data?
//    private var pps: Data?
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupDisplayLayer()
//        setupWebSocket()
//    }
//    
//    private func setupDisplayLayer() {
//        displayLayer = AVSampleBufferDisplayLayer()
//        displayLayer.videoGravity = .resizeAspect
//        displayLayer.frame = view.bounds
//        view.layer.addSublayer(displayLayer)
//    }
//    
//    private func setupWebSocket() {
//        guard let url = URL(string: "wss://rec03ihanoi.vtscloud.vn:443/evup/1727065882jPWLbJ/d12aa2a31aa4xyzummuv07lWh") else {
//            print("Invalid WebSocket URL")
//            return
//        }
//        var request = URLRequest(url: url)
//        request.timeoutInterval = 5
//        socket = WebSocket(request: request)
//        socket.delegate = self
//        socket.connect()
//    }
//    
//    private func configureDecoder(sps: Data, pps: Data) {
//        self.sps = sps
//        self.pps = pps
//        isConfigured = true
//    }
//    
//    private func decodeAndDisplay(videoData: Data) {
//        guard isConfigured, let sps = sps, let pps = pps else {
//            print("Decoder not configured")
//            return
//        }
//        
//        // Create format description
//        var formatDescription: CMFormatDescription?
//        let parameterSetPointers: [UnsafePointer<UInt8>] = [
//            sps.withUnsafeBytes { $0.baseAddress!.assumingMemoryBound(to: UInt8.self) },
//            pps.withUnsafeBytes { $0.baseAddress!.assumingMemoryBound(to: UInt8.self) }
//        ]
//        let parameterSetSizes: [Int] = [sps.count, pps.count]
//        
//        let status = CMVideoFormatDescriptionCreateFromH264ParameterSets(
//            allocator: kCFAllocatorDefault,
//            parameterSetCount: 2,
//            parameterSetPointers: parameterSetPointers,
//            parameterSetSizes: parameterSetSizes,
//            nalUnitHeaderLength: 4,
//            formatDescriptionOut: &formatDescription
//        )
//        
//        guard status == noErr, let formatDescription = formatDescription else {
//            print("Error creating format description: \(status)")
//            return
//        }
//        
//        // Create block buffer
//        var blockBuffer: CMBlockBuffer?
//        let blockStatus = CMBlockBufferCreateWithMemoryBlock(
//            allocator: kCFAllocatorDefault,
//            memoryBlock: nil,
//            blockLength: videoData.count,
//            blockAllocator: nil,
//            customBlockSource: nil,
//            offsetToData: 0,
//            dataLength: videoData.count,
//            flags: 0,
//            blockBufferOut: &blockBuffer
//        )
//        
//        guard blockStatus == kCMBlockBufferNoErr, let blockBuffer = blockBuffer else {
//            print("Error creating block buffer: \(blockStatus)")
//            return
//        }
//        
//        // Replace data bytes in block buffer
//        videoData.withUnsafeBytes { (videoDataPointer: UnsafeRawBufferPointer) in
//            let appendStatus = CMBlockBufferReplaceDataBytes(
//                with: videoDataPointer.baseAddress!,
//                blockBuffer: blockBuffer,
//                offsetIntoDestination: 0,
//                dataLength: videoData.count
//            )
//            
//            guard appendStatus == noErr else {
//                print("Error appending data to block buffer: \(appendStatus)")
//                return
//            }
//        }
//        
//        // Create sample buffer
//        var sampleBuffer: CMSampleBuffer?
//        var timingInfo = CMSampleTimingInfo(duration: .invalid, presentationTimeStamp: .zero, decodeTimeStamp: .invalid)
//        
//        let sampleStatus = CMSampleBufferCreateReady(
//            allocator: kCFAllocatorDefault,
//            dataBuffer: blockBuffer,
//            formatDescription: formatDescription,
//            sampleCount: 1,
//            sampleTimingEntryCount: 1,
//            sampleTimingArray: &timingInfo,
//            sampleSizeEntryCount: 1,
//            sampleSizeArray: [videoData.count],
//            sampleBufferOut: &sampleBuffer
//        )
//        
//        guard sampleStatus == noErr, let sampleBuffer = sampleBuffer else {
//            print("Error creating sample buffer: \(sampleStatus)")
//            return
//        }
//        
//        // Enqueue sample buffer to display layer
//        displayLayer.enqueue(sampleBuffer)
//    }
//    
//    private func receiveVideoData(_ data: Data) {
//        if !isConfigured, let streamSettings = getStreamSettings(from: data) {
//            configureDecoder(sps: streamSettings.sps, pps: streamSettings.pps)
//        } else {
//            decodeAndDisplay(videoData: data)
//        }
//    }
//    
//    private func getStreamSettings(from buffer: Data) -> StreamSettings? {
//        guard buffer.count > 4 else { return nil }
//        
//        let spsLength = buffer.count - 4
//        let spsData = buffer.prefix(spsLength)
//        let ppsData = buffer.suffix(from: spsLength)
//        
//        return StreamSettings(sps: spsData, pps: ppsData)
//    }
//}
//
//extension VideoPlayerViewController: WebSocketDelegate {
//    func didReceive(event: WebSocketEvent, client: any WebSocketClient) {
//        switch event {
//        case .connected(_):
//            print("WebSocket connected")
//            client.write(string: "")
//        case .disconnected(let reason, let code):
//            print("WebSocket disconnected: \(reason) with code: \(code)")
//        case .binary(let data):
//            receiveVideoData(data)
//        case .error(let error):
//            print("WebSocket error: \(error?.localizedDescription ?? "Unknown error")")
//        default:
//            break
//        }
//    }
//}
