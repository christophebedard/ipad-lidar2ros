//
//  Publisher.swift
//  lidar2ros
//
//  Created by Christophe Bédard on 2021-01-05.
//  Copyright © Christophe Bedard. All rights reserved.
//

import Foundation
import OSLog

/// Publisher.
///
/// Uses the RosInterface to advertise and publish.
final class Publisher {
    private var logger = Logger(subsystem: "com.christophebedard.lidar2ros", category: "Publisher")
    
    private var interface: RosInterface
    private var topicName: String
    private var type: String
    private var isAdvertised: Bool
    private var counter: Int
    
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
        self.type = self.getMsgType(type)
        self.logger.debug("type string: \(self.type)")
    }
    
    /// Get message type string from message struct type.
    private func getMsgType(_ type: Any) -> String {
        return String(describing: type).replacingOccurrences(of: "__", with: "/msg/")
    }
    
    /// - returns: the topic name
    public func getTopicName() -> String {
        return self.topicName
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
