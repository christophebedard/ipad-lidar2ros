/*
See LICENSE.3RD-PARTY file for this file’s licensing information.

Abstract:
Contains the application's delegate.
*/

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
