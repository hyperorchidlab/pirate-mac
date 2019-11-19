//
//  Setting.swift
//  Pirate
//
//  Created by hyperorchid on 2019/11/8.
//  Copyright © 2019 hyperorchid. All rights reserved.
//

import Cocoa

class Setting: NSWindowController {

        @IBOutlet weak var NetWorkBox: NSComboBox!
        @IBOutlet weak var TokenAddrTF: NSTextField!
        @IBOutlet weak var MircroPayAddrTF: NSTextField!
        @IBOutlet weak var DNSTF: NSTextField!
        @IBOutlet weak var PriceTF: NSTextField!
        @IBOutlet weak var RefundTimeTF: NSTextField!
        @IBOutlet weak var PoolDepositTF: NSTextField!
        @IBOutlet weak var MinerDepositTF: NSTextField!
        
        @IBOutlet weak var ApiUrlTF: NSTextField!
        
        override func windowDidLoad() {
                super.windowDidLoad()
                self.TokenAddrTF.stringValue = TOKEN_ADDRESS
                self.MircroPayAddrTF.stringValue = MICROPAY_SYSTEM_ADDRESS
                self.DNSTF.stringValue = Service.sharedInstance.srvConf.dns
                self.ApiUrlTF.stringValue = BLOCKCHAIN_API_URL
                self.PriceTF.stringValue = String(format: "%0.4f", Service.sharedInstance.srvConf.packetPrice)
                self.RefundTimeTF.doubleValue = Service.sharedInstance.srvConf.refundTime
                self.PoolDepositTF.stringValue = String(format: "%0.4f", Service.sharedInstance.srvConf.PoolGTN.CoinValue())
                self.MinerDepositTF.stringValue = String(format: "%0.4f", Service.sharedInstance.srvConf.MinerGTN.CoinValue())
        }
    
        @IBAction func SetDNS(_ sender: Any) {
                Service.sharedInstance.srvConf.SetDNS(dns: DNSTF.stringValue)
                dialogOK(question: "Tips", text: "Success")
        }
        
        @IBAction func ExitAct(_ sender: Any) {
                self.close()
        }
}
