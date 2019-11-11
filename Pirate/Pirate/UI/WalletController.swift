//
//  WalletController.swift
//  Pirate
//
//  Created by Pirate on 2019/8/27.
//  Copyright © 2019年 Pirate All rights reserved.
//

import Cocoa

class WalletController: NSWindowController {
        
        let KEY_FOR_WALLET_FILE = "wallet.json"
        
        @IBOutlet weak var MainAddressField: NSTextField!
        @IBOutlet weak var SubAddressField: NSTextField!
        @IBOutlet weak var EthBalanceField: NSTextField!
        @IBOutlet weak var TokenBalanceField: NSTextField!
        
        
        @IBOutlet weak var WaitingTip: NSProgressIndicator!
        @IBOutlet weak var PoolTableView: NSTableView!
        
        
        @IBOutlet weak var NonceTF: NSTextField!
        @IBOutlet weak var TokenTF: NSTextField!
        @IBOutlet weak var PacketsTF: NSTextField!
        @IBOutlet weak var RefundTimeTF: NSTextField!
        @IBOutlet weak var EpochTF: NSTextField!
        @IBOutlet weak var CreditTF: NSTextField!
        @IBOutlet weak var MicroNonceTF: NSTextField!
                
        override func windowDidLoad() {
                super.windowDidLoad()
                
                NotificationCenter.default.addObserver(self, selector:#selector(UserDataChanged(notification:)),
                                                       name: UserDataSyncSuccess, object: nil)
                updateWallet()
                self.PoolTableView.reloadData()
        }
        
        deinit {
                NotificationCenter.default.removeObserver(self)
        }
        
        func updateWallet(){
                let w = Wallet.CurrentWallet
                MainAddressField.stringValue = w.MainAddress
                SubAddressField.stringValue = w.SubAddress
                EthBalanceField.doubleValue = w.EthBalance.CoinValue()
                TokenBalanceField.doubleValue = w.TokenBalance.CoinValue()
        }
        
        @objc func UserDataChanged(notification: Notification){
                DispatchQueue.main.async {
                        self.WaitingTip.isHidden = true
                        self.PoolTableView.reloadData()
                }
        }
        
        @IBAction func Exit(_ sender: Any) {
                self.close()
        }
        
        @IBAction func CreateWalletAction(_ sender: Any) {
                if !Wallet.CurrentWallet.IsEmpty(){
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
                
                let success = Wallet.CurrentWallet.CreateNewWallet(passPhrase: pwd1)
                if success{
                        updateWallet()
                }
        }
        
        @IBAction func ImportWalletAction(_ sender: Any) {
                if !Wallet.CurrentWallet.IsEmpty(){
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
                                try Wallet.CurrentWallet.ImportWallet(path:openPanel.url!.path , password: password)
                                dialogOK(question: "Success", text: "Import wallet success!")
                                self.updateWallet()
                                self.PoolTableView.reloadData()
                                
                        }catch{
                                dialogOK(question: "Warn", text:error.localizedDescription)
                                return
                        }
                }
        }
        
        @IBAction func ExportWalletAction(_ sender: Any) {
                
                if Wallet.CurrentWallet.IsEmpty(){
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
                                try Wallet.CurrentWallet.ExportWallet(dst:FS.url)
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
                        Wallet.CurrentWallet.load()
                        DispatchQueue.main.async {
                                self.WaitingTip.isHidden = true
                                self.PoolTableView.reloadData()
                        }
                }
        }
        
        @IBAction func ReloadMinerPoolActin(_ sender: Any) {
                Wallet.CurrentWallet.load()
        }
        
        @objc func processTransaction(notification: Notification){
                DispatchQueue.main.async {
                        self.WaitingTip.isHidden = true
                }
                ShowTransResult(notification:notification)
        }
        
        @IBAction func TransferAction(_ sender: Any) {
                let (password, target, no, typ) = ShowTransferDialog()
                if typ < 0{
                        return
                }
                WaitingTip.isHidden = false
                if typ == 0{
                        Wallet.CurrentWallet.EthTransfer(password: password, target: target, no: no)
                }else{
                        Wallet.CurrentWallet.TokenTransfer(password: password, target: target, no: no)
                }
        }
}

extension WalletController:NSTableViewDelegate{
        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
                let pool = Wallet.PoolsOfUser[row]
                
                guard let cell = tableView.makeView(withIdentifier:
                        NSUserInterfaceItemIdentifier(rawValue: "SubMinerPoolAddrID"), owner: nil) as? NSTableCellView else{
                        return nil
                }
                cell.textField?.stringValue =  pool.Name
                return cell
        }
        
        func tableViewSelectionDidChange(_ notification: Notification){
                let table = notification.object as! NSTableView
                let idx = table.selectedRow
                if idx < 0 || idx >= Wallet.PoolsOfUser.count{
                        return
                }
                
                let pool = Wallet.PoolsOfUser[idx]
                guard let userData = UserData.LoadUserDataUnder(pool: pool.MainAddr) else{
                        return
                }
                
                self.TokenTF.stringValue = "\(userData.TokenInUsed.CoinValue()) HOP"
                self.PacketsTF.stringValue = ConvertBandWith(val: userData.PacketBalance)
                self.RefundTimeTF.stringValue = userData.RefundTime
                self.EpochTF.intValue = Int32(userData.Epoch)
                self.MicroNonceTF.intValue = Int32(userData.MicrNonce)
                self.CreditTF.stringValue = ConvertBandWith(val: userData.Credit)
        }
}

extension WalletController:NSTableViewDataSource{
        func numberOfRows(in tableView: NSTableView) -> Int {
                return Wallet.PoolsOfUser.count
        }
}

