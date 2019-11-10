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
        @IBOutlet weak var GNTField: NSTextField!
        
        
        
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
                
                NotificationCenter.default.addObserver(self, selector:#selector(buyPacketResult(notification:)),
                                                       name: BuyPacketResultNoti, object: nil)
                
                self.RefundTime.doubleValue = Wallet.sharedInstance.HasApproved.CoinValue()
                self.BuyForAddrField.stringValue = Wallet.sharedInstance.MainAddress
                WaitingTip.isHidden = false
                self.loadPoolsData()
        }
        
        deinit {
                NotificationCenter.default.removeObserver(self)
        }
        
        @objc func updatePoolList(notification: Notification){
                DispatchQueue.main.async {
                        self.WaitingTip.isHidden = true
                        self.poolTableView.reloadData()
                }
        }
        
        @objc func buyPacketResult(notification: Notification){
                DispatchQueue.main.async {
                        self.WaitingTip.isHidden = true
                }
                ShowTransResult(notification:notification)
                MPCManager.loadMyPoolsFromBlockChain()
        }
        
        @IBAction func Exit(_ sender: Any) {
                self.close()
        }
        
        func loadPoolsData(){
                service.contractQueue.async {
                        MinerPool.PoolInfoInMarket()
                        DispatchQueue.main.async {
                                self.WaitingTip.isHidden = true
                                self.poolTableView.reloadData()
                        }
                }
        }
        
        func updatePoolDetails(){
                guard let details = self.currentPool else {
                        return
                }
                
                self.poolAddressField.stringValue = details.MainAddr
                self.GNTField.doubleValue = details.GuaranteedNo.CoinValue()
                guard let chan = MPCManager.PayChannels[details.MainAddr] else {
                        self.poolEmail.stringValue = "Unsubscribed"
                        return
                }
                self.poolEmail.stringValue = "Subscribed"
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

                if Wallet.sharedInstance.TokenBalance.doubleValue < tokenToSpend{
                        dialogOK(question: "Tips", text: "No enough token in your wallet!")
                        return
                }

                if Wallet.sharedInstance.EthBalance.doubleValue <= 0.001{
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
        
        fileprivate enum CellIdentifiers {
                static let AddressCell = "AddressCellID"
                static let CoinPledgedCell = "CoinPledgedCellID"
                static let NameCell = "ShortNameCellID"
        }
        
        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
                let poolInfo = MinerPool.objAt(idx: row)
                
                guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ShortNameCellID"), owner: nil) as? NSTableCellView else{
                        return nil
                }
                
                cell.textField?.stringValue = poolInfo.ShortName
                return cell
        }
        
        func tableViewSelectionDidChange(_ notification: Notification){
                let table = notification.object as! NSTableView
                let idx = table.selectedRow
                if idx < 0 || idx >= MinerPool.cachedPools.count{
                        return
                }
                
                let poolInfo = MinerPool.objAt(idx: idx)
                self.currentPool = poolInfo
                updatePoolDetails()
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
