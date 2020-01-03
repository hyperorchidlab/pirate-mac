//
//  MenuController.swift
//  Pirate
//
//  Created by Bencong Ri on 2019/1/30.
//  Copyright © 2019 Pirate All rights reserved.
//

import Cocoa

class MenuController: NSObject {
      
        @IBOutlet weak var statusMenu: NSMenu!
        @IBOutlet weak var curPoolMenu: NSMenuItem!
        @IBOutlet weak var switchBtn: NSMenuItem!
        @IBOutlet weak var smartModel: NSMenuItem!
        @IBOutlet weak var globalModel: NSMenuItem!
        @IBOutlet weak var walletMenu: NSMenuItem!
        @IBOutlet weak var minerPoolMenu: NSMenuItem!
        @IBOutlet weak var allMyPools: NSMenu!
        @IBOutlet weak var curMinerMenu: NSMenuItem!
        @IBOutlet weak var DashBoardMenu: NSMenuItem!
        @IBOutlet weak var walletStatusMenu: NSMenuItem!
        
        var walletCtrl: WalletController!
        var minerPoolCtrl: PacketMarketController!
        var logCtrl:SysLogController!
        var minerSelectCtrl:MinerSelectCtrl!
        var settingCtrl:Setting!
        var extokenCtrl:ExTokenSettingController!
        
        var CurPoolInSubMenu:NSMenuItem?
        
        let server = Service.sharedInstance
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        override func awakeFromNib() {
                let icon = NSImage(named: "statusOff")
                icon?.isTemplate = true // best for dark mode
                statusItem.button?.image = icon
                statusItem.menu = statusMenu
                
                updateUI()
                updateMinerList()
                
                NotificationCenter.default.addObserver(self, selector:#selector(LoadAllMyPools(notification:)),
                                                       name: UserDataSyncSuccess, object: nil)
                NotificationCenter.default.addObserver(self, selector:#selector(UpdateVpnStatus(notification:)),
                                                       name: VPNStatusChanged, object: nil)
                NotificationCenter.default.addObserver(self, selector:#selector(ServerNodeChanged(notification:)),
                                                       name: SelectPoolOrMinerChanged, object: nil)
                NotificationCenter.default.addObserver(self, selector:#selector(WalletStChanged(_:)),
                                                      name: WalletStatusChanged, object: nil)
                NotificationCenter.default.addObserver(self, selector:#selector(DataCounterShow(noti:)),
                                                       name: DataCounterChanged, object: nil)
                
        }
        
        func updateMinerList(){
                guard let miner = Service.sharedInstance.srvConf.CurMiner() else{
                        self.curMinerMenu.title = "Chose Miner->"
                        return
                }
                self.curMinerMenu.title = String(miner.prefix(8)) + "..."
        }
        
        
        func updateMenu(data: Any?, tagId: Int) {
                DispatchQueue.main.async{ self.updateUI()}
        }
        
        @objc func ServerNodeChanged(notification:Notification){
                DispatchQueue.main.async{
                        self.updateMinerList() 
                        if self.server.srvConf.isTurnon {
                                do{ try self.server.StopServer()} catch _{
                        }
                        dialogOK(question: "VPN Closed", text: "Please reopen the service")
                }
                }
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
                if errNo == 0 {
                        dialogOK(question: "Tips", text: "VPN Start Success")
                }else{
                        dialogOK(question: "VPN Closed", text: "Code:[\(errNo)], Message:[\(errMsg)]")
                }
        }
        
        @objc func LoadAllMyPools(notification:Notification){
                allMyPools.removeAllItems()
                for (_, pool) in Wallet.PoolsOfUser.enumerated() {
                        
                        let menuItem = NSMenuItem(title: pool.Name,
                                                   action:#selector(MenuController.ChangePool(_:)),
                                                   keyEquivalent: "")
                        
                        menuItem.representedObject = pool
                        menuItem.target = self
                        allMyPools.addItem(menuItem)
                        
                        if Service.sharedInstance.srvConf.poolInUsed == pool.MainAddr {
                                self.CurPoolInSubMenu = menuItem
                                menuItem.state = .on
                                self.curPoolMenu.title = pool.Name
                        }
                }
        }
        
