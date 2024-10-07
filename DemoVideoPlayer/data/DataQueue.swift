//
//  DataQueue.swift
//  DemoVideoPlayer
//
//  Created by TaHoangMinh on 7/10/24.
//

import Foundation
import Foundation

public class DataQueue {
    private let lock = NSCondition()
    let dataQueue = LinkedList<DataStruct>()
    
    public func enqueue(_ dataStruct: DataStruct) {
        lock.lock()
        defer { lock.unlock() }
        
        dataQueue.append(dataStruct)
        lock.broadcast()
    }
    
    public func dequeue() -> DataStruct? {
        lock.lock()
        defer { lock.unlock() }
        
        if size() == 0 {
            return nil
        }
        return dataQueue.removeFirst()
    }
    
    public func size() -> Int {
        lock.lock()
        defer { lock.unlock() }
        
        return dataQueue.count
    }
    
    public func fill(_ size: Int) {
        lock.lock()
        defer { lock.unlock() }
        
        if dataQueue == nil {
            return
        }
        while dataQueue.count < size {
            lock.wait()
        }
    }
}
