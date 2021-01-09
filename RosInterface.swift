//
//  RosInterface.swift
//  lidar2ros
//
//  Created by Christophe Bédard on 2021-01-06.
//  Copyright © 2021 Christophe Bedard. All rights reserved.
//

import Foundation
import OSLog

struct MsgRaw : Codable {
    var op: String
    var id: String
    var topic: String
    var type: String?
    var msg: String?
}

/// Interface for ROS.
///
/// Handles websocket connection and sending data.
final class RosInterface {
    private let URL_REGEX = "^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}:\\d{2,4}$"
    
    private var logger: Logger
    private var url: String?
    private var socket: URLSessionWebSocketTask?
    private var isConnected: Bool
    
    private var publishers: [String: Publisher] = [:]
    
    private let jsonEncoder: JSONEncoder = JSONEncoder()
    
    init() {
        self.isConnected = false
        
        self.logger = Logger(subsystem: "com.christophebedard.lidar2ros", category: "RosInterface")
    }
    
    /// Connect.
    ///
    /// Validates the URL and will return false if it is not valid.
    ///
    /// - parameter urlStr: the URL, without the leading websocket protocol schema
    /// - returns: true if successful, false otherwise
    @discardableResult
    public func connect(urlStr: String) -> Bool {
        if self.isConnected {
            self.logger.error("already connected")
            self.disconnect()
        }
        
        // Validate URL
        if !RosInterface.matchesRegex(str: urlStr, regex: self.URL_REGEX) {
            self.logger.error("given URL does not match regex: \(urlStr)")
            return false
        }
        
        self.logger.debug("connecting to \(urlStr)")
        
        // Create socket and connect
        let urlWithProtocol = "ws://\(urlStr)"
        let fullUrl = URL(string: urlWithProtocol)!
        self.socket = URLSession.shared.webSocketTask(with: fullUrl)
        self.socket?.resume()
        
        self.isConnected = true
        return true
    }
    
    /// Disconnect.
    ///
    /// Unadvertises publishers and closes the socket.
    public func disconnect() {
        // Unadvertise all publishers
        for (_, pub) in self.publishers {
            pub.unadvertise()
        }
        
        // Close socket
        self.socket?.cancel(with: URLSessionWebSocketTask.CloseCode.normalClosure, reason: nil)
        self.isConnected = false
    }
    
    /// Create a publisher.
    ///
    /// Advertises it if the interface is connected.
    /// The topic name cannot already be taken.
    ///
    /// - parameter topicName: the topic name
    /// - parameter type: the topic type
    /// - returns: the publisher if successful, `nil` otherwise
    public func createPublisher(topicName: String, type: String) -> Publisher? {
        if nil != self.publishers[topicName] {
            self.logger.error("publisher already exists for topic: \(topicName)")
            return nil
        }
        
        // TODO validate topic name
        
        let pub = Publisher(interface: self, topicName: topicName, type: type)
        
        // Try advertising it if we're connected, otherwise it will just be done later
        if self.isConnected {
            pub.advertise()
        }
        
        self.publishers[topicName] = pub
        return pub
    }
    
    /// Destroy a publisher.
    ///
    /// Unadvertise and remove from the interface.
    ///
    /// - parameter pub: the publisher to destroy
    public func destroyPublisher(pub: Publisher) {
        if nil == self.publishers[pub.getTopicName()] {
            return
        }
        
        pub.unadvertise()
        self.publishers.removeValue(forKey: pub.getTopicName())
    }
    
    /// Send data.
    ///
    /// - parameter data: the raw data to send
    /// - returns: true if successful, false otherwise
    public func send(data: String) -> Bool {
        if !self.isConnected {
            self.logger.info("trying to send without being connected")
            return false
        }
        
        self.logger.debug("sending data")
        
        self.logger.debug("sending: \(data)")
        let messageData = URLSessionWebSocketTask.Message.string(data)
        self.socket?.send(messageData) { error in
            if let error = error {
                self.logger.error("error sending over socket")
                print(error)
            }
        }
        return true
    }
    
    public func toJson<T>(data: T) -> String? where T : Encodable {
        do {
            let json = try self.jsonEncoder.encode(data)
            return String(data: json, encoding: .utf8)
        } catch {
            self.logger.error("error encoding or sending over socket")
            print(error)
        }
        return nil
    }
    
    /// Check if a string matches a regex.
    ///
    /// - returns: true if it matches, false otherwise
    private static func matchesRegex(str: String, regex: String) -> Bool {
        let range = NSRange(location: 0, length: str.utf16.count)
        let regex = try! NSRegularExpression(pattern: regex)
        return regex.firstMatch(in: str, options: [], range: range) != nil
    }
}