        @IBAction func ChangePool(_ sender: NSMenuItem){
                guard let pool = sender.representedObject as? MinerPool else{
                        return
                }
                self.CurPoolInSubMenu?.state = .off
                sender.state = .on
                self.CurPoolInSubMenu = sender
                self.curPoolMenu.title = pool.Name
                
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
                        defer {
                                self.updateUI()
                        }
                        if server.srvConf.isTurnon{
                                try server.StopServer()
                                return
                        }
                        var status = Wallet.CurrentWallet.Status
                        if !status{
                                self.SwitchWallet(sender)
                                status = Wallet.CurrentWallet.Status
                        }
                        if !status{
                                return
                        }
                        
                        try server.StartServer()
                        
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
        
        @IBAction func ShowMinerSelect(_ sender: NSMenuItem) {
                guard let pool = self.CurPoolInSubMenu?.representedObject as? MinerPool else{
                        dialogOK(question: "No Pool Selected", text: "Please chose a valid pool first")
                        return
                }
                
                if minerSelectCtrl != nil {
                        minerSelectCtrl.close()
                }
                minerSelectCtrl = MinerSelectCtrl(windowNibName: "MinerSelectCtrl")
                minerSelectCtrl.CurrntPoolAddress = pool.MainAddr
                minerSelectCtrl.window?.title = pool.Name
                minerSelectCtrl.showWindow(self)
                NSApp.activate(ignoringOtherApps: true)
                minerSelectCtrl.window?.makeKeyAndOrderFront(nil)
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
        
        @IBAction func ShowSysLog(_ sender: Any) {
                if logCtrl != nil {
                        logCtrl.close()
                }
                logCtrl = SysLogController(windowNibName: "SysLogController")
                logCtrl.showWindow(self)
                NSApp.activate(ignoringOtherApps: true)
                logCtrl.window?.makeKeyAndOrderFront(nil)
        }
        @IBAction func ShowSettings(_ sender: Any) {
                if settingCtrl != nil {
                        settingCtrl.close()
                }
                settingCtrl = Setting(windowNibName: "Setting")
                settingCtrl.showWindow(self)
                NSApp.activate(ignoringOtherApps: true)
                settingCtrl.window?.makeKeyAndOrderFront(nil)
        }
        
        @IBAction func SwitchWallet(_ sender: Any) {
                let status = Wallet.CurrentWallet.Status
                if status{
                        Wallet.CurrentWallet.CloseWallet()
                }else{
                        let pwd = showPasswordDialog()
                        if ""==pwd{
                                return
                        }
                        do {
                                try Wallet.CurrentWallet.OpenWallet(auth: pwd)}catch let err{
                                dialogOK(question: "Error", text: err.localizedDescription)
                        }
                }
                self.updateWalletStatus()
        }
        
        @IBAction func ShowExtendTokenSetting(_ sender: Any) {
                if extokenCtrl != nil {
                        extokenCtrl.close()
                }
                extokenCtrl = ExTokenSettingController(windowNibName: "ExTokenSettingController")
                extokenCtrl.showWindow(self)
                NSApp.activate(ignoringOtherApps: true)
                extokenCtrl.window?.makeKeyAndOrderFront(nil)
        }
        
        func updateWalletStatus(){
               let status = Wallet.CurrentWallet.Status
                if status {
                        self.walletStatusMenu.title = "Wallet:Opened"
                }else{
                        self.walletStatusMenu.title = "Wallet:Closed"
                }
        }
        
        @objc func WalletStChanged(_:Notification){
                self.updateWalletStatus()
        }
        @objc func DataCounterShow(noti:Notification){
                guard let counter = noti.userInfo?["count"] as? String else {
                        return
                }
                DispatchQueue.main.async{
                        self.DashBoardMenu.title = "Used:[\(counter)] Bytes"
                }
        }
        
        
}
