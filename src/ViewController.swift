/*
See LICENSE.3RD-PARTY file for this file’s licensing information.

Abstract:
Main view controller for the AR experience.
*/

import UIKit
import Metal
import MetalKit
import ARKit
import OSLog

final class ViewController: UIViewController, ARSessionDelegate {
    private let logger = Logger(subsystem: "com.christophebedard.lidar2ros", category: "ViewController")
    
    private let confidenceControl = UISegmentedControl(items: ["Low", "Medium", "High"])
    private let rgbRadiusSlider = UISlider()
    
    private let helpPageButton = UIButton()
    private let controlsButton = UIButton()
    private var isControlsViewEnabled = true
    private var mainView: UIStackView?
    
    private var pubController: PubController!
    private var session: ARSession!
    private var rosControllerViewProvider: RosControllerViewProvider!
    
    private var renderer: Renderer!
    
    public func setPubManager(pubManager: PubManager) {
        self.logger.debug("setPubManager")
        self.pubController = pubManager.pubController
        self.session = pubManager.session
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported on this device")
            return
        }
        
        self.logger.debug("viewDidLoad")
        
        session.delegate = self
        
        // Set the view to use the default device
        if let view = view as? MTKView {
            view.device = device
            
            view.backgroundColor = UIColor.clear
            // we need this to enable depth test
            view.depthStencilPixelFormat = .depth32Float
            view.contentScaleFactor = 1
            view.delegate = self
            
            // Configure the renderer to draw to the view
            renderer = Renderer(session: session, metalDevice: device, renderDestination: view)
            renderer.drawRectResized(size: view.bounds.size)
        }
        
        // Help page/message button
        let helpIcon = UIImage(systemName: "questionmark.circle.fill", withConfiguration: UIImage.SymbolConfiguration(scale: .large))?.withTintColor(UIColor(white: 1.0, alpha: 0.5), renderingMode: .alwaysOriginal)
        self.helpPageButton.setImage(helpIcon, for: .normal)
        self.helpPageButton.addTarget(self, action: #selector(showHelp), for: .touchUpInside)
        self.helpPageButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Controls display button
        let controlsIcon = UIImage(systemName: "gearshape.fill", withConfiguration: UIImage.SymbolConfiguration(scale: .large))?.withTintColor(UIColor(white: 1.0, alpha: 0.5), renderingMode: .alwaysOriginal)
        self.controlsButton.setImage(controlsIcon, for: .normal)
        self.controlsButton.addTarget(self, action: #selector(controlsButtonPressed), for: .touchUpInside)
        self.controlsButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Horizontal separator
        let separator = UIView()
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        separator.backgroundColor = UIColor.init(white: 1.0, alpha: 0.5)
        
        // Confidence control
        confidenceControl.backgroundColor = .white
        confidenceControl.selectedSegmentIndex = renderer.confidenceThreshold
        confidenceControl.addTarget(self, action: #selector(textFieldValueChanged), for: .valueChanged)
        
        // RGB Radius control
        rgbRadiusSlider.minimumValue = 0
        rgbRadiusSlider.maximumValue = 1.5
        rgbRadiusSlider.isContinuous = true
        rgbRadiusSlider.value = renderer.rgbRadius
        rgbRadiusSlider.addTarget(self, action: #selector(textFieldValueChanged), for: .valueChanged)
        
        self.rosControllerViewProvider = RosControllerViewProvider(pubController: self.pubController!, session: self.session)
        
        // Then stacked vertically
        self.mainView = UIStackView(arrangedSubviews: [rosControllerViewProvider.view!, separator, confidenceControl, rgbRadiusSlider])
        self.mainView!.isHidden = !self.isControlsViewEnabled
        self.mainView!.translatesAutoresizingMaskIntoConstraints = false
        self.mainView!.axis = .vertical
        self.mainView!.spacing = 20
        
        view.addSubview(helpPageButton)
        view.addSubview(controlsButton)
        view.addSubview(mainView!)
        NSLayoutConstraint.activate([
            self.mainView!.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            self.mainView!.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            self.helpPageButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -30),
            self.helpPageButton.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -30),
            self.controlsButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -30),
            self.controlsButton.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 30),
        ])
    }
    
    @objc
    private func showHelp() {
        let helpAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        helpAlertController.title = "How to use"
        helpAlertController.message = """
This application sends messages to a rosbridge using the rosbridge v2.0 protocol.

Launch a rosbridge on a computer accessible from this iPad through the network.
Then set the remote bridge IP and port to point to it.
"""
        let openLinkAction = UIAlertAction(title: "open rosbrige instructions", style: .default) { (action: UIAlertAction) in
            let url = URLComponents(string: "https://github.com/RobotWebTools/ros2-web-bridge#install")!
            UIApplication.shared.open(url.url!)
        }
        let closeAction = UIAlertAction(title: "close", style: .cancel)
        helpAlertController.addAction(openLinkAction)
        helpAlertController.addAction(closeAction)
        self.present(helpAlertController, animated: true)
    }
    
    @objc
    private func controlsButtonPressed() {
        // Just invert state
        self.isControlsViewEnabled = !self.isControlsViewEnabled
        self.mainView!.isHidden = !self.isControlsViewEnabled
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // self.pubController?.disable()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a world-tracking configuration, and
        // enable the scene depth frame-semantic.
        let configuration = ARWorldTrackingConfiguration()
        configuration.frameSemantics = .sceneDepth

        // Run the view's session
        session.run(configuration)
        
        // The screen shouldn't dim during AR experiences.
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    @objc
    private func textFieldValueChanged(view: UIView) {
        switch view {
            
        case confidenceControl:
            renderer.confidenceThreshold = confidenceControl.selectedSegmentIndex
            
        case rgbRadiusSlider:
            renderer.rgbRadius = rgbRadiusSlider.value
            
        default:
            break
        }
    }
    
    // Auto-hide the home indicator to maximize immersion in AR experiences.
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    // Hide the status bar to maximize immersion in AR experiences.
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user.
        guard error is ARError else { return }
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        DispatchQueue.main.async {
            // Present an alert informing about the error that has occurred.
            let alertController = UIAlertController(title: "The AR session failed.", message: errorMessage, preferredStyle: .alert)
            let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
                alertController.dismiss(animated: true, completion: nil)
                if let configuration = self.session.configuration {
                    self.session.run(configuration, options: .resetSceneReconstruction)
                }
            }
            alertController.addAction(restartAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
}

// MARK: - MTKViewDelegate

extension ViewController: MTKViewDelegate {
    // Called whenever view changes orientation or layout is changed
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        renderer.drawRectResized(size: size)
    }
    
    // Called whenever the view needs to render
    func draw(in view: MTKView) {
        renderer.draw()
    }
}

// MARK: - RenderDestinationProvider

protocol RenderDestinationProvider {
    var currentRenderPassDescriptor: MTLRenderPassDescriptor? { get }
    var currentDrawable: CAMetalDrawable? { get }
    var colorPixelFormat: MTLPixelFormat { get set }
    var depthStencilPixelFormat: MTLPixelFormat { get set }
    var sampleCount: Int { get set }
}

extension MTKView: RenderDestinationProvider {
    
}
