//
//  PubController.swift
//  lidar2ros
//
//  Created by Christophe Bédard on 2021-01-08.
//  Copyright © 2021 Christophe Bedard. All rights reserved.
//

import Foundation
import OSLog
import ARKit

/// Simple protocol for a view controller with a PubController.
protocol ViewWithPubController {
    func setPubController(pubController: PubController)
}

/// Controller for publishing depth data.
/// TODO rename to "DepthPubController"
final class PubController {
    private let logger = Logger(subsystem: "com.christophebedard.lidar2ros", category: "PubController")
    private let TOPIC_TYPE = "sensor_msgs/msg/Image"
    
    private var url: String?
    
    private var isEnabled: Bool = false
    private let interface = RosInterface()
    private var pub: Publisher?
    
    /// Enable and connect.
    ///
    /// - parameter url: the new URL to use, or `nil` to keep the current one
    /// - parameter topicName: the new topic name to use, or `nil` to keep the current one
    /// - returns: true if enabling was was successful, false otherwise
    public func enable(url: String?, topicName: String?) -> Bool {
        self.logger.debug("enable")
        self.isEnabled = true
        if !self.updateTopic(topicName: topicName) {
            return false
        }
        return self.updateConnection(url: url)
    }
    
    /// Resume state, and, if the controller is enabled, update the connection.
    ///
    /// - returns: true if enabled and resumed successfully, false otherwise
    @discardableResult
    public func resume() -> Bool? {
        self.logger.debug("resume")
        if self.isEnabled {
            return self.updateConnection(url: nil)
        }
        return false
    }
    
    /// Pause and disconnect interface.
    public func pause() {
        self.logger.debug("pause")
        self.interface.disconnect()
    }
    
    /// Disable and disconnect interface.
    public func disable() {
        self.logger.debug("disable")
        self.isEnabled = false
        self.interface.disconnect()
    }
    
    /// Update and publish if enabled.
    public func update(time: Double, depth: CVPixelBuffer, points: [vector_float3]) {
        self.logger.debug("update")
        
        if self.isEnabled {
            // TODO disable if publish fails?
            self.pub?.publish(RosUtils.depthMapToImage(time: time, depth: depth))
        }
    }
    
    /// Update connection URL and try to reconnect.
    ///
    /// If the connection fails, the controller is disabled.
    ///
    /// - parameter url: the new URL to use, or `nil` to keep the current URL
    /// - returns: true if the connection update was successful, false otherwise
    private func updateConnection(url: String?) -> Bool {
        self.logger.debug("updateConnection")
        if nil != url {
            self.url = url
        }
        if nil != self.url && self.interface.connect(urlStr: self.url!) {
            return true
        } else {
            self.disable()
            return false
        }
    }
    
    /// Update the topic.
    ///
    /// Replaces the current publisher if needed.
    ///
    /// - parameter topicName: the topic name
    /// - returns: true if successful, false otherwise
    private func updateTopic(topicName: String?) -> Bool {
        let currentTopic = self.pub?.getTopicName()
        if nil != topicName && currentTopic != topicName {
            // Replace publisher
            self.logger.debug("replacing publisher: changing topic from \(currentTopic ?? "??") to \(topicName!)")
            if nil != self.pub {
                self.interface.destroyPublisher(pub: self.pub!)
            }
            self.pub = self.interface.createPublisher(topicName: topicName!, type: self.TOPIC_TYPE)
            if nil == self.pub {
                return false
            }
        }
        return true
    }
}
