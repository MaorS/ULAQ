//
//  BlueSTSDKManager.swift
//  ULAQ
//
//  Created by msapps on 08/06/2017.
//  Copyright © 2017 msapps. All rights reserved.
//

import UIKit
import BlueSTSDK

typealias Axis = (x : Double, y : Double , z : Double)

protocol BleManagerDelegate : class {
    func didAccelerometerChanged(axis: Axis)
    func nodeDidConnect()
    func nodeDidConnectionGone()
}

class BleManager : NSObject,BlueSTSDKFeatureDelegate,BlueSTSDKFeatureAutoConfigurableDelegate,BlueSTSDKNodeStateDelegate{
    
    var node : BlueSTSDKNode?
    var features : [BlueSTSDKFeature]?
    var delegate : BleManagerDelegate?
    var state : BlueSTSDKNodeState?
    
    // shared instance
    static let shared = BleManager()
    private override init() {}
    
    // Setup the manager with node
    func configManager(with node : BlueSTSDKNode){
        self.node = node
        node.connect()
        node.addStatusDelegate(self)
    }
    
    // MARK : - BlueSTSDKFeatureDelegate
    func didUpdate(_ feature: BlueSTSDKFeature, sample: BlueSTSDKFeatureSample) {
        
        let x = sample.data[0]
        let y = sample.data[1]
        let z = sample.data[2]
        
        if feature.name == accelerometer{
            self.delegate?.didAccelerometerChanged(axis: Axis(x : x.doubleValue, y : y.doubleValue , z : z.doubleValue))
        }
        
    }
    
    // MARK : - BlueSTSDKNodeStateDelegate
    func node(_ node: BlueSTSDKNode, didChange newState: BlueSTSDKNodeState, prevState: BlueSTSDKNodeState) {
        // update current state
        self.state = newState
        
        switch newState {
        case .connected:
            getfeatures(from: node)
            return
        case .lost : fallthrough
        case .unreachable : fallthrough
        case .dead : self.delegate?.nodeDidConnectionGone()
        default : return
        }
    }
    
    // MARK : - Get features from node
    func getfeatures(from node : BlueSTSDKNode){
        let features : [BlueSTSDKFeature] = node.getFeatures()
        
        for feature in features{
            if feature.enabled && feature.name == accelerometer{
                self.features?.append(feature)
                if node.isEnableNotification(feature){
                    node.disableNotification(feature)
                    if let _feature = feature as? BlueSTSDKFeatureAutoConfigurable{
                        _feature.removeFeatureConfigurationDelegate(self)
                    }
                    feature.remove(self)
                }else{
                    
                    if let _feature = feature as? BlueSTSDKFeatureAutoConfigurable{
                        _feature.addFeatureConfigurationDelegate(self)
                        _feature.startAutoConfiguration()
                    }
                    feature.add(self)
                    self.node?.enableNotification(feature)
                    
                }
            }
            
        }
        
    }
}
