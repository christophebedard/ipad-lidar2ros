//
//  ControlledPublisher.swift
//  lidar2ros
//
//  Created by Christophe Bédard on 2021-01-10.
//  Copyright © 2021 Christophe Bedard. All rights reserved.
//

import Foundation
import OSLog

/// Managed publisher that can be enabled/disabled and for which we can change the topic.
class ControlledPublisher {
    private var logger = Logger(subsystem: "com.christophebedard.lidar2ros", category: "ControlledPublisher")
    
    private var isEnabled: Bool = false
    private var interface: RosInterface
    private var type: Any
    private var pub: Publisher?
    
    init(interface: RosInterface, type: Any) {
        self.interface = interface
        self.type = type
    }
    
    public func enable(topicName: String? = nil) -> Bool {
        self.logger.debug("enable")
        self.isEnabled = true
        return self.updateTopic(topicName: topicName)
    }
    
    public func disable() {
        self.logger.debug("disable")
        self.isEnabled = false
    }
    
    @discardableResult
    public func publish<T>(_ msg: T) -> Bool where T : RosMsg {
        if !self.isEnabled {
            return true
        }
        return self.pub?.publish(msg) ?? true
    }
    
    public func updateTopic(topicName: String? = nil) -> Bool {
        if nil == topicName {
            return false
        }
        let currentTopic = self.pub?.topicName
        if currentTopic != topicName {
            // Replace publisher
            self.logger.debug("replacing publisher: changing topic from \(currentTopic ?? "(none)") to \(topicName!)")
            if nil != self.pub {
                self.interface.destroyPublisher(pub: self.pub!)
            }
            self.pub = self.interface.createPublisher(topicName: topicName!, type: self.type)
            if nil == self.pub {
                return false
            }
        }
        return true
    }
}
