//
//  MinerSelectCtrl.swift
//  Pirate
//
//  Created by hyperorchid on 2019/11/14.
//  Copyright © 2019 hyperorchid. All rights reserved.
//

import Cocoa

class MinerSelectCtrl: NSWindowController {
        @IBOutlet weak var MinserAddress: NSTextField!
        
        @IBOutlet weak var MinerTableView: NSScrollView!
        override func windowDidLoad() {
                super.windowDidLoad()
        }
    
        @IBOutlet weak var Zone: NSTextField!
        
        @IBOutlet weak var IPAddress: NSTextField!
        
        @IBOutlet weak var PingValue: NSTextField!
        
        @IBAction func TestPingValue(_ sender: Any) {
        }
        @IBAction func ExitAct(_ sender: Any) {
        }
        
        @IBAction func ChangeMinersAct(_ sender: Any) {
        }
        
        @IBAction func PingAllMiners(_ sender: Any) {
        }
        
}
