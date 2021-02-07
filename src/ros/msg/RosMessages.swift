// Copyright 2021 Christophe Bedard
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation

/// Generic ROS message, which is just an encodable object.
typealias RosMsg = Encodable

/// builtin_interfaces/Time
struct builtin_interfaces__Time: RosMsg {
    var sec: Int32
    var nanosec: UInt32
}

/// std_msgs/Header
struct std_msgs__Header: RosMsg {
    var stamp: builtin_interfaces__Time
    var frame_id: String
}

/// sensor_msgs/Image
struct sensor_msgs__Image: RosMsg {
    var header: std_msgs__Header
    var height: UInt32
    var width: UInt32
    var encoding: String
    var is_bigendian: UInt8
    var step: UInt32
    var data: [UInt8]
    
    static let RGB8: String = "rgb8"
    static let RGBA8: String = "rgba8"
    static let RGB16: String = "rgb16"
    static let RGBA16: String = "rgba16"
    static let BGR8: String = "bgr8"
    static let BGRA8: String = "bgra8"
    static let BGR16: String = "bgr16"
    static let BGRA16: String = "bgra16"
    static let MONO8: String = "mono8"
    static let MONO16: String = "mono16"
}

/// std_msgs/String
struct std_msgs__String: RosMsg {
    var data: String
}

/// sensor_msgs/PointField
struct sensor_msgs__PointField: RosMsg {
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
struct sensor_msgs__PointCloud2: RosMsg {
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

/// geometry_msgs/Vector3
struct geometry_msgs__Vector3: RosMsg {
    var x: Float64
    var y: Float64
    var z: Float64
}

/// geometry_msgs/Quaternion
struct geometry_msgs__Quaternion: RosMsg {
    var x: Float64
    var y: Float64
    var z: Float64
    var w: Float64
}

/// geometry_msgs/Transform
struct geometry_msgs__Transform: RosMsg {
    var translation: geometry_msgs__Vector3
    var rotation: geometry_msgs__Quaternion
}

/// geometry_msgs/TransformStamped
struct geometry_msgs__TransformStamped: RosMsg {
    var header: std_msgs__Header
    var child_frame_id: String
    var transform: geometry_msgs__Transform
}

/// tf2_msgs/TFMessage
struct tf2_msgs__TFMessage: RosMsg {
    var transforms: [geometry_msgs__TransformStamped]
}
