//
//  MinerPoolController.swift
//  Pirate
//
//  Created by Pirate on 2019/8/29.
//  Copyright © 2019年 Pirate All rights reserved.
//

import Cocoa
import DecentralizedShadowSocks

class PacketMarketController: NSWindowController {
        @IBOutlet weak var WaitingTip: NSProgressIndicator!
        @IBOutlet weak var poolTableView: NSTableView!
        
        @IBOutlet weak var poolEmail: NSTextField!
        @IBOutlet weak var poolUrl: NSTextField!
        @IBOutlet weak var poolAddressField: NSTextField!
        @IBOutlet weak var poolGNTField: NSTextField!
                
        
        @IBOutlet weak var PacketCanGet: NSTextField!
        @IBOutlet weak var TokenToSpend: NSTextField!
        @IBOutlet weak var BuyForAddrField: NSTextField!
        
        @IBOutlet weak var PacketBalance: NSTextField!
        @IBOutlet weak var TokenDeposit: NSTextField!
        @IBOutlet weak var Nonce: NSTextField!
        @IBOutlet weak var RefundTime: NSTextField!
        
        var currentPool:MinerPool? = nil
        let service = Service.sharedInstance
        
        override func windowDidLoad() {
                super.windowDidLoad()
                
                NotificationCenter.default.addObserver(self, selector:#selector(updatePoolList(notification:)),
                                                       name: PoolsInMarketChanged, object: nil)
                
                NotificationCenter.default.addObserver(self, selector:#selector(UserDataChanged(notification:)),
                                                       name: UserDataSyncSuccess, object: nil)
             
                self.BuyForAddrField.stringValue = Wallet.CurrentWallet.MainAddress
                MinerPool.PoolInfoInMarket()
                self.poolTableView.reloadData()
        }
        
        deinit {
                NotificationCenter.default.removeObserver(self)
        }
        
        @objc func updatePoolList(notification: Notification){
                self.WaitingTip.isHidden = false
                MinerPool.PoolInfoInMarket()
                
                DispatchQueue.main.async {
                        self.WaitingTip.isHidden = true
                        self.poolTableView.reloadData()
                }
        }
        
        @objc func UserDataChanged(notification: Notification){
               
        }
        
        @IBAction func Exit(_ sender: Any) {
                self.close()
        }
        
        
        @IBAction func BuyPacketAction(_ sender: NSButton) {
                guard let details = self.currentPool else {
                        dialogOK(question: "Tips:",text: "Please select one pool first")
                        return
                }

                let tokenToSpend = self.TokenToSpend.doubleValue
                if tokenToSpend <= 0.01{
                        dialogOK(question: "Tips", text: "Too less token to spend!")
                        return
                }

                if Wallet.CurrentWallet.TokenBalance.doubleValue < tokenToSpend{
                        dialogOK(question: "Tips", text: "No enough token in your wallet!")
                        return
                }

                if Wallet.CurrentWallet.EthBalance.doubleValue <= 0.001{
                        dialogOK(question: "Tips", text: "No enough ETH for operation gas!")
                        return
                }

                let password = showPasswordDialog()
                if password == ""{
                        return
                }
                ShowShopingDialog(buyFrom: details.MainAddr,
                                  For: self.BuyForAddrField.stringValue,
                                  auth: password, tokenNo: tokenToSpend)
        }
}

extension PacketMarketController:NSTableViewDelegate {
        
        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
                let poolInfo = MinerPool.objAt(idx: row)
                
                guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ShortNameCellID"), owner: nil) as? NSTableCellView else{
                        return nil
                }
                
                cell.textField?.stringValue = poolInfo.Name
                return cell
        }
        
        func tableViewSelectionDidChange(_ notification: Notification){
                let table = notification.object as! NSTableView
                let idx = table.selectedRow
                if idx < 0 || idx >= MinerPool.cachedPools.count{
                        return
                }
                
                let pool = MinerPool.objAt(idx: idx)
                self.currentPool = pool
               
                self.poolAddressField.stringValue = pool.MainAddr
                self.poolGNTField.stringValue = "\(pool.GuaranteedNo.CoinValue()) HOP"
                self.poolEmail.stringValue = pool.Email
                self.poolUrl.stringValue = pool.Url
                
                guard let userData = UserData.LoadUserDataUnder(pool:pool.MainAddr)else{
                        self.PacketBalance.stringValue = "0 MBytes"
                        self.TokenDeposit.stringValue = "0 HOP"
                        self.Nonce.intValue = -1
                        self.RefundTime.stringValue = "-"
                        return
                }
                
                self.PacketBalance.stringValue = ConvertBandWith(val: userData.PacketBalance)
                self.TokenDeposit.stringValue = "\(userData.TokenInUsed.CoinValue()) HOP"
                self.Nonce.intValue = Int32(userData.Nonce)
                self.RefundTime.stringValue = userData.RefundTime
        }
}

extension PacketMarketController:NSTableViewDataSource { 
        func numberOfRows(in tableView: NSTableView) -> Int {
                return MinerPool.cachedPools.count
        }
}

extension PacketMarketController:NSTextFieldDelegate{
        
        func controlTextDidChange(_ notification: Notification){
                guard let field = notification.object as? NSTextField else {
                        Swift.print(notification.object as Any)
                        return
                }
                Swift.print(field.doubleValue)
                let tokenNo = field.doubleValue
                let bytesSum = tokenNo * Double(Service.sharedInstance.srvConf.packetPrice)
                self.PacketCanGet.stringValue = ConvertBandWith(val: bytesSum)
        }
}
