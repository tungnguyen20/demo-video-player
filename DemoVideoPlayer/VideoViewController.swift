import UIKit
import MobileVLCKit
import Starscream

class VideoViewController: UIViewController {

    private var videoView: UIView!
//    private var player: HevcWebSocketStreamPlayer?
    private var player: AvcWebSocketStreamPlayer?
    private var startStopButton: UIButton!
    private var activityIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        VLCLibrary.shared().debugLogging = true
        VLCLibrary.shared().debugLoggingLevel = 3
        
        setupUI()
//        setupPlayer()
        openSocket()
    }

    private func setupUI() {
        // Set up video view
        videoView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height - 200))
        videoView.backgroundColor = .clear
        view.addSubview(videoView)

        // Set up start/stop button
        startStopButton = UIButton(type: .system)
        startStopButton.setTitle("Start", for: .normal)
        startStopButton.frame = CGRect(x: 20, y: 100, width: 100, height: 40)
        startStopButton.addTarget(self, action: #selector(startStopTapped), for: .touchUpInside)
        view.addSubview(startStopButton)

        // Set up activity indicator
        activityIndicator = UIActivityIndicatorView(style: .white)
        activityIndicator.center = videoView.center
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
    }
    
    
    var videoSocket: VideoSocket! = nil
    private func openSocket() {
        videoSocket = VideoSocket.init(vtsPlayer: UIView.init())
        videoSocket.setupSocket(url: "wss://rec03ihanoi.vtscloud.vn:443/evup/1727065882jPWLbJ/d12aa2a31aa4xyzummuv07lWh")
        videoSocket.startSocket()
    }
    
    private func setupPlayer() {
        guard let wsURL = URL(string: "wss://rec03ihanoi.vtscloud.vn:443/evup/1727065882jPWLbJ/d12aa2a31aa4xyzummuv07lWh") else {
            print("Invalid WebSocket URL")
            return
        }
//        player = HevcWebSocketStreamPlayer(webSocketURL: wsURL, videoView: videoView)
//        player = AvcWebSocketStreamPlayer(webSocketURL: wsURL, videoView: videoView)
        player?.delegate = self
    }

    @objc private func startStopTapped() {
        if startStopButton.title(for: .normal) == "Start" {
            startPlayback()
        } else {
            stopPlayback()
        }
    }

    private func startPlayback() {
        activityIndicator.startAnimating()
        player?.start()
        startStopButton.setTitle("Stop", for: .normal)
    }

    private func stopPlayback() {
        player?.stop()
        startStopButton.setTitle("Start", for: .normal)
        activityIndicator.stopAnimating()
    }
}

extension VideoViewController: HevcWebSocketStreamPlayerDelegate, AvcWebSocketStreamPlayerDelegate {
    func playerDidConnect() {
        print("WebSocket connected")
    }

    func playerDidDisconnect() {
        print("WebSocket disconnected")
        DispatchQueue.main.async {
            self.stopPlayback()
        }
    }

    func playerDidStartPlaying() {
        print("Video started playing")
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
        }
    }

    func playerDidEncounterError(_ error: Error) {
        print("Player error: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.stopPlayback()
            // You might want to show an alert to the user here
        }
    }
}

struct DataStruct {
    var videoData: Data?
    var timestamp: Int64
    var isParams: Bool
    
    init(_ data: Data?, _ timestamp: Int64, _ isParams: Bool) {
        self.videoData = data
        self.timestamp = timestamp
        self.isParams = isParams
    }
}
