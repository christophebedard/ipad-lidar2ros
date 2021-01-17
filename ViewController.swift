/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Main view controller for the AR experience.
*/

import UIKit
import Metal
import MetalKit
import ARKit
import OSLog

final class ViewController: UIViewController, ARSessionDelegate, ViewWithPubController {
    private let logger = Logger(subsystem: "com.christophebedard.lidar2ros", category: "ViewController")
    
    private let isUIEnabled = true
    private let confidenceControl = UISegmentedControl(items: ["Low", "Medium", "High"])
    private let rgbRadiusSlider = UISlider()
    
    // Help page button
    private let helpPageButton = UIButton()
    // Global/connection
    private let urlTextField = UITextField()
    private let urlTextFieldLabel = UILabel()
    private let masterSwitch = UISwitch()
    // Depth
    private let topicNameDepthTextField = UITextField()
    private let topicNameDepthTextFieldLabel = UILabel()
    private let statusSwitchDepth = UISwitch()
    // Point cloud
    private let topicNamePointCloudTextField = UITextField()
    private let topicNamePointCloudTextFieldLabel = UILabel()
    private let statusSwitchPointCloud = UISwitch()
    
    private let session = ARSession()
    private var renderer: Renderer!
    
    public var pubController: PubController?
    
    public func setPubController(pubController: PubController) {
        self.pubController = pubController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported on this device")
            return
        }
        
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
        
        // WebSocket URL field, label, and global switch
        self.createLabelTextFieldSwitchViews(uiLabel: urlTextFieldLabel, uiTextField: urlTextField, uiStatusSwitch: masterSwitch, labelText: "Remote bridge", textFieldPlaceholder: "192.168.0.xyz:abcd")
        // Depth topic name field, label, and switch
        self.createLabelTextFieldSwitchViews(uiLabel: topicNameDepthTextFieldLabel, uiTextField: topicNameDepthTextField, uiStatusSwitch: statusSwitchDepth, labelText: "Depth map", textFieldPlaceholder: "/topic_depth", useAsDefaultText: true)
        // Point cloud topic name field and label
        self.createLabelTextFieldSwitchViews(uiLabel: topicNamePointCloudTextFieldLabel, uiTextField: topicNamePointCloudTextField, uiStatusSwitch: statusSwitchPointCloud, labelText: "Point cloud", textFieldPlaceholder: "/topic_pointcloud", useAsDefaultText: true)
        
        // Stack with all the ROS config
        let labelsStackView = self.createVerticalStack(arrangedSubviews: [urlTextFieldLabel, topicNameDepthTextFieldLabel, topicNamePointCloudTextFieldLabel])
        let textFieldsStackView = self.createVerticalStack(arrangedSubviews: [urlTextField, topicNameDepthTextField, topicNamePointCloudTextField])
        let statusSwitchesView = self.createVerticalStack(arrangedSubviews: [masterSwitch, statusSwitchDepth, statusSwitchPointCloud])
        let rosStackView = UIStackView(arrangedSubviews: [labelsStackView, textFieldsStackView, statusSwitchesView])
        rosStackView.isHidden = !isUIEnabled
        rosStackView.translatesAutoresizingMaskIntoConstraints = false
        rosStackView.axis = .horizontal
        rosStackView.spacing = 10
        
        // Horizontal separator
        let separator = UIView()
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        separator.backgroundColor = UIColor.init(white: 1.0, alpha: 0.5)
        
