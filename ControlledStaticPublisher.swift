//
//  ControlledStaticPublisher.swift
//  lidar2ros
//
//  Created by Christophe Bédard on 2021-01-17.
//  Copyright © 2021 Christophe Bedard. All rights reserved.
//

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
