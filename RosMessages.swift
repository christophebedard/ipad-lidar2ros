//
//  RosMessages.swift
//  lidar2ros
//
//  Created by Christophe Bédard on 2021-01-09.
//  Copyright © 2021 Apple. All rights reserved.
//

import Foundation

struct std_msgs__String : Codable {
    var data: String
}

struct MsgRaw<T> : Codable where T : Codable {
    var op: String
    var id: String
    var topic: String
    var type: String?
    var msg: T?
}
