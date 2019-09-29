//
//  WalletController.swift
//  Pangolin
//
//  Created by Bencong Ri on 2019/8/27.
//  Copyright © 2019年 pangolink.org All rights reserved.
//

import Cocoa

class WalletController: NSWindowController {
        
        let KEY_FOR_WALLET_FILE = "wallet.json"
        @IBOutlet weak var MainAddressField: NSTextField!
        @IBOutlet weak var SubAddressField: NSTextField!
        @IBOutlet weak var EthBalanceField: NSTextField!
        @IBOutlet weak var TokenBalanceField: NSTextField!
        
        @IBOutlet weak var WaitingTip: NSProgressIndicator!
        
        @IBOutlet weak var RefundTimeField: NSTextField!
        @IBOutlet weak var DataBalanceField: NSTextField!
        @IBOutlet weak var DataAvgPriceField: NSTextField!
        @IBOutlet weak var MinerDescField: NSTextField!
        @IBOutlet weak var PoolTableView: NSTableView!
        
        
        var channelInUsed:MicroPayChannel? = nil
        
        override func windowDidLoad() {
                super.windowDidLoad()
                
                NotificationCenter.default.addObserver(self, selector:#selector(updateBalance(notification:)),
                                                       name: WalletDataChangedNoti, object: nil)
                NotificationCenter.default.addObserver(self, selector:#selector(processTransaction(notification:)),
                                                       name: TokenTransferResultNoti, object: nil)
                NotificationCenter.default.addObserver(self, selector:#selector(freshPoolList(notification:)),
                                                       name: PayChannelChangedNoti, object: nil)
                updateWallet() 
                MPCManager.loadMyChannels()
        }
        
        deinit {
                NotificationCenter.default.removeObserver(self)
        }
        
        func updateWallet(){
                let w = Wallet.sharedInstance
                
                MainAddressField.stringValue = "0x" + w.MainAddress
                SubAddressField.stringValue = w.SubAddress
                EthBalanceField.doubleValue = w.EthBalance.CoinValue()
                TokenBalanceField.doubleValue = w.TokenBalance.CoinValue()
        }
        
        @objc func updateBalance(notification: Notification){
                DispatchQueue.main.async {
                        self.WaitingTip.isHidden = true
                        self.updateWallet()
                }
        }
        
        @IBAction func Exit(_ sender: Any) {
                self.close()
        }
        
        @IBAction func CreateWalletAction(_ sender: Any) {
                if !Wallet.sharedInstance.IsEmpty(){
                        let ok = dialogOKCancel(question: "Replace This Wallet?", text: "Current wallet will be replaced by new created one!")
                        if !ok{
                                return
                        }
                }
                
                let (pwd1, pwd2, ok) = show2PasswordDialog()
                if !ok{
                        return
                }
                
                if pwd1 != pwd2{
                        dialogOK(question: "Error", text: "The 2 Passwords are different")
                        return
                }
                
                let success = Wallet.sharedInstance.CreateNewWallet(passPhrase: pwd1)
                if success{
                        updateWallet()
                }
        }
        
        @IBAction func ImportWalletAction(_ sender: Any) {
                if !Wallet.sharedInstance.IsEmpty(){
                        let ok = dialogOKCancel(question: "Replace This Wallet?", text: "Current wallet will be replaced by imported one!")
                        if !ok{
                                return
                        }
                }
                
                let openPanel = NSOpenPanel()
                openPanel.allowsMultipleSelection = false
                openPanel.canChooseDirectories = false
                openPanel.canCreateDirectories = false
                openPanel.canChooseFiles = true
                NSApp.activate(ignoringOtherApps: true)
                openPanel.allowedFileTypes=["text", "txt", "json"]
                openPanel.begin { (result) -> Void in
                        if result.rawValue != NSFileHandlingPanelOKButton {
                                return
                        }
                        
                        let password = showPasswordDialog()
                        if password == ""{
                                return
                        }
                        
                        do {
                                let jsonStr = try String.init(contentsOf: openPanel.url!)
                                try Wallet.sharedInstance.ImportWallet(json:jsonStr , password: password)
                                dialogOK(question: "Success", text: "Import wallet success!")
                                self.updateWallet()
                                
                        }catch{
                                dialogOK(question: "Warn", text:error.localizedDescription)
                                return
                        }
                }
        }
        
