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
//
// This file includes 3rd party work.
// See LICENSE.3RD-PARTY file for this file’s 3rd-party licensing information.

import UIKit
import ARKit
import OSLog

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    private let logger = Logger(subsystem: "com.christophebedard", category: "AppDelegate")
    
    var window: UIWindow?
    
    private let pubManager = PubManager()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.logger.info("application")
        if !ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            // Ensure that the device supports scene depth and present
            //  an error-message view controller, if not.
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            window?.rootViewController = storyboard.instantiateViewController(withIdentifier: "unsupportedDeviceMessage")
        } else {
            (window?.rootViewController as! ViewController).setPubManager(pubManager: self.pubManager)
        }
        self.pubManager.start()
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        self.logger.debug("app did enter background")
        self.pubManager.pubController.pause()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        self.logger.debug("app will enter foreground")
        self.pubManager.pubController.resume()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        self.logger.debug("app will terminate")
        self.pubManager.pubController.disable()
    }
}
