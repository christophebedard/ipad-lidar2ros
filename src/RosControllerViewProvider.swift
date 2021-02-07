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
import UIKit
import OSLog
import ARKit

/// Class providing a view with ROS-related controls.
final class RosControllerViewProvider {
    private let logger = Logger(subsystem: "com.christophebedard.lidar2ros", category: "RosControllerViewProvider")
    
    // Global/connection
    private let urlTextField = UITextField()
    private let urlTextFieldLabel = UILabel()
    private let masterSwitch = UISwitch()
    // Transforms
    private let transformsLabel = UILabel()
    private let transformsSwitch = UISwitch()
    // Depth
    private let topicNameDepthTextField = UITextField()
    private let topicNameDepthTextFieldLabel = UILabel()
    private let statusSwitchDepth = UISwitch()
    // Point cloud
    private let topicNamePointCloudTextField = UITextField()
    private let topicNamePointCloudTextFieldLabel = UILabel()
    private let statusSwitchPointCloud = UISwitch()
    // Camera image
    private let topicNameCameraImageTextField = UITextField()
    private let topicNameCameraImageTextFieldLabel = UILabel()
    private let statusSwitchCameraImage = UISwitch()
    
    private var session: ARSession
    private var pubController: PubController
    
    public private(set) var view: UIView?
    