        @IBAction func ExportWalletAction(_ sender: Any) {
                
                if Wallet.sharedInstance.IsEmpty(){
                        dialogOK(question: "Tips", text: "No account to export")
                        return
                }
                let FS = NSSavePanel()
                FS.canCreateDirectories = true
                FS.allowedFileTypes = ["text", "txt", "json"]
                FS.canCreateDirectories = true
                FS.isExtensionHidden = false
                FS.nameFieldStringValue = KEY_FOR_WALLET_FILE
                NSApp.activate(ignoringOtherApps: true)
                FS.begin { result in
                        if result.rawValue != NSFileHandlingPanelOKButton {
                                return
                        }
                        do {
                                try Wallet.sharedInstance.ExportWallet(dst:FS.url)
                                dialogOK(question: "Success", text: "Export account success!")
                        }catch{
                                dialogOK(question: "Error", text: error.localizedDescription)
                                return
                        }
                }
        }
        
        @IBAction func SyncEthereumAction(_ sender: Any) {
                WaitingTip.isHidden = false
                Service.sharedInstance.contractQueue.async {
                        Wallet.sharedInstance.syncWalletData()
                        MPCManager.loadMyChannels()
                        DispatchQueue.main.async {
                                self.WaitingTip.isHidden = true
                                self.PoolTableView.reloadData()
                        }
                }
        }
        
        @IBAction func ReloadMinerPoolActin(_ sender: Any) {
        }
        @objc func processTransaction(notification: Notification){
                DispatchQueue.main.async {
                        self.WaitingTip.isHidden = true
                }
                ShowTransResult(notification:notification)
        }
        @objc func freshPoolList(notification: Notification){
                DispatchQueue.main.async {
                        self.WaitingTip.isHidden = true
                        self.PoolTableView.reloadData()
                }
        }
        
        @IBAction func TransferAction(_ sender: Any) {
                let (password, target, no, typ) = ShowTransferDialog()
                if typ < 0{
                        return
                }
                WaitingTip.isHidden = false
                if typ == 0{
                        Wallet.sharedInstance.EthTransfer(password: password, target: target, no: no)
                }else{
                        Wallet.sharedInstance.LinTokenTransfer(password: password, target: target, no: no)
                }
        }
}

extension WalletController:NSTableViewDelegate{
        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
                let chan = MPCManager.ObjAt(idx: row)
                
                guard let cell = tableView.makeView(withIdentifier:
                        NSUserInterfaceItemIdentifier(rawValue: "SubMinerPoolAddrID"), owner: nil) as? NSTableCellView else{
                        return nil
                }
                
                let pool = MinerPool.cachedPools[chan.MainAddr] 
                cell.textField?.stringValue =  (pool?.ShortName)!
                return cell
        }
        
        func tableViewSelectionDidChange(_ notification: Notification){
                let table = notification.object as! NSTableView
                let idx = table.selectedRow
                if idx < 0 || idx >= MPCManager.PayChannels.count{
                        return
                }
                
                self.channelInUsed = MPCManager.ObjAt(idx: idx)
                self.updatePoolDetails()
        }
        
        func updatePoolDetails(){
                guard let channel = self.channelInUsed else {
                        return
                }
                let pool = MinerPool.cachedPools[channel.MainAddr]
                self.MinerDescField.stringValue = pool!.DetailInfos
                self.DataBalanceField.stringValue = ConvertBandWith(val: channel.RemindPackets)
                let date = Date.init(timeIntervalSince1970: TimeInterval(channel.Expiration))
                self.RefundTimeField.stringValue = "\(date)"
        }
}

extension WalletController:NSTableViewDataSource{
        func numberOfRows(in tableView: NSTableView) -> Int {
                return MPCManager.PayChannels.count
        }
}

