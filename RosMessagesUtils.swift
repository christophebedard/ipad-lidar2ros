//
//  RosMessagesUtils.swift
//  lidar2ros
//
//  Created by Christophe Bédard on 2021-01-10.
//  Copyright © 2021 Christophe Bedard. All rights reserved.
//

import Foundation
import ARKit

/// Utilities for dealing with and creating messages.
final class RosMessagesUtils {
    /// Get timestamp message from time value.
    public static func getTimestamp(_ time: Double) -> builtin_interfaces__Time {
        let sec = Int32(time)
        let nanosec = UInt32((time - Double(sec)) * 1000000)
        let time = builtin_interfaces__Time(sec: sec, nanosec: nanosec)
        return time
    }
    
    public static func depthMapToImage(time: Double, depth: CVPixelBuffer) -> sensor_msgs__Image {
        let header = std_msgs__Header(stamp: self.getTimestamp(time), frame_id: "world")
        let width = CVPixelBufferGetWidth(depth)
        let height = CVPixelBufferGetHeight(depth)
        let encoding = "mono8"
        let step = CVPixelBufferGetBytesPerRow(depth) / 4
        let data = self.pixelBufferToArray(buffer: depth, width: width, height: height, bytesPerRow: step)
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
