//
//  RosMessages.swift
//  lidar2ros
//
//  Created by Christophe Bédard on 2021-01-09.
//  Copyright © 2021 Apple. All rights reserved.
//

import Foundation
import ARKit

/// builtin_interfaces/Time
struct builtin_interfaces__Time : Encodable {
    var sec: Int32
    var nanosec: UInt32
}

/// std_msgs/Header
struct std_msgs__Header : Encodable {
    var stamp: builtin_interfaces__Time
    var frame_id: String
}

/// sensor_msgs/Image
struct sensor_msgs__Image : Encodable {
    var header: std_msgs__Header
    var height: UInt32
    var width: UInt32
    var encoding: String
    var is_bigendian: UInt8
    var step: UInt32
    var data: [UInt8]
}

/// std_msgs/String
struct std_msgs__String : Encodable {
    var data: String
}

/// Utilities for dealing with and creating messages.
final class RosUtils {
    /// Get current timestamp message.
    public static func getTimestamp() -> builtin_interfaces__Time {
        let date = Date()
        let epochTime = date.timeIntervalSince1970
        let sec = Int32(epochTime)
        let nanosec = UInt32((epochTime - Double(sec)) * 1000000)
        let time = builtin_interfaces__Time(sec: sec, nanosec: nanosec)
        return time
    }
    
    public static func depthMapToImage(_ depth: CVPixelBuffer) -> sensor_msgs__Image {
        let header = std_msgs__Header(stamp: RosUtils.getTimestamp(), frame_id: "world")
        let width = CVPixelBufferGetWidth(depth)
        let height = CVPixelBufferGetHeight(depth)
        let encoding = "mono8"
        let step = CVPixelBufferGetBytesPerRow(depth) / 4
        let data = RosUtils.pixelBufferToArray(buffer: depth, width: width, height: height, bytesPerRow: step)
        return sensor_msgs__Image(header: header, height: UInt32(height), width: UInt32(width), encoding: encoding, is_bigendian: 0, step: UInt32(step), data: data)
    }
    
    private static func pixelBufferToArray(buffer: CVPixelBuffer, width: Int, height: Int, bytesPerRow: Int) -> [UInt8] {
            var imgArray: [UInt8] = []

            // Lock buffer
            CVPixelBufferLockBaseAddress(buffer, .readOnly)

            // Unlock buffer upon exiting
            defer {
                CVPixelBufferUnlockBaseAddress(buffer, .readOnly)
            }

            if let baseAddress = CVPixelBufferGetBaseAddressOfPlane(buffer, 0) {
                let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)
                for y in (0..<height) {
                    for x in (0..<width) {
                        let ix = y * bytesPerRow * 4 + x * 4
                        imgArray.append(buffer[ix + 2])
                    }
                }
            }
            return imgArray
        }
}
