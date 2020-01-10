//
//  FreeTokenWindowController.swift
//  Pirate
//
//  Created by hyperorchid on 2020/1/10.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Cocoa
import DecentralizedShadowSocks

class FreeTokenWindowController: NSWindowController {
        
        @IBOutlet weak var WaitingTips: NSProgressIndicator!
        @IBOutlet weak var TXTips: NSTextField!
        override func windowDidLoad() {
                super.windowDidLoad()
        }
        
        @IBAction func ApplyEth(_ sender: NSButton) {
                let addr = Wallet.CurrentWallet.MainAddress
                
                if addr == ""{
                        dialogOK(question: "TIPS",text: "Please create wallet first")
                        return
                }
                if Wallet.CurrentWallet.EthBalance.doubleValue >= 0.05{
                        dialogOK(question: "TIPS",text: "Your balance is more than 0.05ETH")
                        return
                }
                guard let ret = ApplyFreeEth(addr.toGoString()) else{
                        return
                }
                TXTips.stringValue = String(cString:ret)
        }
        
        @IBAction func ApplyHOP(_ sender: Any) {
                let addr = Wallet.CurrentWallet.MainAddress
                
                if addr == ""{
                        dialogOK(question: "TIPS",text: "Please create wallet first")
                        return
                }
                
                if Wallet.CurrentWallet.TokenBalance.doubleValue >= 500{
                        dialogOK(question: "TIPS",text: "Your balance is more than 500HOP")
                        return
                }                
                guard let ret = ApplyFreeToken(addr.toGoString()) else{
                        return
                }
                TXTips.stringValue = String(cString:ret)
        }
}
