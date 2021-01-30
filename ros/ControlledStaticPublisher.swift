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

/// Managed publisher that can be enabled/idsabled and for which we can't change the topic.
final class ControlledStaticPublisher : ControlledPublisher {
    private var logger = Logger(subsystem: "com.christophebedard.lidar2ros", category: "ControlledStaticPublisher")
    
    private let topicName: String
    
    init(interface: RosInterface, type: Any, topicName: String) {
        self.topicName = topicName
        super.init(interface: interface, type: type)
    }
    
    public override func enable(topicName: String? = nil) -> Bool {
        return super.enable(topicName: self.topicName)
    }
    
    public override func updateTopic(topicName: String? = nil) -> Bool {
        return super.updateTopic(topicName: self.topicName)
    }
}
