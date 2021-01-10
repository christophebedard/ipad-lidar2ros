//
//  RosMessagesUtils.swift
//  lidar2ros
//
//  Created by Christophe Bédard on 2021-01-10.
//  Copyright © 2021 Christophe Bedard. All rights reserved.
//

import Foundation
import ARKit

/// Conversion from Float to array of bytes ([UInt8]).
extension Float {
   var bytes: [UInt8] {
       withUnsafeBytes(of: self, Array.init)
   }
}

/// Utilities for dealing with and creating messages.
final class RosMessagesUtils {
    /// Get builtin_interfaces/Time message from time value.
    public static func getTimestamp(_ time: Double) -> builtin_interfaces__Time {
        let sec = Int32(time)
        let nanosec = UInt32((time - Double(sec)) * 1000000)
        let time = builtin_interfaces__Time(sec: sec, nanosec: nanosec)
        return time
    }
    
    /// Get sensor_msgs/PointCloud2 message from time and points.
    public static func pointsToPointCloud2(time: Double, points: [vector_float3]) -> sensor_msgs__PointCloud2 {
        let header = std_msgs__Header(stamp: self.getTimestamp(time), frame_id: "world")
        // Unordered point cloud: width * height = count * 1
        let height = UInt32(1)
        let width = UInt32(points.count)
        // Each value takes 4 bytes (float = 32 bits = 4 bytes)
        let fields = [
            sensor_msgs__PointField(name: "x", offset: UInt32(0), datatype: sensor_msgs__PointField.DATATYPE_FLOAT32, count: UInt32(1)),
            sensor_msgs__PointField(name: "y", offset: UInt32(4), datatype: sensor_msgs__PointField.DATATYPE_FLOAT32, count: UInt32(1)),
            sensor_msgs__PointField(name: "z", offset: UInt32(8), datatype: sensor_msgs__PointField.DATATYPE_FLOAT32, count: UInt32(1)),
        ]
        let is_bigendian = false
        // 3 elements (x,y,z) * 4 bytes per element (float = 32 bits = 4 bytes)
        let point_step = UInt32(3 * 4)
        let row_step = width * point_step
        let data = self.flattenVectorFloat3Array(points)
        let is_dense = false
        return sensor_msgs__PointCloud2(header: header, height: height, width: width, fields: fields, is_bigendian: is_bigendian, point_step: point_step, row_step: row_step, data: data, is_dense: is_dense)
    }
    
    private static func flattenVectorFloat3Array(_ array: [vector_float3]) -> [UInt8] {
        return array.flatMap { $0.x.bytes + $0.y.bytes + $0.z.bytes }
    }
    
    /// Get sensor_msgs/Image message from time and depth map.
    public static func depthMapToImage(time: Double, depthMap: CVPixelBuffer) -> sensor_msgs__Image {
        let header = std_msgs__Header(stamp: self.getTimestamp(time), frame_id: "world")
        let width = CVPixelBufferGetWidth(depthMap)
        let height = CVPixelBufferGetHeight(depthMap)
        let encoding = "mono8"
        let is_bigendian = UInt8(0)
        let step = CVPixelBufferGetBytesPerRow(depthMap) / 4
        let data = self.pixelBufferToArray(buffer: depthMap, width: width, height: height, bytesPerRow: step)
        return sensor_msgs__Image(header: header, height: UInt32(height), width: UInt32(width), encoding: encoding, is_bigendian: is_bigendian, step: UInt32(step), data: data)
    }
    
    private static func pixelBufferToArray(buffer: CVPixelBuffer, width: Int, height: Int, bytesPerRow: Int) -> [UInt8] {
        // Lock buffer
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        // Unlock buffer upon exiting
        defer {
            CVPixelBufferUnlockBaseAddress(buffer, .readOnly)
        }

        var imgArray: [UInt8] = []
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