    init(pubController: PubController, session: ARSession) {
        self.logger.debug("init")
        
        self.pubController = pubController
        self.session = session
        
        // WebSocket URL field, label, and global switch
        self.createLabelTextFieldSwitchViews(uiLabel: urlTextFieldLabel, uiTextField: urlTextField, uiStatusSwitch: masterSwitch, labelText: "Remote bridge", textFieldPlaceholder: "192.168.0.xyz:abcd")
        // Transforms
        self.createLabelTextFieldSwitchViews(uiLabel: transformsLabel, uiTextField: nil, uiStatusSwitch: transformsSwitch, labelText: "Transforms", textFieldPlaceholder: nil)
        // Depth topic name field, label, and switch
        self.createLabelTextFieldSwitchViews(uiLabel: topicNameDepthTextFieldLabel, uiTextField: topicNameDepthTextField, uiStatusSwitch: statusSwitchDepth, labelText: "Depth map", textFieldPlaceholder: "/ipad/depth", useAsDefaultText: true)
        // Point cloud topic name field and label
        self.createLabelTextFieldSwitchViews(uiLabel: topicNamePointCloudTextFieldLabel, uiTextField: topicNamePointCloudTextField, uiStatusSwitch: statusSwitchPointCloud, labelText: "Point cloud", textFieldPlaceholder: "/ipad/pointcloud", useAsDefaultText: true)
        // Camera image topic name field, label, and switch
        self.createLabelTextFieldSwitchViews(uiLabel: topicNameCameraImageTextFieldLabel, uiTextField: topicNameCameraImageTextField, uiStatusSwitch: statusSwitchCameraImage, labelText: "Camera", textFieldPlaceholder: "/ipad/camera", useAsDefaultText: true)
        
        // Stack with all the ROS config
        let labelsStackView = self.createVerticalStack(arrangedSubviews: [urlTextFieldLabel, transformsLabel, topicNameDepthTextFieldLabel, topicNamePointCloudTextFieldLabel, topicNameCameraImageTextFieldLabel])
        let textFieldsStackView = self.createVerticalStack(arrangedSubviews: [urlTextField, UIView(), topicNameDepthTextField, topicNamePointCloudTextField, topicNameCameraImageTextField])
        let statusSwitchesView = self.createVerticalStack(arrangedSubviews: [masterSwitch, transformsSwitch, statusSwitchDepth, statusSwitchPointCloud, statusSwitchCameraImage])
        let rosStackView = UIStackView(arrangedSubviews: [labelsStackView, textFieldsStackView, statusSwitchesView])
        //rosStackView.isHidden = !isUIEnabled
        rosStackView.translatesAutoresizingMaskIntoConstraints = false
        rosStackView.axis = .horizontal
        rosStackView.spacing = 10
        
        self.view = rosStackView
        
        // TODO extract to separate class
        Timer.scheduledTimer(timeInterval: 1.0/10.0, target: self, selector: #selector(updatePub), userInfo: nil, repeats: true)
    }
    
    private func createLabelTextFieldSwitchViews(uiLabel: UILabel, uiTextField: UITextField?, uiStatusSwitch: UISwitch, labelText: String, textFieldPlaceholder: String?, useAsDefaultText: Bool = false) {
        if nil != uiTextField {
            uiTextField!.borderStyle = UITextField.BorderStyle.bezel
            uiTextField!.clearButtonMode = UITextField.ViewMode.whileEditing
            uiTextField!.autocorrectionType = UITextAutocorrectionType.no
            if nil != textFieldPlaceholder {
                uiTextField!.placeholder = textFieldPlaceholder
                if useAsDefaultText {
                    uiTextField!.text = textFieldPlaceholder
                }
            }
            uiTextField!.addTarget(self, action: #selector(viewValueChanged), for: .editingDidEndOnExit)
        }
        uiLabel.attributedText = NSAttributedString(string: labelText)
        uiStatusSwitch.preferredStyle = UISwitch.Style.checkbox
        uiStatusSwitch.addTarget(self, action: #selector(switchStatusChanged), for: .valueChanged)
    }
    
    private func createVerticalStack(arrangedSubviews: [UIView]) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: arrangedSubviews)
        //stackView.isHidden = !isUIEnabled
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.alignment = UIStackView.Alignment.fill
        stackView.distribution = UIStackView.Distribution.fillEqually
        return stackView
    }
    
    @objc
    private func viewValueChanged(view: UIView) {
        switch view {
            
        case self.urlTextField:
            self.updateUrl()
            
        case self.topicNameDepthTextField:
            self.updatePubTopic(uiSwitch: self.statusSwitchDepth, pubType: .depth, topicName: self.topicNameDepthTextField.text!)
            
        case self.topicNamePointCloudTextField:
            self.updatePubTopic(uiSwitch: self.statusSwitchPointCloud, pubType: .pointCloud, topicName: self.topicNamePointCloudTextField.text!)
            
        case self.topicNameCameraImageTextField:
            self.updatePubTopic(uiSwitch: self.statusSwitchCameraImage, pubType: .camera, topicName: self.topicNameCameraImageTextField.text!)
            
        default:
            break
        }
    }
    
    @objc
    private func switchStatusChanged(view: UIView) {
        switch view {
            
        case self.masterSwitch:
            self.updateMasterSwitch()
            
        case self.transformsSwitch:
            self.updateTopicState(uiSwitch: self.transformsSwitch, pubType: .transforms, topicName: nil)
            
        case self.statusSwitchDepth:
            self.updateTopicState(uiSwitch: self.statusSwitchDepth, pubType: .depth, topicName: self.topicNameDepthTextField.text!)
            
        case self.statusSwitchPointCloud:
            self.updateTopicState(uiSwitch: self.statusSwitchPointCloud, pubType: .pointCloud, topicName: self.topicNamePointCloudTextField.text!)
            
        case self.statusSwitchCameraImage:
            self.updateTopicState(uiSwitch: self.statusSwitchCameraImage, pubType: .camera, topicName: self.topicNameCameraImageTextField.text!)
            
        default:
            break
        }
    }
    
    private func updateUrl() {
        // Enable pub controller and/or update URL
        if self.pubController.enable(url: self.urlTextField.text) {
            // It worked, so turn switch on
            self.masterSwitch.setOn(true, animated: true)
        } else {
            // It fails, so turn off switch and disable
            self.masterSwitch.setOn(false, animated: true)
            self.pubController.disable()
        }
    }
    
    private func updateMasterSwitch() {
        if self.masterSwitch.isOn {
            self.updateUrl()
        } else {
            // Disable pub controller
            self.pubController.disable()
        }
    }
    
    private func updatePubTopic(uiSwitch: UISwitch, pubType: PubController.PubType, topicName: String?) {
        if self.pubController.updatePubTopic(pubType: .depth, topicName: self.topicNameDepthTextField.text!) {
            uiSwitch.setOn(true, animated: true)
            self.updateTopicState(uiSwitch: uiSwitch, pubType: pubType, topicName: topicName)
        } else {
            // Disable pub and turn off switch
            self.pubController.disablePub(pubType: pubType)
            uiSwitch.setOn(false, animated: true)
        }
    }
    
    private func updateTopicState(uiSwitch: UISwitch, pubType: PubController.PubType, topicName: String?) {
        if uiSwitch.isOn {
            // Enable publishing
            if self.pubController.enablePub(pubType: pubType, topicName: topicName) {
                // Enable master switch if not already enabled
                if !self.masterSwitch.isOn {
                    self.masterSwitch.setOn(true, animated: true)
                    self.updateMasterSwitch()
                }
            } else {
                // Enabling failed, so disable and turn off switch
                uiSwitch.setOn(false, animated: true)
                self.pubController.disablePub(pubType: pubType)
            }
        } else {
            // Disable publishing
            self.pubController.disablePub(pubType: pubType)
        }
    }
    
    @objc
    private func updatePub() {
        // TODO move to more appropriate place (non UI thread)
        let currentFrame = self.session.currentFrame
        if nil != currentFrame {
            let timestamp = currentFrame!.timestamp
            let depthMap = currentFrame!.sceneDepth?.depthMap
            let pointCloud = currentFrame!.rawFeaturePoints?.points
            let cameraTf = currentFrame!.camera.transform
            let cameraImage = currentFrame!.capturedImage
            if nil != depthMap && nil != pointCloud {
                self.pubController.update(time: timestamp, depthMap: depthMap!, points: pointCloud!, cameraTf: cameraTf, cameraImage: cameraImage)
            }
        }
    }
}
