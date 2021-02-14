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
import ARKit
import OSLog

/// Class that manages and instigates the publishing.
///
/// The actual work is done in a background thread.
final class PubManager {
    private let logger = Logger(subsystem: "com.christophebedard.lidar2ros", category: "PubManager")
    
    public let session = ARSession()
    public let pubController: PubController
    private let interface = RosInterface()
    
    private var pubTf: ControlledStaticPublisher
    // private var pubTfStatic: ControlledStaticPublisher
    private var pubDepth: ControlledPublisher
    private var pubPointCloud: ControlledPublisher
    private var pubCamera: ControlledPublisher
    
    public init() {
        /// Create controlled pub objects for all publishers
        self.pubTf = ControlledStaticPublisher(interface: self.interface, type: tf2_msgs__TFMessage.self, topicName: "/tf")
        // FIXME: using /tf only for now because /tf_static does not seem to work
        // self.pubTfStatic = ControlledStaticPublisher(interface: self.interface, type: tf2_msgs__TFMessage.self, topicName: "/tf")
        self.pubDepth = ControlledPublisher(interface: self.interface, type: sensor_msgs__Image.self)
        self.pubPointCloud = ControlledPublisher(interface: self.interface, type: sensor_msgs__PointCloud2.self)
        self.pubCamera = ControlledPublisher(interface: self.interface, type: sensor_msgs__Image.self)
        
        let controlledPubs: [PubController.PubType: [ControlledPublisher]] = [
            //.transforms: [self.pubTf, self.pubTfStatic],
            .transforms: [self.pubTf],
            .depth: [self.pubDepth],
            .pointCloud: [self.pubPointCloud],
            .camera: [self.pubCamera],
        ]
        self.pubController = PubController(pubs: controlledPubs, interface: self.interface)
    }
    
    private func startPubThread(id: String, pubType: PubController.PubType, publishFunc: @escaping () -> Void) {
        self.logger.debug("start pub thread: \(id)")
        DispatchQueue.global(qos: .background).async {
            Thread.current.name = "PubManager: \(id)"
            var last = Date().timeIntervalSince1970
            while true {
                if !self.pubController.isEnabled {
                    continue
                }
                let interval = 1.0 / self.pubController.getPubRate(pubType)!
                // TODO find a better way: seems like busy sleep is the
                // most reliable way to do this but it wastes CPU time
                var now = Date().timeIntervalSince1970
                while now - last < interval {
                    now = Date().timeIntervalSince1970
                }
                last = Date().timeIntervalSince1970
                publishFunc()
            }
        }
    }
    
    /// Start managed publishing.
    public func start() {
        self.logger.debug("start")
        self.startPubThread(id: "tf", pubType: .transforms, publishFunc: self.publishTf)
        self.startPubThread(id: "depth", pubType: .depth, publishFunc: self.publishDepth)
        self.startPubThread(id: "pointcloud", pubType: .pointCloud, publishFunc: self.publishPointCloud)
        // TODO fix/implement
        // self.startPubThread(id: "camera", pubType: .camera, publishFunc: self.publishCamera)
    }
    
    private func publishTf() {
        guard let currentFrame = self.session.currentFrame else {
            return
        }
        let timestamp = currentFrame.timestamp
        let cameraTf = currentFrame.camera.transform
        // TODO revert when /tf_static works
        // self.pubTf.publish(RosMessagesUtils.tfToTfMsg(time: time, tf: cameraTf))
        // self.pubTfStatic.publish(RosMessagesUtils.getTfStaticMsg(time: time))
        var tfMsg = RosMessagesUtils.tfToTfMsg(time: timestamp, tf: cameraTf)
        let tfStaticMsg = RosMessagesUtils.getTfStaticMsg(time: timestamp)
        tfMsg.transforms.append(contentsOf: tfStaticMsg.transforms)
        self.pubTf.publish(tfMsg)
    }
    
    private func publishDepth() {
        guard let currentFrame = self.session.currentFrame,
              let depthMap = currentFrame.sceneDepth?.depthMap else {
                return
        }
        let timestamp = currentFrame.timestamp
        self.pubDepth.publish(RosMessagesUtils.depthMapToImage(time: timestamp, depthMap: depthMap))
    }
    
    private func publishPointCloud() {
        guard let currentFrame = self.session.currentFrame,
              let pointCloud = currentFrame.rawFeaturePoints?.points else {
                return
        }
        let timestamp = currentFrame.timestamp
        self.pubPointCloud.publish(RosMessagesUtils.pointsToPointCloud2(time: timestamp, points: pointCloud))
    }
    
//    private func publishCamera() {
//        guard let currentFrame = self.session.currentFrame else {
//            return
//        }
//        let timestamp = currentFrame.timestamp
//        let cameraImage = currentFrame.capturedImage
//        self.pubCamera.publish(RosMessagesUtils.pixelBufferToImage(time: time, pixelBuffer: cameraImage))
//    }
}
