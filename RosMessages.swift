//
//  RosMessages.swift
//  lidar2ros
//
//  Created by Christophe Bédard on 2021-01-09.
//  Copyright © 2021 Christophe Bedard. All rights reserved.
//

import Foundation

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

/// sensor_msgs/PointField
struct sensor_msgs__PointField : Encodable {
    var name: String
    var offset: UInt32
    var datatype: UInt8
    var count: UInt32
    
    static let DATATYPE_INT8: UInt8 = 1
    static let DATATYPE_UINT8: UInt8 = 2
    static let DATATYPE_INT16: UInt8 = 3
    static let DATATYPE_UINT16: UInt8 = 4
    static let DATATYPE_INT32: UInt8 = 5
    static let DATATYPE_UINT32: UInt8 = 6
    static let DATATYPE_FLOAT32: UInt8 = 7
    static let DATATYPE_FLOAT64: UInt8 = 8
}

/// sensor_msgs/PointCloud2
struct sensor_msgs__PointCloud2 : Encodable {
    var header: std_msgs__Header
    var height: UInt32
    var width: UInt32
    var fields: [sensor_msgs__PointField]
    var is_bigendian: Bool
    var point_step: UInt32
    var row_step: UInt32
    var data: [UInt8]
    var is_dense: Bool
}

/// std_msgs/String
struct std_msgs__String : Encodable {
    var data: String
}
