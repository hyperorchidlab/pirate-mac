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
        
        @IBOutlet weak var PacketCanGet: NSTextField!
        @IBOutlet weak var TokenToSpend: NSTextField!
        @IBOutlet weak var BuyForAddrField: NSTextField!
        @IBOutlet weak var EthBalance: NSTextField!
        @IBOutlet weak var LinBalance: NSTextField!
        @IBOutlet weak var WaitingTip: NSProgressIndicator!
        @IBOutlet weak var poolTableView: NSTableView!
        @IBOutlet weak var avgPriceField: NSTextField!
        @IBOutlet weak var myStatusField: NSTextField!
        @IBOutlet weak var myBalanceField: NSTextField!
        @IBOutlet weak var PoolAddressField: NSTextField!
        @IBOutlet weak var poolDescField: NSScrollView!
        @IBOutlet weak var mortagedField: NSTextField!
        @IBOutlet weak var approvedField: NSTextField!
        @IBOutlet weak var unclaimed: NSTextField!
        
        var currentPool:MinerPool? = nil
        let service = Service.sharedInstance
        
        override func windowDidLoad() {
                super.windowDidLoad()
                
                NotificationCenter.default.addObserver(self, selector:#selector(updatePoolList(notification:)),
                                                       name: PoolsInMarketChanged, object: nil)
                
                NotificationCenter.default.addObserver(self, selector:#selector(buyPacketResult(notification:)),
                                                       name: BuyPacketResultNoti, object: nil)
                
                
                self.LinBalance.doubleValue = Wallet.sharedInstance.TokenBalance.CoinValue()
                self.EthBalance.doubleValue = Wallet.sharedInstance.EthBalance.CoinValue()
                self.avgPriceField.doubleValue = Double(Service.sharedInstance.srvConf.packetPrice)
                self.approvedField.doubleValue = Wallet.sharedInstance.HasApproved.CoinValue()
                self.BuyForAddrField.stringValue = Wallet.sharedInstance.MainAddress
                WaitingTip.isHidden = false
                self.loadPoolsData()
                MinerPool.asyncFreshMarketData()
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
                
                let view = self.poolDescField.documentView as! NSTextView
                view.string = details.DetailInfos
                self.PoolAddressField.stringValue = details.MainAddr
                self.mortagedField.doubleValue = details.GuaranteedNo.CoinValue()
                guard let chan = MPCManager.PayChannels[details.MainAddr] else {
                        self.myStatusField.stringValue = "Unsubscribed"
                        return
                }
                self.myStatusField.stringValue = "Subscribed"
                self.myBalanceField.stringValue = ConvertBandWith(val: chan.RemindPackets)
        }
        
        @IBAction func SycFromEthereumAction(_ sender: NSButton) {
                MinerPool.asyncFreshMarketData()
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
