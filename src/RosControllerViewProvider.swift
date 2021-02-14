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
    
    private struct PubEntry {
        var label: UILabel
        var labelText: String
        var topicNameField: UITextField?
        var defaultTopicName: String?
        var stateSwitch: UISwitch
        var rateStepper: UIStepper
        var rateStepperLabel: UILabel
        var rateMin: Double = 0.5
        var rateMax: Double = 20.0
        var rateDefault: Double = PubController.defaultRate
        var rateStep: Double = 0.5
    }
    
    private let pubEntries: [PubController.PubType: PubEntry]
    private let transformsEntry: PubEntry
    private let depthEntry: PubEntry
    private let pointCloudEntry: PubEntry
    private let cameraEntry: PubEntry
    
    private let session: ARSession
    private let pubController: PubController
    
    /// The provided view.
    public private(set) var view: UIView?
    
    init(pubController: PubController, session: ARSession) {
        self.logger.debug("init")
        
        self.pubController = pubController
        self.session = session
        
        // Pub UI entries
        self.transformsEntry = PubEntry(label: UILabel(), labelText: "Transforms", topicNameField: nil, defaultTopicName: nil, stateSwitch: UISwitch(), rateStepper: UIStepper(), rateStepperLabel: UILabel())
        self.depthEntry = PubEntry(label: UILabel(), labelText: "Depth map", topicNameField: UITextField(), defaultTopicName: "/ipad/depth", stateSwitch: UISwitch(), rateStepper: UIStepper(), rateStepperLabel: UILabel())
        self.pointCloudEntry = PubEntry(label: UILabel(), labelText: "Point cloud", topicNameField: UITextField(), defaultTopicName: "/ipad/pointcloud", stateSwitch: UISwitch(), rateStepper: UIStepper(), rateStepperLabel: UILabel())
        self.cameraEntry = PubEntry(label: UILabel(), labelText: "Camera", topicNameField: UITextField(), defaultTopicName: "/ipad/camera", stateSwitch: UISwitch(), rateStepper: UIStepper(), rateStepperLabel: UILabel())
        
        self.pubEntries = [
            .transforms: self.transformsEntry,
            .depth: self.depthEntry,
            .pointCloud: self.pointCloudEntry,
            .camera: self.cameraEntry,
        ]
        
        self.initViewsFromEntry(self.transformsEntry)
        self.initViewsFromEntry(self.depthEntry)
        self.initViewsFromEntry(self.pointCloudEntry)
        self.initViewsFromEntry(self.cameraEntry)
        
        // WebSocket URL field, label, and global switch
        self.initViews(uiLabel: urlTextFieldLabel, labelText: "Remote bridge", uiTextField: urlTextField, uiStatusSwitch: masterSwitch, textFieldPlaceholder: "192.168.0.xyz:abcd")
        
        // Stack with all the ROS config
        // TODO add separator between IP address and pub controls
        let labelsStackView = self.createVerticalStack(arrangedSubviews: [urlTextFieldLabel, self.transformsEntry.label, self.depthEntry.label, self.pointCloudEntry.label, self.cameraEntry.label])
        let textFieldsStackView = self.createVerticalStack(arrangedSubviews: [urlTextField, UIView(), self.depthEntry.topicNameField!, self.pointCloudEntry.topicNameField!, self.cameraEntry.topicNameField!])
        let statusSwitchesView = self.createVerticalStack(arrangedSubviews: [masterSwitch, self.transformsEntry.stateSwitch, self.depthEntry.stateSwitch, self.pointCloudEntry.stateSwitch, self.cameraEntry.stateSwitch])
        let steppersView = self.createVerticalStack(arrangedSubviews: [UIView(), self.transformsEntry.rateStepper, self.depthEntry.rateStepper, self.pointCloudEntry.rateStepper, self.cameraEntry.rateStepper])
        let stepperDisplaysView = self.createVerticalStack(arrangedSubviews: [UIView(), self.transformsEntry.rateStepperLabel, self.depthEntry.rateStepperLabel, self.pointCloudEntry.rateStepperLabel, self.cameraEntry.rateStepperLabel])
        let rosStackView = UIStackView(arrangedSubviews: [labelsStackView, textFieldsStackView, statusSwitchesView, steppersView, stepperDisplaysView])
        rosStackView.translatesAutoresizingMaskIntoConstraints = false
        rosStackView.axis = .horizontal
        rosStackView.spacing = 10
        
        self.view = rosStackView
    }
    
    private func initViewsFromEntry(_ pubEntry: PubEntry) {
        self.initViews(uiLabel: pubEntry.label, labelText: pubEntry.labelText, uiTextField: pubEntry.topicNameField, uiStatusSwitch: pubEntry.stateSwitch, textFieldPlaceholder: pubEntry.defaultTopicName, useAsDefaultText: true, pubEntry: pubEntry)
    }
    
    private func initViews(uiLabel: UILabel, labelText: String, uiTextField: UITextField?, uiStatusSwitch: UISwitch, textFieldPlaceholder: String?, useAsDefaultText: Bool = false, pubEntry: PubEntry? = nil) {
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
            uiTextField!.addTarget(self, action: #selector(textFieldValueChanged), for: .editingDidEndOnExit)
        }
        uiLabel.attributedText = NSAttributedString(string: labelText)
        uiStatusSwitch.preferredStyle = UISwitch.Style.checkbox
        uiStatusSwitch.addTarget(self, action: #selector(switchStatusChanged), for: .valueChanged)
        if nil != pubEntry {
            pubEntry!.rateStepper.autorepeat = true
            pubEntry!.rateStepper.isContinuous = true
            pubEntry!.rateStepper.minimumValue = pubEntry!.rateMin
            pubEntry!.rateStepper.maximumValue = pubEntry!.rateMax
            pubEntry!.rateStepper.stepValue = pubEntry!.rateStep
            pubEntry!.rateStepper.value = pubEntry!.rateDefault
            pubEntry!.rateStepper.isEnabled = false
            pubEntry!.rateStepper.addTarget(self, action: #selector(stepperValueChanged), for: .valueChanged)
            pubEntry!.rateStepperLabel.text = RosControllerViewProvider.rateAsString(pubEntry!.rateStepper.value)
        }
    }
    
    private func createVerticalStack(arrangedSubviews: [UIView]) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: arrangedSubviews)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.alignment = UIStackView.Alignment.fill
        stackView.distribution = UIStackView.Distribution.fillEqually
        return stackView
    }
    
    @objc
    private func textFieldValueChanged(view: UIView) {
        switch view {
        case self.urlTextField:
            self.updateUrl()
        case self.depthEntry.topicNameField:
            self.updatePubTopic(.depth)
        case self.pointCloudEntry.topicNameField:
            self.updatePubTopic(.pointCloud)
        case self.cameraEntry.topicNameField:
            self.updatePubTopic(.camera)
        default:
            break
        }
    }
    
    @objc
    private func switchStatusChanged(view: UIView) {
        switch view {
        case self.masterSwitch:
            self.updateMasterSwitch()
        case self.transformsEntry.stateSwitch:
            self.updateTopicState(.transforms)
        case self.depthEntry.stateSwitch:
            self.updateTopicState(.depth)
        case self.pointCloudEntry.stateSwitch:
            self.updateTopicState(.pointCloud)
        case self.cameraEntry.stateSwitch:
            self.updateTopicState(.camera)
        default:
            break
        }
    }
    
     @objc
     private func stepperValueChanged(view: UIView) {
        switch view {
        case self.transformsEntry.rateStepper:
            self.updateRate(.transforms)
        case self.depthEntry.rateStepper:
            self.updateRate(.depth)
        case self.pointCloudEntry.rateStepper:
            self.updateRate(.pointCloud)
        case self.cameraEntry.rateStepper:
            self.updateRate(.camera)
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
    
    private func updatePubTopic(_ pubType: PubController.PubType) {
        let pubEntry = self.pubEntries[pubType]!
        if self.pubController.updatePubTopic(pubType: .depth, topicName: pubEntry.topicNameField?.text!) {
            pubEntry.stateSwitch.setOn(true, animated: true)
            self.updateTopicState(pubType)
        } else {
            // Disable pub and turn off switch
            self.pubController.disablePub(pubType: pubType)
            pubEntry.stateSwitch.setOn(false, animated: true)
        }
    }
    
    private func updateTopicState(_ pubType: PubController.PubType) {
        let pubEntry = self.pubEntries[pubType]!
        if pubEntry.stateSwitch.isOn {
            // Enable publishing
            if self.pubController.enablePub(pubType: pubType, topicName: pubEntry.topicNameField?.text!) {
                pubEntry.rateStepper.isEnabled = true
                // Enable master switch if not already enabled
                if !self.masterSwitch.isOn {
                    self.masterSwitch.setOn(true, animated: true)
                    self.updateMasterSwitch()
                }
            } else {
                // Enabling failed, so disable publishing & stepper and turn off switch
                pubEntry.stateSwitch.setOn(false, animated: true)
                pubEntry.rateStepper.isEnabled = false
                self.pubController.disablePub(pubType: pubType)
            }
        } else {
            // Disable publishing and stepper
            self.pubController.disablePub(pubType: pubType)
            pubEntry.rateStepper.isEnabled = false
        }
    }
    
    private func updateRate(_ pubType: PubController.PubType) {
        let pubEntry = self.pubEntries[pubType]!
        pubEntry.rateStepperLabel.text = RosControllerViewProvider.rateAsString(pubEntry.rateStepper.value)
        // TODO change pub rate
    }
    
    private static func rateAsString(_ rate: Double) -> String {
        return String(format: "%.1f Hz", rate)
    }
}
