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

/// Raw message for interacting with rosbridge.
struct RosbridgeMsg<T> : Encodable where T : Encodable {
    var op: String
    var id: String
    var topic: String
    var type: String?
    var msg: T?
}

/// Interface for ROS & rosbridge.
///
/// Handles websocket connection and sending data.
final class RosInterface {
    private static let URL_REGEX = "^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}:\\d{2,4}$"
    
    private var logger = Logger(subsystem: "com.christophebedard.lidar2ros", category: "RosInterface")
    
    private let jsonEncoder: JSONEncoder = JSONEncoder()
    private var url: String?
    private var socket: URLSessionWebSocketTask?
    private var isConnected = false
    
    private var publishers: [String: Publisher] = [:]
    
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
        if !RosInterface.isValidUrl(urlStr) {
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
    public func createPublisher(topicName: String, type: Any) -> Publisher? {
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
        if nil == self.publishers[pub.topicName] {
            return
        }
        
        pub.unadvertise()
        self.publishers.removeValue(forKey: pub.topicName)
    }
    
    /// Send data.
    ///
    /// - parameter data: the raw data to send
    /// - returns: true if successful, false otherwise
    public func send<T>(_ encodable: T) -> Bool where T : Encodable {
        if !self.isConnected {
            self.logger.info("trying to send without being connected")
            return false
        }
        
        self.logger.debug("sending data")
        
        guard let data = self.toJson(encodable) else {
            return false
        }
        
        let messageData = URLSessionWebSocketTask.Message.data(data)
        self.socket?.send(messageData) { error in
            if let error = error {
                self.logger.error("error sending over socket")
                print(error)
            }
        }
        return true
    }
    
    /// Convert encodable object to data.
    ///
    /// - parameter encodable: the encodable object
    /// - returns: the corresponding data object, or `nil` if it failed
    private func toJson<T>(_ encodable: T) -> Data? where T : Encodable {
        do {
            let json = try self.jsonEncoder.encode(encodable)
            return json
        } catch {
            self.logger.error("error encoding or sending over socket")
            print(error)
        }
        return nil
    }
    
    /// Check if URL string is valid.
    ///
    /// - returns: true if valid, false otherwise
    private static func isValidUrl(_ url: String) -> Bool {
        return RosInterface.matchesRegex(str: url, regex: RosInterface.URL_REGEX)
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
