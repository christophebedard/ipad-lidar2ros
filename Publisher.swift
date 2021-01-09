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
    /// - parameter type: the topic type
    init(interface: RosInterface, topicName: String, type: String) {
        self.interface = interface
        self.topicName = topicName
        self.type = type
        self.isAdvertised = false
        self.counter = 0
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
        
        let d: [String: String] = [
            "op": "advertise",
            "id": "advertise:\(self.topicName)",
            "topic": self.topicName,
            "type": self.type,
        ]
        if !self.interface.send(data: d) {
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
        
        let d: [String: String] = [
            "op": "unadvertise",
            "id": "unadvertise:\(self.topicName)",
            "topic": self.topicName,
        ]
        if !self.interface.send(data: d) {
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
    public func publish(msg: String) -> Bool {
        if !self.isAdvertised && !self.advertise() {
            return false
        }
        
        self.logger.debug("publishing \(self.topicName)")
        self.counter += 1
        
        let d: [String: String] = [
            "op": "publish",
            "id": "publish:\(self.topicName):\(self.counter)",
            "topic": self.topicName,
            "msg": msg,
        ]
        return self.interface.send(data: d)
    }
}