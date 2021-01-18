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

/// Publishing controller for all data.
final class PubController {
    /// Type of controlled publication.
    public enum PubType {
        case depth
        case pointCloud
        case transforms
    }
    
    private let logger = Logger(subsystem: "com.christophebedard.lidar2ros", category: "PubController")
    
    private var url: String?
    private var isEnabled: Bool = false
    private let interface = RosInterface()
    private var controlledPubs: [PubType: ControlledPublisher] = [:]
    
    init() {
        /// Create controlled pub objects for all publishers
        self.controlledPubs[.depth] = ControlledPublisher(interface: self.interface, type: sensor_msgs__Image.self)
        self.controlledPubs[.pointCloud] = ControlledPublisher(interface: self.interface, type: sensor_msgs__PointCloud2.self)
        self.controlledPubs[.transforms] = ControlledStaticPublisher(interface: self.interface, type: tf2_msgs__TFMessage.self, topicName: "/tf")
        
        _ = self.controlledPubs[.transforms]?.enable()
    }
    
    /// Enable specific publisher.
    ///
    /// - parameter pubType: the type of the publisher to enable
    /// - parameter topicName: the topicName to use for the publisher
    public func enablePub(pubType: PubType, topicName: String?) -> Bool {
        return self.controlledPubs[pubType]?.enable(topicName: topicName) ?? false
    }
    
    /// Disable specific publisher.
    ///
    /// - parameter pubType: the type of the publisher to disable
    public func disablePub(pubType: PubType) {
        self.controlledPubs[pubType]?.disable()
    }
    
    /// Update topic name for a publisher.
    ///
    /// - parameter topicName: the new topic name
    /// - returns: true if successful, false otherwise
    public func updatePubTopic(pubType: PubType, topicName: String?) -> Bool {
        return self.controlledPubs[pubType]?.updateTopic(topicName: topicName) ?? false
    }
    
    /// Enable and connect.
    ///
    /// - parameter url: the new URL to use, or `nil` to keep the current one
    /// - parameter topicNames: the dictionnary of topic names of topics to use (`nil` to keep the current one)
    /// - returns: true if enabling was was successful, false otherwise
    public func enable(url: String?) -> Bool {
        self.logger.debug("enable")
        self.isEnabled = true
        return self.updateConnection(url)
    }
    
    /// Resume state, and, if the controller is enabled, update the connection.
    ///
    /// - returns: true if enabled and resumed successfully, false otherwise
    @discardableResult
    public func resume() -> Bool? {
        self.logger.debug("resume")
        if self.isEnabled {
            return self.updateConnection(nil)
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
    public func update(time: Double, depthMap: CVPixelBuffer, points: [vector_float3], cameraTf: simd_float4x4) {
        self.logger.debug("update")
        
        if self.isEnabled {
            // TODO disable if publish fails?
            self.controlledPubs[.depth]?.publish(RosMessagesUtils.depthMapToImage(time: time, depthMap: depthMap))
            self.controlledPubs[.pointCloud]?.publish(RosMessagesUtils.pointsToPointCloud2(time: time, points: points))
            self.controlledPubs[.transforms]?.publish(RosMessagesUtils.tfToTfMsg(time: time, tf: cameraTf))
        }
    }
    
    /// Update connection URL and try to reconnect.
    ///
    /// If the connection fails, the controller is disabled.
    ///
    /// - parameter url: the new URL to use, or `nil` to keep the current URL and just re-connect
    /// - returns: true if the connection update was successful, false otherwise
    private func updateConnection(_ url: String?) -> Bool {
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
}
