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
import ARKit

/// Publishing controller for all data.
final class PubController {
    /// Type of controlled publication.
    public enum PubType {
        case transforms
        case depth
        case pointCloud
        case camera
    }
    public static let defaultRate = 2.0
    
    private let logger = Logger(subsystem: "com.christophebedard.lidar2ros", category: "PubController")
    
    private var url: String?
    private var isEnabled: Bool = false
    private let interface = RosInterface()
    
    private var controlledPubs: [PubType: [ControlledPublisher]]
    private var pubTf: ControlledStaticPublisher
    // private var pubTfStatic: ControlledStaticPublisher
    private var pubDepth: ControlledPublisher
    private var pubPointCloud: ControlledPublisher
    private var pubCamera: ControlledPublisher
    
    init() {
        /// Create controlled pub objects for all publishers
        self.pubTf = ControlledStaticPublisher(interface: self.interface, type: tf2_msgs__TFMessage.self, topicName: "/tf")
        // FIXME: using /tf only for now because /tf_static does not seem to work
        // self.pubTfStatic = ControlledStaticPublisher(interface: self.interface, type: tf2_msgs__TFMessage.self, topicName: "/tf")
        self.pubDepth = ControlledPublisher(interface: self.interface, type: sensor_msgs__Image.self)
        self.pubPointCloud = ControlledPublisher(interface: self.interface, type: sensor_msgs__PointCloud2.self)
        self.pubCamera = ControlledPublisher(interface: self.interface, type: sensor_msgs__Image.self)
        
        self.controlledPubs = [
            //.transforms: [self.pubTf, self.pubTfStatic],
            .transforms: [self.pubTf],
            .depth: [self.pubDepth],
            .pointCloud: [self.pubPointCloud],
            .camera: [self.pubCamera],
        ]
    }
    
    /// Enable specific publisher.
    ///
    /// - parameter pubType: the type of the publisher to enable
    /// - parameter topicName: the topicName to use for the publisher
    public func enablePub(pubType: PubType, topicName: String?) -> Bool {
        guard let pubs = self.controlledPubs[pubType] else {
            return false
        }
        var result = true
        for pub in pubs {
            result = result && pub.enable(topicName: topicName)
        }
        return result
    }
    
    /// Disable specific publisher.
    ///
    /// - parameter pubType: the type of the publisher to disable
    public func disablePub(pubType: PubType) {
        guard let pubs = self.controlledPubs[pubType] else {
            return
        }
        for pub in pubs {
            pub.disable()
        }
    }
    
    /// Update topic name for a publisher.
    ///
    /// - parameter topicName: the new topic name
    /// - returns: true if successful, false otherwise
    public func updatePubTopic(pubType: PubType, topicName: String?) -> Bool {
        guard let pubs = self.controlledPubs[pubType] else {
            return false
        }
        var result = true
        for pub in pubs {
            result = result && pub.updateTopic(topicName: topicName)
        }
        return result
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
    public func update(time: Double, depthMap: CVPixelBuffer, points: [vector_float3], cameraTf: simd_float4x4, cameraImage: CVPixelBuffer) {
        self.logger.debug("update")
        
        if self.isEnabled {
            // TODO disable if publish fails?
            // TODO revert when /tf_static works
            // self.pubTf.publish(RosMessagesUtils.tfToTfMsg(time: time, tf: cameraTf))
            // self.pubTfStatic.publish(RosMessagesUtils.getTfStaticMsg(time: time))
            var tfMsg = RosMessagesUtils.tfToTfMsg(time: time, tf: cameraTf)
            let tfStaticMsg = RosMessagesUtils.getTfStaticMsg(time: time)
            tfMsg.transforms.append(contentsOf: tfStaticMsg.transforms)
            self.pubTf.publish(tfMsg)
            self.pubDepth.publish(RosMessagesUtils.depthMapToImage(time: time, depthMap: depthMap))
            self.pubPointCloud.publish(RosMessagesUtils.pointsToPointCloud2(time: time, points: points))
            // TODO implement
            // self.pubCamera.publish(RosMessagesUtils.pixelBufferToImage(time: time, pixelBuffer: cameraImage))
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
