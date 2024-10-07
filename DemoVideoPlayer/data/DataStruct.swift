//
//  DataStruct.swift
//  DemoVideoPlayer
//
//  Created by TaHoangMinh on 7/10/24.
//

import Foundation
import Foundation

public struct DataStruct: Comparable {
    public var isParams: Bool
    public var mTimeNum: Int64
    public let mVideoData: [UInt8]
    
    public init(data: [UInt8]) {
        self.mVideoData = data
        self.mTimeNum = 0
        self.isParams = false
    }
    
    public init(data: [UInt8], mTimeNum: Int64, isParams: Bool) {
        self.mVideoData = data
        self.mTimeNum = mTimeNum
        self.isParams = isParams
    }
    
    public func getVideoData() -> [UInt8] {
        return self.mVideoData
    }
    
    public static func < (lhs: DataStruct, rhs: DataStruct) -> Bool {
        return lhs.mTimeNum < rhs.mTimeNum
    }
    
    public static func == (lhs: DataStruct, rhs: DataStruct) -> Bool {
        return lhs.mTimeNum == rhs.mTimeNum
    }
}
