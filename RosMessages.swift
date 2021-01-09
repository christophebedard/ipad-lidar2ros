//
//  RosMessages.swift
//  lidar2ros
//
//  Created by Christophe Bédard on 2021-01-09.
//  Copyright © 2021 Apple. All rights reserved.
//

import Foundation

struct builtin_interfaces__Time : Encodable {
    var sec: Int32
    var nanosec: UInt32
}

struct std_msgs__Header : Encodable {
    var stamp: builtin_interfaces__Time
    var frame_id: String
}

struct sensor_msgs__Image : Encodable {
    var header: std_msgs__Header
    var height: UInt32
    var width: UInt32
    var encoding: String
    var is_bigendian: UInt8
    var step: UInt32
    var data: [UInt8]
}

struct std_msgs__String : Encodable {
    var data: String
}
