//
//  MenuController.swift
//  Pangolin
//
//  Created by Bencong Ri on 2019/1/30.
//  Copyright © 2019 pangolink.org All rights reserved.
//

import Cocoa

class MenuController: NSObject {
      
        @IBOutlet weak var statusMenu: NSMenu!
        @IBOutlet weak var channelName: NSMenuItem!
        @IBOutlet weak var switchBtn: NSMenuItem!
        @IBOutlet weak var smartModel: NSMenuItem!
        @IBOutlet weak var globalModel: NSMenuItem!
        @IBOutlet weak var walletMenu: NSMenuItem!
        @IBOutlet weak var minerPoolMenu: NSMenuItem!
        @IBOutlet weak var allPayChannels: NSMenu!
        @IBOutlet weak var ConfigMenu: NSMenuItem!
        
        var walletCtrl: WalletController!
        var minerPoolCtrl: PacketMarketController!
        var logCtrl:SysLogController!
        var selMenuItem:NSMenuItem?
        
        let server = Service.sharedInstance
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        override func awakeFromNib() {
                let icon = NSImage(named: "statusOff")
                icon?.isTemplate = true // best for dark mode
                statusItem.button?.image = icon
                statusItem.menu = statusMenu
                updateUI()
                
                NotificationCenter.default.addObserver(self, selector:#selector(loadChannelMenu(notification:)),
                                                       name: UserDataSyncSuccess, object: nil)
                
                NotificationCenter.default.addObserver(self, selector:#selector(UpdateVpnStatus(notification:)),
                                                       name: VPNStatusChanged, object: nil)
        }
        
        func updateMenu(data: Any?, tagId: Int) {
                DispatchQueue.main.async{ self.updateUI()}
        }
        
        @objc func UpdateVpnStatus(notification:Notification){
                
                DispatchQueue.main.async {
                        self.updateUI()
                }
                guard let ui = notification.userInfo as NSDictionary? else{
                        return
                }
                let errMsg = ui["msg"] as! String
                let errNo = ui["errNo"] as! Int
                
                dialogOK(question: "VPN 关闭", text: "错误码:[\(errNo)], 错误提示:[\(errMsg)]")
        }
        
        @objc func loadChannelMenu(notification:Notification){
                
                if allPayChannels.numberOfItems == Wallet.PoolsOfUser.count + 2{
                        return
                }
                
                while allPayChannels.numberOfItems > 2 {
                        allPayChannels.removeItem(at: 2)
                }
                
                for (_, pool) in Wallet.PoolsOfUser.enumerated() {
                        
                        let menuItem = NSMenuItem(title: pool.Name,
                                                   action:#selector(MenuController.ChangeChannelInUse(_:)),
                                                   keyEquivalent: "")
                        menuItem.representedObject = pool
                        menuItem.target = self
                        allPayChannels.addItem(menuItem)
                        if Service.sharedInstance.srvConf.poolInUsed == pool.MainAddr {
                                self.selMenuItem = menuItem
                                menuItem.state = .on
                                self.channelName.title = pool.Name
                        }
                }
        }
        
        @IBAction func ChangeChannelInUse(_ sender: NSMenuItem){
                guard let pool = sender.representedObject as? MinerPool else{
                        return
                }
                self.selMenuItem?.state = .off
                sender.state = .on
                self.selMenuItem = sender
                self.channelName.title = pool.Name
                
               Service.sharedInstance.srvConf.changeUsedPool(addr: pool.MainAddr)
        }
        
        func updateUI() -> Void {                
                if server.srvConf.isTurnon {
                        switchBtn.title = "Turn Off".localized
                        statusItem.button?.image = NSImage(named: "statusOn")
                }else{
                        switchBtn.title = "Turn On".localized
                        statusItem.button?.image = NSImage(named: "statusOff")
                }
                if server.srvConf.isGlobal{
                        smartModel.state = .off
                        globalModel.state = .on
                }else{
                        smartModel.state = .on
                        globalModel.state = .off
                }
        }
        
        @IBAction func switchTurnOnOff(_ sender: NSMenuItem) {
                
                do{
                        if server.srvConf.isTurnon{
                                try server.StopServer()
                        }else{
                                let pwd = showPasswordDialog()
                                if ""==pwd{
                                        return
                                }
                                try server.StartServer(password: pwd)
                        }
                }catch{
                        dialogOK(question: "Error", text: error.localizedDescription)
                }
        }
        
        @IBAction func ShowWalletView(_ sender: NSMenuItem) {
                if walletCtrl != nil {
                        walletCtrl.close()
                }
                walletCtrl = WalletController(windowNibName: "WalletController")
                walletCtrl.showWindow(self)
                NSApp.activate(ignoringOtherApps: true)
                walletCtrl.window?.makeKeyAndOrderFront(nil)
        }
        
        @IBAction func ShowPacketMarket(_ sender: NSMenuItem) {
                if minerPoolCtrl != nil {
                        minerPoolCtrl.close()
                }
                minerPoolCtrl = PacketMarketController(windowNibName: "PacketMarketController")
                minerPoolCtrl.showWindow(self)
                NSApp.activate(ignoringOtherApps: true)
                minerPoolCtrl.window?.makeKeyAndOrderFront(nil)
        }

        @IBAction func changeModel(_ sender: NSMenuItem) {
               
                do{try server.ChangeModel(global: sender.tag == 1)}catch{
                        dialogOK(question: "Error", text: error.localizedDescription)
                        return
                }
                updateUI()
        }
        
        @IBAction func finish(_ sender: NSMenuItem) { 
                server.Exit()
                NSApplication.shared.terminate(self)
        }
        
        @IBAction func ShowStatics(_ sender: Any) {
                if logCtrl != nil {
                        logCtrl.close()
                }
                logCtrl = SysLogController(windowNibName: "SysLogController")
                logCtrl.showWindow(self)
                NSApp.activate(ignoringOtherApps: true)
                logCtrl.window?.makeKeyAndOrderFront(nil)
        }
}
