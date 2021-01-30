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
import OSLog

/// Publisher.
///
/// Uses the RosInterface to advertise and publish.
final class Publisher {
    private var logger = Logger(subsystem: "com.christophebedard.lidar2ros", category: "Publisher")
    
    private var interface: RosInterface
    private var isAdvertised: Bool
    private var counter: Int
    
    /// The name of the topic that the publisher publishes on.
    public private(set) var topicName: String
    /// The string representation of the publisher's message type.
    public private(set) var type: String
    
    /// Create a publisher.
    ///
    /// - parameter interface: the ROS interface to use
    /// - parameter topicName: the topic name
    /// - parameter type: the type, as the message struct type
    init(interface: RosInterface, topicName: String, type: Any) {
        self.interface = interface
        self.topicName = topicName
        self.isAdvertised = false
        self.counter = 0
        self.type = ""
        self.type = Publisher.getMsgType(type)
    }
    
    /// Get message type string representation from message struct type.
    ///
    /// - parameter typeStruct: the type, as the message struct type
    /// - returns: the ROS-compatible string representation of the type
    private static func getMsgType(_ typeStruct: Any) -> String {
        // Using '/msg/' between package name and message name with ROS 2 in mind
        // TODO if this is what ends up making rosbridge work with only ROS 2,
        // maybe add a switch to switch between ROS 1 and 2
        return String(describing: typeStruct).replacingOccurrences(of: "__", with: "/msg/")
    }
    
    /// Advertise topic.
    ///
    /// - returns: true if successful, false otherwise
    @discardableResult
    public func advertise() -> Bool {
        if self.isAdvertised {
            return true
        }
        
        self.logger.debug("advertising \(self.topicName)")
        
        let d = RosbridgeMsg(op: "advertise", id: "advertise:\(self.topicName)", topic: self.topicName, type: self.type, msg: "")
        if !self.interface.send(d) {
            return false
        }
        self.isAdvertised = true
        self.counter = 0
        return true
    }
    
    /// Unadvertise topic.
    ///
    /// - returns: true if successful, false otherwise
    @discardableResult
    public func unadvertise() -> Bool{
        if !self.isAdvertised {
            return true
        }
        
        self.logger.debug("unadvertising \(self.topicName)")
        
        let d = RosbridgeMsg(op: "unadvertise", id: "unadvertise:\(self.topicName)", topic: self.topicName, type: nil, msg: "")
        if !self.interface.send(d) {
            return false
        }
        self.isAdvertised = false
        return true
    }
    
    /// Publish message.
    ///
    /// - parameter msg: the message to publish
    /// - returns: true if successful, false otherwise
    @discardableResult
    public func publish<T>(_ msg: T) -> Bool where T : RosMsg {
        if !self.isAdvertised && !self.advertise() {
            return false
        }
        
        self.logger.debug("publishing \(self.topicName)")
        self.counter += 1
        
        let d = RosbridgeMsg(op: "publish", id: "publish:\(self.topicName):\(self.counter)", topic: self.topicName, type: nil, msg: msg)
        return self.interface.send(d)
    }
}
