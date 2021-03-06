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
        var errorTips: String?
        
        override func windowDidLoad() {
                super.windowDidLoad()
                NotificationCenter.default.addObserver(self, selector:#selector(LogChanged(notification:)),
                name: NewLibLogs, object: nil)
                
                for (_, value) in Service.LogCache.enumerated(){
                        self.logScrView.documentView?.insertText(value)
                }
                if let err = errorTips{
                        self.logScrView.documentView?.insertText(err)
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
                
        }
        
        @IBAction func ExitWin(_ sender: Any) {
                self.close()
        }
}
