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
    
    // Global/connection
    private let urlTextField = UITextField()
    private let urlTextFieldLabel = UILabel()
    private let statusSwitch = UISwitch()
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
        
        // WebSocket URL field, label, and global switch
        urlTextField.borderStyle = UITextField.BorderStyle.bezel
        urlTextField.clearButtonMode = UITextField.ViewMode.whileEditing
        urlTextField.autocorrectionType = UITextAutocorrectionType.no
        urlTextField.placeholder = "192.168.0.xyz:abcd"
        urlTextField.addTarget(self, action: #selector(viewValueChanged), for: .editingDidEndOnExit)
        
        urlTextFieldLabel.attributedText = NSAttributedString(string: "Remote bridge")
        
        statusSwitch.preferredStyle = UISwitch.Style.checkbox
        statusSwitch.addTarget(self, action: #selector(statusChanged), for: .valueChanged)
        
        // Depth topic name field, label, and switch
        topicNameDepthTextField.borderStyle = UITextField.BorderStyle.bezel
        topicNameDepthTextField.clearButtonMode = UITextField.ViewMode.whileEditing
        topicNameDepthTextField.autocorrectionType = UITextAutocorrectionType.no
        topicNameDepthTextField.placeholder = "/topic_depth"
        topicNameDepthTextField.text = topicNameDepthTextField.placeholder
        topicNameDepthTextField.addTarget(self, action: #selector(viewValueChanged), for: .editingDidEndOnExit)
        
        topicNameDepthTextFieldLabel.attributedText = NSAttributedString(string: "Depth map")
        
        statusSwitchDepth.preferredStyle = UISwitch.Style.checkbox
        statusSwitchDepth.addTarget(self, action: #selector(statusChanged), for: .valueChanged)
        
        // Point cloud topic name field and label
        topicNamePointCloudTextField.borderStyle = UITextField.BorderStyle.bezel
        topicNamePointCloudTextField.clearButtonMode = UITextField.ViewMode.whileEditing
        topicNamePointCloudTextField.autocorrectionType = UITextAutocorrectionType.no
        topicNamePointCloudTextField.placeholder = "/topic_pointcloud"
        topicNamePointCloudTextField.text = topicNamePointCloudTextField.placeholder
        topicNamePointCloudTextField.addTarget(self, action: #selector(viewValueChanged), for: .editingDidEndOnExit)
        
        topicNamePointCloudTextFieldLabel.attributedText = NSAttributedString(string: "Point cloud")
        
        statusSwitchPointCloud.preferredStyle = UISwitch.Style.checkbox
        statusSwitchPointCloud.addTarget(self, action: #selector(statusChanged), for: .valueChanged)
        
        // Stacks
        let labelsStackView = UIStackView(arrangedSubviews: [urlTextFieldLabel, topicNameDepthTextFieldLabel, topicNamePointCloudTextFieldLabel])
        labelsStackView.isHidden = !isUIEnabled
        labelsStackView.translatesAutoresizingMaskIntoConstraints = false
        labelsStackView.axis = .vertical
        labelsStackView.spacing = 10
        labelsStackView.alignment = UIStackView.Alignment.fill
        labelsStackView.distribution = UIStackView.Distribution.fillEqually
        let textFieldsStackView = UIStackView(arrangedSubviews: [urlTextField, topicNameDepthTextField, topicNamePointCloudTextField])
        textFieldsStackView.isHidden = !isUIEnabled
        textFieldsStackView.translatesAutoresizingMaskIntoConstraints = false
        textFieldsStackView.axis = .vertical
        textFieldsStackView.spacing = 10
        textFieldsStackView.alignment = UIStackView.Alignment.fill
        textFieldsStackView.distribution = UIStackView.Distribution.fillEqually
        let statusSwitchesView = UIStackView(arrangedSubviews: [statusSwitch, statusSwitchDepth, statusSwitchPointCloud])
        statusSwitchesView.isHidden = !isUIEnabled
        statusSwitchesView.translatesAutoresizingMaskIntoConstraints = false
        statusSwitchesView.spacing = 10
        statusSwitchesView.axis = .vertical
        statusSwitchesView.alignment = UIStackView.Alignment.center
        statusSwitchesView.distribution = UIStackView.Distribution.fill
        
        let rosStackView = UIStackView(arrangedSubviews: [labelsStackView, textFieldsStackView, statusSwitchesView])
        rosStackView.isHidden = !isUIEnabled
        rosStackView.translatesAutoresizingMaskIntoConstraints = false
        rosStackView.axis = .horizontal
        rosStackView.spacing = 10
        
        let separator = UIView()
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        separator.backgroundColor = UIColor.init(white: 1.0, alpha: 0.5)
        
        // Then stacked vertically
        let stackView = UIStackView(arrangedSubviews: [rosStackView, separator, confidenceControl, rgbRadiusSlider])
        stackView.isHidden = !isUIEnabled
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 20
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50)
        ])
        
        Timer.scheduledTimer(timeInterval: 1.0/10.0, target: self, selector: #selector(updatePub), userInfo: nil, repeats: true)
    }
    
    @objc
    private func updatePub() {
        // TODO move to more appropriate place (non UI thread)
        let currentFrame = session.currentFrame
        if nil != currentFrame {
            let timestamp = currentFrame!.timestamp
            let depthMap = currentFrame!.sceneDepth?.depthMap
            let pointCloud = currentFrame!.rawFeaturePoints?.points
            if nil != depthMap && nil != pointCloud {
                self.pubController?.update(time: timestamp, depthMap: depthMap!, points: pointCloud!)
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
            
        case urlTextField:
            self.enableAndUpdateSwitch(uiSwitch: self.statusSwitch, url: self.urlTextField.text, topicNameDepth: self.topicNameDepthTextField.text, topicNamePointCloud: self.topicNamePointCloudTextField.text)
            
        case topicNameDepthTextField:
            self.enableAndUpdateSwitch(uiSwitch: self.statusSwitchDepth, url: nil, topicNameDepth: self.topicNameDepthTextField.text, topicNamePointCloud: nil)
            
        case topicNamePointCloudTextField:
            self.enableAndUpdateSwitch(uiSwitch: self.statusSwitchPointCloud, url: nil, topicNameDepth: nil, topicNamePointCloud: self.topicNamePointCloudTextField.text)
            
        default:
            break
        }
    }
    
    @objc
    private func statusChanged(view: UIView) {
        switch view {
            
        case statusSwitch:
            if self.statusSwitch.isOn {
                self.enableAndUpdateSwitch(uiSwitch: self.statusSwitch, url: nil, topicNameDepth: self.topicNameDepthTextField.text, topicNamePointCloud: self.topicNamePointCloudTextField.text)
            } else {
                self.pubController?.disable()
            }
            
        case statusSwitchDepth:
            if self.statusSwitchDepth.isOn {
                self.enableAndUpdateSwitch(uiSwitch: self.statusSwitchDepth, url: nil, topicNameDepth: self.topicNameDepthTextField.text, topicNamePointCloud: nil)
            } else {
                // Disable the right publisher
                self.pubController?.disableDepth()
            }
            
        case statusSwitchPointCloud:
            if self.statusSwitchPointCloud.isOn {
                self.enableAndUpdateSwitch(uiSwitch: self.statusSwitchPointCloud,url: nil, topicNameDepth: nil, topicNamePointCloud: self.topicNamePointCloudTextField.text)
            } else {
                // Disable the right publisher
                self.pubController?.disablePointCloud()
            }
            
        default:
            break
        }
    }
    
    private func enableAndUpdateSwitch(uiSwitch: UISwitch, url: String?, topicNameDepth: String?, topicNamePointCloud: String?) {
        var result = true
        if nil != topicNameDepth {
            if self.pubController?.enableDepth(topicName: topicNameDepth!) ?? false {
                self.statusSwitchDepth.setOn(true, animated: true)
            } else {
                result = false
            }
        }
        if nil != topicNamePointCloud {
            if self.pubController?.enablePointCloud(topicName: topicNamePointCloud!) ?? false {
                self.statusSwitchPointCloud.setOn(true, animated: true)
            } else {
                result = false
            }
        }
        let enableResult = self.pubController?.enable(url: url, topicNameDepth: topicNameDepth, topicNamePointCloud: topicNamePointCloud)
        if enableResult != nil {
            uiSwitch.setOn(enableResult! && result, animated: true)
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
