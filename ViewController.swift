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
    
    private let urlTextField = UITextField()
    private let urlTextFieldLabel = UILabel()
    private let statusSwitch = UISwitch()
    private let topicNameTextField = UITextField()
    private let topicNameTextFieldLabel = UILabel()
    
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
        
        // WebSocket URL field and label
        urlTextField.borderStyle = UITextField.BorderStyle.bezel
        urlTextField.clearButtonMode = UITextField.ViewMode.whileEditing
        urlTextField.autocorrectionType = UITextAutocorrectionType.no
        urlTextField.placeholder = "192.168.0.xyz:abcd"
        urlTextField.addTarget(self, action: #selector(viewValueChanged), for: .editingDidEndOnExit)
        urlTextFieldLabel.attributedText = NSAttributedString(string: "IP and port")
        
        // Topic name field and label
        topicNameTextField.borderStyle = UITextField.BorderStyle.bezel
        topicNameTextField.clearButtonMode = UITextField.ViewMode.whileEditing
        topicNameTextField.autocorrectionType = UITextAutocorrectionType.no
        topicNameTextField.placeholder = "/my_topic"
        topicNameTextField.text = topicNameTextField.placeholder
        topicNameTextField.addTarget(self, action: #selector(viewValueChanged), for: .editingDidEndOnExit)
        topicNameTextFieldLabel.attributedText = NSAttributedString(string: "Topic name")
        
        // Switch
        statusSwitch.preferredStyle = UISwitch.Style.checkbox
        statusSwitch.addTarget(self, action: #selector(statusChanged), for: .valueChanged)
        
        // Stacks
        let labelsStackView = UIStackView(arrangedSubviews: [urlTextFieldLabel, topicNameTextFieldLabel])
        labelsStackView.isHidden = !isUIEnabled
        labelsStackView.translatesAutoresizingMaskIntoConstraints = false
        labelsStackView.axis = .vertical
        labelsStackView.spacing = 10
        labelsStackView.alignment = UIStackView.Alignment.fill
        labelsStackView.distribution = UIStackView.Distribution.fillEqually
        let textFieldsStackView = UIStackView(arrangedSubviews: [urlTextField, topicNameTextField])
        textFieldsStackView.isHidden = !isUIEnabled
        textFieldsStackView.translatesAutoresizingMaskIntoConstraints = false
        textFieldsStackView.axis = .vertical
        textFieldsStackView.spacing = 10
        textFieldsStackView.alignment = UIStackView.Alignment.fill
        textFieldsStackView.distribution = UIStackView.Distribution.fillEqually
        let statusSwitchView = UIStackView(arrangedSubviews: [statusSwitch])
        statusSwitchView.isHidden = !isUIEnabled
        statusSwitchView.translatesAutoresizingMaskIntoConstraints = false
        statusSwitchView.axis = .horizontal
        textFieldsStackView.spacing = 10
        statusSwitchView.alignment = UIStackView.Alignment.center
        statusSwitchView.distribution = UIStackView.Distribution.fill
        
        let rosStackView = UIStackView(arrangedSubviews: [labelsStackView, textFieldsStackView, statusSwitchView])
        rosStackView.isHidden = !isUIEnabled
        rosStackView.translatesAutoresizingMaskIntoConstraints = false
        rosStackView.axis = .horizontal
        rosStackView.spacing = 10
        labelsStackView.alignment = UIStackView.Alignment.center
        labelsStackView.distribution = UIStackView.Distribution.fill
        
        // Then stacked vertically
        let stackView = UIStackView(arrangedSubviews: [rosStackView, confidenceControl, rgbRadiusSlider])
        stackView.isHidden = !isUIEnabled
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 20
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50)
        ])
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
            self.enableAndUpdateSwitch(url: self.urlTextField.text, topicName: self.topicNameTextField.text)
            
        case topicNameTextField:
            self.enableAndUpdateSwitch(url: nil, topicName: self.topicNameTextField.text)
            
        default:
            break
        }
    }
    
    @objc
    private func statusChanged() {
        if self.statusSwitch.isOn {
            self.enableAndUpdateSwitch(url: nil, topicName: self.topicNameTextField.text)
        } else {
            self.pubController?.disable()
        }
    }
    
    private func enableAndUpdateSwitch(url: String?, topicName: String?) {
        let enableResult = self.pubController?.enable(url: url, topicName: topicName)
        if enableResult != nil {
            self.statusSwitch.setOn(enableResult!, animated: true)
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
        // TODO move to more appropriate place (non UI thread)
        self.pubController?.update()
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
