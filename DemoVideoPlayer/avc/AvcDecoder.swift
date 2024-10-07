//
//  AvcDecoder.swift
//  DemoVideoPlayer
//
//  Created by TaHoangMinh on 7/10/24.
//

import Foundation
import Foundation
import AVFoundation

class AvcDecoder {
    var mWorker: Worker?
    let vtsPlayer: VtsPlayer
    
    init(vtsPlayer: VtsPlayer) {
        self.vtsPlayer = vtsPlayer
    }
    
    func start() {
        if mWorker == nil {
            let worker = Worker()
            mWorker = worker
            worker.setRunning(true)
            worker.start()
        }
    }
    
    func stop() {
        if let worker = mWorker {
            worker.setRunning(false)
            mWorker = nil
        }
    }
    
    class Worker: Thread {
//        private var mCodec: AVCodecContext?
        private let mIsRunning = AtomicBool(false)
        private let mIsConfigured = AtomicBool(false)
        private let sps = Data()
        private let pps = Data()
        private let mTimeoutUs: Int64 = 10000
        
        func setRunning(_ isRunning: Bool) {
            mIsRunning.set(isRunning)
        }
        
        private func sleep2Sec() {
            Task {
                do {
                    try await Task.sleep(nanoseconds: 2_000_000_000)
                } catch {
                    print(error)
                }
            }
        }
        
        private func configure(layer: CALayer, width: Int, height: Int, csd0: Data, csd1: Data) {
            // Chuyển đổi phần cấu hình codec từ Java sang Swift là một quá trình phức tạp
            // và cần được thực hiện cẩn thận với AVFoundation
            // Đây chỉ là một phiên bản giả định
            if mIsConfigured.get() { return }
            
            do {
                let decompressSettings = [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
                    kCVPixelBufferWidthKey as String: width,
                    kCVPixelBufferHeightKey as String: height
                ] as [String : Any]
                
                // Giả định việc tạo và cấu hình codec
                // mCodec = try AVCodecContext(...)
                
                mIsConfigured.set(true)
            } catch {
                print(error)
                sleep2Sec()
            }
        }
        
        private func decodeAvc2(input: Data, offset: Int, size: Int, presentationTimeUs: Int64, flags: Int) {
            // Chuyển đổi logic giải mã từ Java sang Swift
            // Đây chỉ là một phiên bản giả định
            if mIsConfigured.get() && mIsRunning.get() {
                // Thực hiện giải mã ở đây
            }
        }
        
        override func main() {
            // Chuyển đổi logic chính của thread từ Java sang Swift
            // Đây chỉ là một phiên bản giả định
            while mIsRunning.get() {
                if mIsConfigured.get() {
                    // Xử lý giải mã
                } else {
                    // Xử lý dữ liệu từ queue
                }
            }
            
            // Dọn dẹp tài nguyên
        }
    }
}

class AtomicBool {
    private var value: Bool
    private let lock = NSLock()
    
    init(_ initialValue: Bool) {
        value = initialValue
    }
    
    func get() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
    
    func set(_ newValue: Bool) {
        lock.lock()
        defer { lock.unlock() }
        value = newValue
    }
}
