//
//  MainVC.swift
//  ULAQ
//
//  Created by Maor Shams on 07/06/2017.
//  Copyright © 2017 Maor Shams. All rights reserved.
//

import UIKit
import BlueSTSDK

class MainVC: UIViewController ,UITableViewDelegate,UITableViewDataSource,BlueSTSDKManagerDelegate, BlueSTSDKNodeStateDelegate{

    @IBOutlet weak var tableView : UITableView!
    
    var manager : BlueSTSDKManager
    var nodes : [BlueSTSDKNode]
    
    let DISCOVERY_TIMEOUT : Int32 = (10 * 1000)
    let ERROR_MSG_TIMEOUT = (3.0)
    
    required init?(coder aDecoder: NSCoder) {
        manager = BlueSTSDKManager.sharedInstance()
        nodes = manager.nodes() as! [BlueSTSDKNode]
        super.init(coder: aDecoder)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        manager.add(self)
        manager.discoveryStart()
        
        if !manager.nodes().isEmpty{
            for node in manager.nodes(){
                if let _node = node as? BlueSTSDKNode{
                    if _node.isConnected(){
                        _node.disconnect()
                    }
                }
            }
            manager.resetDiscovery()
            tableView.reloadData()
        }
        
        manager.discoveryStart(DISCOVERY_TIMEOUT)
        self.setNavigationDiscoveryButton()
    }
    
    func setNavigationDiscoveryButton() {
        if manager.isDiscovering() {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(self.manageDiscoveryButton))
        }
        else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(self.manageDiscoveryButton))
        }
    }
    
    
    func manageDiscoveryButton() {
        if manager.isDiscovering() {
            manager.discoveryStop()
        }
        else {
            //remove old data
            manager.resetDiscovery()
            tableView.reloadData()
            //start to discovery new data
            manager.discoveryStart(DISCOVERY_TIMEOUT)
        }
    }
    // MARK: - BlueSTSDKManagerDelegate
    
    func manager(_ manager: BlueSTSDKManager!, didChangeDiscovery enable: Bool) {
        DispatchQueue.main.sync {
            self.setNavigationDiscoveryButton()
        }
    }
    func manager(_ manager: BlueSTSDKManager!, didDiscover node: BlueSTSDKNode!) {
        DispatchQueue.main.async {
            self.nodes.append(node)
            self.tableView.reloadData()
        }
    }
    
    // MARK: - BlueSTSDKNodeStatusDelegate
    
    func node(_ node: BlueSTSDKNode, didChange newState: BlueSTSDKNodeState, prevState: BlueSTSDKNodeState) {
        print(node)
        if newState == .connected{
            
            DispatchQueue.main.sync {
                tableView.reloadData()
            }
        }
    }
    
    // MARK: - TABLEVIEW DELEGATE
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nodes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let node = nodes[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        
        cell?.textLabel?.text = node.name
        cell?.detailTextLabel?.text = node.address
        
        return cell!
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let node = nodes[indexPath.row]
        node.connect()
        node.addStatusDelegate(self)
        /////
        BleManager.shared.configManager(with: node)
        self.performSegue(withIdentifier: "gameSegue", sender: node)
    }
    

}
