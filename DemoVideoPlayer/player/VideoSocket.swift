import Foundation
import Starscream

class VideoSocket: NSObject, WebSocketDelegate {

    
    static let TAG = "VideoSocket"
    static var linkIndex: Int64 = 0
    
    var httpClient: URLSession
    var socket_state: SOCKET_STATE
    var vtsPlayer: VtsPlayer! = nil
    var webSocket: WebSocket?
    
    var monitorRtpEnqueue: (() -> Void)?
    var sourceUrl: String = ""
    
    enum SOCKET_STATE {
        case SOCKET_INVALID
        case SOCKET_STARTED
        case SOCKET_RECONNECTING
        case SOCKET_CONNECTED
        case SOCKET_STOPPED
    }
    
    init(vtsPlayer: VtsPlayer) {
        self.vtsPlayer = vtsPlayer
        let config = URLSessionConfiguration.default
        self.httpClient = URLSession(configuration: config)
        self.socket_state = .SOCKET_INVALID
        VideoSocket.linkIndex = 0
        
        super.init()
        
        self.monitorRtpEnqueue = { [weak self] in
            guard let self = self else { return }
            if self.socket_state != .SOCKET_STOPPED {
                self.reconnectSocket()
            }
        }
    }
    
    func setupSocket(url: String) {
        self.sourceUrl = url
    }
    
    func startSocket() {
        if socket_state != .SOCKET_STARTED {
            connectSocket()
            socket_state = .SOCKET_STARTED
        }
    }
    
    func stopSocket() {
        if socket_state != .SOCKET_STOPPED {
            webSocket?.disconnect()
            webSocket = nil
            socket_state = .SOCKET_STOPPED
        }
    }
    
    func reconnectSocket() {
        if socket_state != .SOCKET_STOPPED {
            webSocket?.disconnect()
            webSocket = nil
            socket_state = .SOCKET_RECONNECTING
            connectSocket()
        }
    }
    
    private func connectSocket() {
        guard socket_state != .SOCKET_CONNECTED, webSocket == nil, let url = URL(string: sourceUrl) else { return }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        
        webSocket = WebSocket(request: request)
        webSocket?.delegate = self
        webSocket?.connect()
    }
    
    // MARK: - WebSocketDelegate
    
    func didReceive(event: Starscream.WebSocketEvent, client: any Starscream.WebSocketClient) {
        switch event {
        case .connected(_):
            socket_state = .SOCKET_CONNECTED
            client.write(string: "Hello")
        case .disconnected(_, _):
            reconnectSocket()
        case .text(_):
            break
        case .binary(let data):
            handleBinaryMessage(data: data)
        case .ping(_), .pong(_), .viabilityChanged(_), .reconnectSuggested(_), .cancelled:
            break
        case .error(let error):
            print("WebSocket error: \(error?.localizedDescription ?? "Unknown error")")
            reconnectSocket()
        case .peerClosed:
            break
        }
    }
    
    private func handleBinaryMessage(data: Data) {
        guard data.count >= 2 else { return }
        let firstByte = data[1]
        
        if socket_state == .SOCKET_STARTED {
            socket_state = .SOCKET_CONNECTED
            
            if firstByte == 1 {
                // MINHTH - TODO
//                vtsPlayer.releaseHevcPlayer()
            } else if firstByte == 2 {
                // MINHTH - TODO
//                vtsPlayer.releaseAvcPlayer()
            } else {
                // MINHTH - TODO
//                vtsPlayer.releasePlayer()
                return
            }
        }
        
        do {
            if firstByte == 1 {
                // MINHTH - TODO
                print("MINHTH - firstByte = 1")
                let uintData = [UInt8](data)
                try vtsPlayer.getRtpQueue().enqueue(VideoSocket.linkIndex, DataStruct(data: uintData))
            } else if firstByte == 2 {
                // MINHTH - TODO
//                try vtsPlayer.getRtpQueue().enqueueHevc(VideoSocket.linkIndex, DataStruct(data))
            }
            VideoSocket.linkIndex += 1
        } catch {
            print("Error handling binary message: \(error.localizedDescription)")
        }
    }
}
