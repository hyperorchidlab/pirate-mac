//
//  SysLog.swift
//  Pirate
//
//  Created by hyperorchid on 2019/11/12.
//  Copyright © 2019 hyperorchid. All rights reserved.
//

import Cocoa
import DecentralizedShadowSocks

class SysLogController: NSWindowController {
        @IBOutlet weak var logScrView: NSScrollView!
        @IBOutlet weak var PoolAddrTF: NSTextField!
        
        override func windowDidLoad() {
                super.windowDidLoad()
                NotificationCenter.default.addObserver(self, selector:#selector(LogChanged(notification:)),
                name: NewLibLogs, object: nil)
                
                for (_, value) in Service.LogCache.enumerated(){
                        self.logScrView.documentView?.insertText(value)
                }
        }
    
        @objc func LogChanged(notification: Notification){
                
                guard let log = notification.userInfo?["log"] else{
                        return
                }
                
                DispatchQueue.main.async {
                         self.logScrView.documentView?.insertText(log)
                }
        }
        
        @IBAction func ShowReceiptAction(_ sender: Any) {
                
                guard let ret = showReceipt(self.PoolAddrTF!.stringValue.toGoString())else{
                        self.logScrView.documentView?.insertText("\n------>: NO RECEIPT------>\n")
                        return
                }
                
                self.logScrView.documentView?.insertText(String(cString:ret))
        }
        
        
        @IBAction func ExitWin(_ sender: Any) {
                self.close()
        }
}
