//
//  MinerSelectCtrl.swift
//  Pirate
//
//  Created by hyperorchid on 2019/11/14.
//  Copyright © 2019 hyperorchid. All rights reserved.
//

import Cocoa
import DecentralizedShadowSocks

class MinerSelectCtrl: NSWindowController {
        public var CurrntPoolAddress:String = ""
        private var minerData:[MinerData] = []
        private var minerTestData:[String:MinerTestData] = [:]
        
        @IBOutlet weak var MinerListTV: NSTableView!
        
        @IBOutlet weak var MineStatus: NSTextField!
        @IBOutlet weak var waitingTips: NSProgressIndicator!
        @IBOutlet weak var MinerAddress: NSTextField!
        @IBOutlet weak var Zone: NSTextField!
        @IBOutlet weak var IPAddress: NSTextField!
        @IBOutlet weak var PingValue: NSTextField!
        
        override func windowDidLoad() {
                super.windowDidLoad()
                self.minerData = MinerData.LoadMiners(PoolAddr: self.CurrntPoolAddress)
                self.MinerListTV.reloadData()
        }
        
        @IBAction func TestPingValue(_ sender: Any) {
                guard MinerAddress.stringValue != "" else{
                        return
                }
                
                let mid = self.MinerAddress.stringValue.toGoString()
                Service.sharedInstance.contractQueue.async {
                        let ret = testPings(mid)
                        DispatchQueue.main.async {
                                self.waitingTips.isHidden = true
                                
                                guard let ipData = ret.r0 else {
                                        self.IPAddress.stringValue = "none"
                                        self.PingValue.stringValue = "none"
                                        return
                                }
                        
                                self.IPAddress.stringValue = String(cString: ipData)
                                self.PingValue.stringValue = String(format:"%.2f ms", Double(ret.r1))
                                let td = MinerTestData(ip: self.IPAddress.stringValue, ping: Double(ret.r1))
                                self.minerTestData[self.MinerAddress.stringValue] = td
                                self.MinerListTV.reloadData()
                        }
                }
        }
        
        @IBAction func ExitAct(_ sender: Any) {
                self.close()
        }
        
        @IBAction func ChangeMinersAct(_ sender: Any) {
                self.waitingTips.isHidden = false
                Service.sharedInstance.contractQueue.async {
                        self.minerData = MinerData.SyncMiners(PoolAddr: self.CurrntPoolAddress)
                }
                DispatchQueue.main.async {
                        self.waitingTips.isHidden = true
                        self.MinerListTV.reloadData()
                }
        }
        
        @IBAction func PingAllMiners(_ sender: Any) {
                
                self.waitingTips.isHidden = false
                
                for (_, md) in minerData.enumerated(){
                        Service.sharedInstance.contractQueue.async {
                                let ret = testPings(md.SubAddr.toGoString())
                                if ret.r0 == nil {
                                        self.minerTestData[md.SubAddr] = MinerTestData(ip: "none", ping:-1)
                                }else{
                                        self.minerTestData[md.SubAddr] = MinerTestData(ip: String(cString: ret.r0!), ping: Double(ret.r1))
                                }
                                
                                if self.minerData.count != self.minerTestData.count{
                                        return
                                }
                                
                                DispatchQueue.main.async {
                                        self.waitingTips.isHidden = true
                                        self.MinerListTV.reloadData()
                                }
                        }
                }
        }
        
        @IBAction func SetAsServiceMiner(_ sender: Any) {
                guard MinerAddress.stringValue != "" else {
                        return
                }
                
                do {
                        try Service.sharedInstance.srvConf.SetCurMiner(addr: MinerAddress.stringValue, forPool: self.CurrntPoolAddress)
                } catch let err {
                        dialogOK(question: "Set failed", text: err.localizedDescription)
                }
                
                self.MinerListTV.reloadData()
        }
        
}

extension MinerSelectCtrl:NSTableViewDelegate {
        
        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
                let miner = self.minerData[row]
                
                guard let idt = tableColumn?.identifier else{
                        return nil
                }
                
                guard let cell = tableView.makeView(withIdentifier: idt, owner: nil)  else{
                        return nil
                }
                
                if (idt.rawValue == "SubAddr"){
                        let SubAddrcCell = cell as! NSTableCellView
                        SubAddrcCell.textField?.stringValue = miner.SubAddr
                }else if (idt.rawValue == "PingValue"){
                        
                        let PingCell = cell as! NSTableCellView
                        
                        let testData = self.minerTestData[miner.SubAddr]
                        if testData == nil{
                                PingCell.textField?.intValue = 0
                        }else{
                                PingCell.textField?.stringValue = String(format:"%.2f ms", testData!.Ping)
                        }
                        
                }else {
                        let StatusCell = cell as! NSButton
                        if Service.sharedInstance.srvConf.CurMiner() == miner.SubAddr {
                                StatusCell.state = .on
                        }else{
                                StatusCell.state = .off
                        }
                }
                
                return cell
        }
        
        func tableViewSelectionDidChange(_ notification: Notification){
                
                let table = notification.object as! NSTableView
                let idx = table.selectedRow
                if idx < 0 || idx >= minerData.count{
                        return
                }
                
                let miner = self.minerData[idx]
                self.MinerAddress.stringValue = miner.SubAddr
                self.Zone.stringValue = miner.Zone
                if Service.sharedInstance.srvConf.CurMiner() == miner.SubAddr{
                        self.MineStatus.stringValue = "IN USED"
                }else{
                        self.MineStatus.stringValue = ""
                }
                
                guard  let testData = self.minerTestData[miner.SubAddr] else{
                        self.IPAddress.stringValue = "-"
                        self.PingValue.stringValue = "0"
                        return
                }
                
                self.IPAddress.stringValue = testData.IPAddr
                self.PingValue.stringValue = String(format:"%.2f ms", testData.Ping)
        }
}

extension MinerSelectCtrl:NSTableViewDataSource {
        
        func numberOfRows(in tableView: NSTableView) -> Int {
                return self.minerData.count
        } 
}
