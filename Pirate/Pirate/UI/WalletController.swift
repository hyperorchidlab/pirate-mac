//
//  WalletController.swift
//  Pirate
//
//  Created by Pirate on 2019/8/27.
//  Copyright © 2019年 Pirate All rights reserved.
//

import Cocoa
import DecentralizedShadowSocks

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
        @IBOutlet weak var InRechargeTF: NSTextField!
        
        override func windowDidLoad() {
                super.windowDidLoad()
                
                NotificationCenter.default.addObserver(self, selector:#selector(UserDataChanged(notification:)),
                                                       name: UserDataSyncSuccess, object: nil)
                
                NotificationCenter.default.addObserver(self, selector:#selector(WalletBalanceUpdate(notification:)),
                                                      name: WalletBalanceChanged, object: nil)
                updateWallet()
        }
        
        deinit {
                NotificationCenter.default.removeObserver(self)
        }
        
        func updateWallet(){
                let symbol = Service.sharedInstance.srvConf.CurToken!.Symbol
                let w = Wallet.CurrentWallet
                MainAddressField.stringValue = w.MainAddress
                SubAddressField.stringValue = w.SubAddress
                EthBalanceField.stringValue = String(format: "%.4f ETH", Wallet.CurrentWallet.EthBalance.CoinValue())
                TokenBalanceField.stringValue = String(format: "%.4f \(symbol)", Wallet.CurrentWallet.TokenBalance.CoinValue())
        }
        
        @objc func WalletBalanceUpdate(notification: Notification){
                DispatchQueue.main.async {
                        self.WaitingTip.isHidden = true
                        self.updateWallet()
                }
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
                var isReplaced = false
                if !Wallet.CurrentWallet.IsEmpty(){
                        let ok = dialogOKCancel(question: "Replace This Wallet?", text: "Current wallet will be replaced by new created one!")
                        if !ok{
                                return
                        }
                        isReplaced = true
                }
                
                let (pwd1, pwd2, ok) = show2PasswordDialog()
                if !ok{
                        return
                }
                
                if pwd1 != pwd2{
                        dialogOK(question: "Error", text: "The 2 Passwords are different")
                        return
                }
                
                let success = Wallet.CurrentWallet.CreateNewWallet(passPhrase: pwd1, replaceOld:isReplaced)
                if success{
                        updateWallet()
                }
        }
        
        @IBAction func ImportWalletAction(_ sender: Any) {
                var isReplaced = false
                if !Wallet.CurrentWallet.IsEmpty(){
                        let ok = dialogOKCancel(question: "Replace This Wallet?", text: "Current wallet will be replaced by imported one!")
                        if !ok{
                                return
                        }
                        isReplaced = true
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
                                try Wallet.CurrentWallet.ImportWallet(path:openPanel.url!.path , password: password, replaceOld: isReplaced)
                                dialogOK(question: "Success", text: "Import wallet success!")
                                self.updateWallet()
                                
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
                                self.updateWallet()
                        }
                }
        }
        
        @IBAction func ReloadMinerPoolActin(_ sender: Any) {
                Wallet.CurrentWallet.load()
        }
        
        @IBAction func TransferAction(_ sender: Any) {
                let (password, target, no, typ) = ShowTransferDialog()
                if typ < 0{
                        return
                }
                
                WaitingTip.isHidden = false
                Service.sharedInstance.contractQueue.async {
                        var tx = "", err = ""
                        if typ == 0{
                                let ret = TransferEth(password.toGoString(), target.toGoString(), no)
                                if ret.r0 == nil{
                                        err = String(cString: ret.r1)
                                }else{
                                        tx = String(cString: ret.r0)
                                }
                        } else{
                                let ret = TransferToken(password.toGoString(), target.toGoString(), no)
                                if ret.r0 == nil{
                                        err = String(cString: ret.r1)
                                }else{
                                        tx = String(cString: ret.r0)
                                }
                        }
                        DispatchQueue.main.async {
                                self.WaitingTip.isHidden = true
                                if tx != ""{
                                        if let url = URL(string: "\(BaseEtherScanUrl)/tx/\(tx)") {
                                                NSWorkspace.shared.open(url)
                                                return
                                        }
                                        
                                        dialogOK(question: "Tips", text: err)
                                }
                        }
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
                let symbol = Service.sharedInstance.srvConf.CurToken!.Symbol
                self.NonceTF.intValue = Int32(userData.Nonce)
                self.TokenTF.stringValue = "\(userData.TokenInUsed.CoinValue()) \(symbol)"
                self.PacketsTF.stringValue = ConvertBandWith(val: userData.PacketBalance)
                self.RefundTimeTF.stringValue = userData.RefundTime
                self.EpochTF.intValue = Int32(userData.Epoch)
                self.MicroNonceTF.intValue = Int32(userData.MicrNonce)
                self.CreditTF.stringValue = ConvertBandWith(val: userData.Credit)
                self.InRechargeTF.stringValue = ConvertBandWith(val: userData.InCharge)
        }
}

extension WalletController:NSTableViewDataSource{
        func numberOfRows(in tableView: NSTableView) -> Int {
                return Wallet.PoolsOfUser.count
        }
}
