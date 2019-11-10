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
//        var ChannelCtrl:ChooseChannelController!
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
                                                       name: PayChannelChangedNoti, object: nil)
                
                NotificationCenter.default.addObserver(self, selector:#selector(UpdateVpnStatus(notification:)),
                                                       name: Service.VPNStatusChanged, object: nil)
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
                
                if allPayChannels.numberOfItems == MPCManager.PayChannels.count + 2{
                        return
                }
                
                while allPayChannels.numberOfItems > 2 {
                        allPayChannels.removeItem(at: 2)
                }
                
                let channles = MPCManager.PayChannels
                for (_, c) in channles.values.enumerated() {
                        let pool = MinerPool.cachedPools[c.MainAddr]
                        let menuItem = NSMenuItem(title: (pool?.ShortName)!,
                                                   action:#selector(MenuController.ChangeChannelInUse(_:)),
                                                   keyEquivalent: "")
                        menuItem.representedObject = c
                        menuItem.target = self
                        allPayChannels.addItem(menuItem)
                        if Service.sharedInstance.srvConf.poolInUsed == c.MainAddr {
                                self.selMenuItem = menuItem
                                menuItem.state = .on
                                self.channelName.title = (pool?.ShortName)!
                        }
                }
        }
        
        @IBAction func ChangeChannelInUse(_ sender: NSMenuItem){
                guard let myItem = sender.representedObject as? MicroPayChannel else{
                        return
                }
                self.selMenuItem?.state = .off
                sender.state = .on
                let pool = MinerPool.cachedPools[myItem.MainAddr]
                self.selMenuItem = sender
                self.channelName.title = (pool?.ShortName)!
                
               Service.sharedInstance.srvConf.changeUsedPool(addr: myItem.MainAddr)
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
        
        @IBAction func ShowMinerPoolView(_ sender: NSMenuItem) {
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
//                if ChannelCtrl != nil {
//                        ChannelCtrl.close()
//                }
//                ChannelCtrl = ChooseChannelController(windowNibName: "ChooseChannelController")
//                ChannelCtrl.showWindow(self)
//                NSApp.activate(ignoringOtherApps: true)
//                ChannelCtrl.window?.makeKeyAndOrderFront(nil)
        }
}
