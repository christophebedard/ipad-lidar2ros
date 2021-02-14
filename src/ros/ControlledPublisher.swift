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

/// Managed publisher that can be enabled/disabled and for which we can change the topic.
class ControlledPublisher {
    private var logger = Logger(subsystem: "com.christophebedard.lidar2ros", category: "ControlledPublisher")
    
    public private(set) var isEnabled: Bool = false
    
    private var interface: RosInterface
    private var type: Any
    private var pub: Publisher?
    
    public init(interface: RosInterface, type: Any) {
        self.interface = interface
        self.type = type
    }
    
    /// Enable controlled publisher.
    ///
    /// - parameter topicName: the new topic name to use, or `nil` to keep the current one
    /// - returns: true if successful, false otherwise
    public func enable(topicName: String? = nil) -> Bool {
        self.logger.debug("enable")
        self.isEnabled = true
        return self.updateTopic(topicName: topicName)
    }
    
    /// Disable controlled publisher.
    public func disable() {
        self.logger.debug("disable")
        self.isEnabled = false
    }
    
    /// Publish message.
    ///
    /// - parameter msg: the message to publish
    /// - returns: true if successful, false otherwise
    @discardableResult
    public func publish<T>(_ msg: T) -> Bool where T: RosMsg {
        if !self.isEnabled {
            return true
        }
        return self.pub?.publish(msg) ?? true
    }
    
    /// Update topic name.
    ///
    /// - parameter topicName: the new topic name to use
    /// - returns: true if successful, false otherwise
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
