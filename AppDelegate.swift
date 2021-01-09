/*
See LICENSE folder for this sample’s licensing information.

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
    
    private let pubController = PubController()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.logger.info("application")
        if !ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            // Ensure that the device supports scene depth and present
            //  an error-message view controller, if not.
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            window?.rootViewController = storyboard.instantiateViewController(withIdentifier: "unsupportedDeviceMessage")
        } else {
            (window?.rootViewController as! ViewWithPubController).setPubController(pubController: self.pubController)
        }
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        self.logger.debug("app did enter background")
        self.pubController.pause()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        self.logger.debug("app will enter foreground")
        self.pubController.resume()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        self.logger.debug("app will terminate")
        self.pubController.disable()
    }
}

