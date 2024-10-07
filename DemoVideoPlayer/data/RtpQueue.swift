//
//  RtpQueue.swift
//  DemoVideoPlayer
//
//  Created by TaHoangMinh on 7/10/24.
//

import Foundation

class RtpQueue {
    private let lock = NSLock()
    private let condition = NSCondition()
    
    var nextPackageNumber: Int64 = 0
    var rtpQueue: [Int64: DataStruct] = [:]
    var nextPackageNumberAudio: Int64 = 0
    var nextPackageNumberHevc: Int64 = 0
    var rtpQueueHevc: [Int64: DataStruct] = [:]
    
    func enqueue(_ index: Int64, _ dataStruct: DataStruct) -> Bool {
//        lock.lock()
//        defer { lock.unlock() }
        
        if rtpQueue.count > 100 {
            rtpQueue.removeAll()
            nextPackageNumber = index
        }
        
        if index >= nextPackageNumber {
            rtpQueue[index] = dataStruct
            condition.broadcast()
            return true
        } else {
            return false
        }
    }
    
    func dequeue() -> (Int64, DataStruct?) {
//        lock.lock()
//        defer { lock.unlock() }
        
        while rtpQueue.isEmpty {
            condition.wait()
        }
        
        var pair: (Int64, DataStruct?) = (nextPackageNumber, nil)
        
        if let dataStruct = rtpQueue[nextPackageNumber] {
            pair = (nextPackageNumber, dataStruct)
            rtpQueue.removeValue(forKey: nextPackageNumber)
            nextPackageNumber += 1
        }
        
        return pair
    }
    
    func next() {
        lock.lock()
        defer { lock.unlock() }
        
        rtpQueue.removeValue(forKey: nextPackageNumber)
        
        if let firstKey = rtpQueue.keys.sorted().first {
            nextPackageNumber = firstKey
        } else {
            nextPackageNumber += 1
        }
    }
    
    func empty() {
        lock.lock()
        defer { lock.unlock() }
        
        rtpQueue.removeAll()
    }
    
    func enqueueHevc(_ index: Int64, _ dataStruct: DataStruct) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        if rtpQueueHevc.count > 100 {
            rtpQueueHevc.removeAll()
            nextPackageNumberHevc = index
        }
        
        if index >= nextPackageNumberHevc {
            rtpQueueHevc[index] = dataStruct
            condition.broadcast()
            return true
        } else {
            return false
        }
    }
    
    func dequeueHevc() -> (Int64, DataStruct?) {
        lock.lock()
        defer { lock.unlock() }
        
        while rtpQueueHevc.isEmpty {
            condition.wait()
        }
        
        var pair: (Int64, DataStruct?) = (nextPackageNumberHevc, nil)
        
        if let dataStruct = rtpQueueHevc[nextPackageNumberHevc] {
            pair = (nextPackageNumberHevc, dataStruct)
            rtpQueueHevc.removeValue(forKey: nextPackageNumberHevc)
            nextPackageNumberHevc += 1
        }
        
        return pair
    }
    
    func nextHevc() {
        lock.lock()
        defer { lock.unlock() }
        
        rtpQueueHevc.removeValue(forKey: nextPackageNumberHevc)
        
        if let firstKey = rtpQueueHevc.keys.sorted().first {
            nextPackageNumberHevc = firstKey
        } else {
            nextPackageNumberHevc += 1
        }
    }
    
    func emptyHevc() {
        lock.lock()
        defer { lock.unlock() }
        
        rtpQueueHevc.removeAll()
    }
}
