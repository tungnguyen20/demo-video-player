import Foundation
import Starscream

public class VideoSocket: NSObject, WebSocketDelegate {

    
    public static let TAG = "VideoSocket"
    public static var linkIndex: Int64 = 0
    
    public var httpClient: URLSession
    public var socket_state: SOCKET_STATE
    public var vtsPlayer: UIView
    public var webSocket: WebSocket?
    
    public var monitorRtpEnqueue: (() -> Void)?
    public var sourceUrl: String = ""
    
    public enum SOCKET_STATE {
        case SOCKET_INVALID
        case SOCKET_STARTED
        case SOCKET_RECONNECTING
        case SOCKET_CONNECTED
        case SOCKET_STOPPED
    }
    
    public init(vtsPlayer: UIView) {
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
    
    public func setupSocket(url: String) {
        self.sourceUrl = url
    }
    
    public func startSocket() {
        if socket_state != .SOCKET_STARTED {
            connectSocket()
            socket_state = .SOCKET_STARTED
        }
    }
    
    public func stopSocket() {
        if socket_state != .SOCKET_STOPPED {
            webSocket?.disconnect()
            webSocket = nil
            socket_state = .SOCKET_STOPPED
        }
    }
    
    public func reconnectSocket() {
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
    
    public func didReceive(event: Starscream.WebSocketEvent, client: any Starscream.WebSocketClient) {
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
//                try vtsPlayer.getRtpQueue().enqueue(VideoSocket.linkIndex, DataStruct(data))
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
