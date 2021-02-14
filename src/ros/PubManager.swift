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
    public let pubController = PubController()
    
    /// Start managed publishing.
    public func start() {
        self.logger.debug("start")
        DispatchQueue.global(qos: .background).async {
            Thread.current.name = "PubManager"
            // TODO manage publishing rate
            while true {
                self.updatePub()
            }
        }
    }
    
    private func updatePub() {
        guard let currentFrame = self.session.currentFrame else {
            return
        }
        let timestamp = currentFrame.timestamp
        let cameraTf = currentFrame.camera.transform
        let cameraImage = currentFrame.capturedImage
        guard let depthMap = currentFrame.sceneDepth?.depthMap,
              let pointCloud = currentFrame.rawFeaturePoints?.points else {
                return
        }
        self.pubController.update(time: timestamp, depthMap: depthMap, points: pointCloud, cameraTf: cameraTf, cameraImage: cameraImage)
    }
}