        // Confidence control
        confidenceControl.backgroundColor = .white
        confidenceControl.selectedSegmentIndex = renderer.confidenceThreshold
        confidenceControl.addTarget(self, action: #selector(viewValueChanged), for: .valueChanged)
        
        // RGB Radius control
        rgbRadiusSlider.minimumValue = 0
        rgbRadiusSlider.maximumValue = 1.5
        rgbRadiusSlider.isContinuous = true
        rgbRadiusSlider.value = renderer.rgbRadius
        rgbRadiusSlider.addTarget(self, action: #selector(viewValueChanged), for: .valueChanged)
        
        // Then stacked vertically
        let stackView = UIStackView(arrangedSubviews: [rosStackView, separator, confidenceControl, rgbRadiusSlider])
        stackView.isHidden = !isUIEnabled
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 20
        
        view.addSubview(helpPageButton)
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50)
        ])
        NSLayoutConstraint.activate([
            self.helpPageButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -30),
            self.helpPageButton.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -30),
        ])
        
        Timer.scheduledTimer(timeInterval: 1.0/10.0, target: self, selector: #selector(updatePub), userInfo: nil, repeats: true)
    }
    
    private func createLabelTextFieldSwitchViews(uiLabel: UILabel, uiTextField: UITextField, uiStatusSwitch: UISwitch, labelText: String, textFieldPlaceholder: String, useAsDefaultText: Bool = false) {
        uiTextField.borderStyle = UITextField.BorderStyle.bezel
        uiTextField.clearButtonMode = UITextField.ViewMode.whileEditing
        uiTextField.autocorrectionType = UITextAutocorrectionType.no
        uiTextField.placeholder = textFieldPlaceholder
        if useAsDefaultText {
            uiTextField.text = textFieldPlaceholder
        }
        uiTextField.addTarget(self, action: #selector(viewValueChanged), for: .editingDidEndOnExit)
        uiLabel.attributedText = NSAttributedString(string: labelText)
        uiStatusSwitch.preferredStyle = UISwitch.Style.checkbox
        uiStatusSwitch.addTarget(self, action: #selector(switchStatusChanged), for: .valueChanged)
    }
    
    private func createVerticalStack(arrangedSubviews: [UIView]) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: arrangedSubviews)
        stackView.isHidden = !isUIEnabled
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.alignment = UIStackView.Alignment.fill
        stackView.distribution = UIStackView.Distribution.fillEqually
        return stackView
    }
    
    @objc
    func showHelp(sender: UIButton!) {
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
    private func updatePub() {
        // TODO move to more appropriate place (non UI thread)
        let currentFrame = session.currentFrame
        if nil != currentFrame {
            let timestamp = currentFrame!.timestamp
            let depthMap = currentFrame!.sceneDepth?.depthMap
            let pointCloud = currentFrame!.rawFeaturePoints?.points
            let cameraTf = currentFrame!.camera.transform
            if nil != depthMap && nil != pointCloud {
                self.pubController?.update(time: timestamp, depthMap: depthMap!, points: pointCloud!, cameraTf: cameraTf)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.pubController?.disable()
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
    private func viewValueChanged(view: UIView) {
        switch view {
            
        case confidenceControl:
            renderer.confidenceThreshold = confidenceControl.selectedSegmentIndex
            
        case rgbRadiusSlider:
            renderer.rgbRadius = rgbRadiusSlider.value
            
        case self.urlTextField:
            self.updateUrl()
            
        case self.topicNameDepthTextField:
            self.updatePubTopic(uiSwitch: self.statusSwitchDepth, pubType: .depth, topicName: self.topicNameDepthTextField.text!)
            
        case self.topicNamePointCloudTextField:
            self.updatePubTopic(uiSwitch: self.statusSwitchPointCloud, pubType: .pointCloud, topicName: self.topicNamePointCloudTextField.text!)
            
        default:
            break
        }
    }
    
    @objc
    private func switchStatusChanged(view: UIView) {
        switch view {
            
        case self.masterSwitch:
            self.updateMasterSwitch()
            
        case self.statusSwitchDepth:
            self.updateTopicState(uiSwitch: self.statusSwitchDepth, pubType: .depth, topicName: self.topicNameDepthTextField.text!)
            
        case self.statusSwitchPointCloud:
            self.updateTopicState(uiSwitch: self.statusSwitchPointCloud, pubType: .pointCloud, topicName: self.topicNamePointCloudTextField.text!)
            
        default:
            break
        }
    }
    
    private func updateUrl() {
        // Enable pub controller and/or update URL
        if self.pubController?.enable(url: self.urlTextField.text) ?? false {
            // It worked, so turn switch on
            self.masterSwitch.setOn(true, animated: true)
        } else {
            // It fails, so turn off switch and disable
            self.masterSwitch.setOn(false, animated: true)
            self.pubController?.disable()
        }
    }
    
    private func updateMasterSwitch() {
        if self.masterSwitch.isOn {
            self.updateUrl()
        } else {
            // Disable pub controller
            self.pubController?.disable()
        }
    }
    
    private func updatePubTopic(uiSwitch: UISwitch, pubType: PubController.PubType, topicName: String) {
        if self.pubController?.updatePubTopic(pubType: .depth, topicName: self.topicNameDepthTextField.text!) ?? false {
            uiSwitch.setOn(true, animated: true)
            self.updateTopicState(uiSwitch: uiSwitch, pubType: pubType, topicName: topicName)
        } else {
            // Disable pub and turn off switch
            self.pubController?.disablePub(pubType: pubType)
            uiSwitch.setOn(false, animated: true)
        }
    }
    
    private func updateTopicState(uiSwitch: UISwitch, pubType: PubController.PubType, topicName: String) {
        if uiSwitch.isOn {
            // Enable publishing
            if self.pubController?.enablePub(pubType: pubType, topicName: topicName) ?? false {
                // Enable master switch if not already enabled
                if !self.masterSwitch.isOn {
                    self.masterSwitch.setOn(true, animated: true)
                    self.updateMasterSwitch()
                }
            } else {
                // Enabling failed, so disable and turn off switch
                uiSwitch.setOn(false, animated: true)
                self.pubController?.disablePub(pubType: pubType)
            }
        } else {
            // Disable publishing
            self.pubController?.disablePub(pubType: pubType)
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
