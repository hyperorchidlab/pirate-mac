//
//  ExtendWalletController.swift
//  Pirate
//
//  Created by hyperorchid on 2020/1/4.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Cocoa

class ExtendWalletController: NSWindowController {
        @IBOutlet weak var TokensTableView: NSTableView!
        @IBOutlet weak var waitTips: NSProgressIndicator!
        
        let symbolID = NSUserInterfaceItemIdentifier(rawValue: "ExtendTokenSymbol")
        let balanceID = NSUserInterfaceItemIdentifier(rawValue: "ExtendTokenBalance")
        var CurTokenRadio:NSButton?
        override func windowDidLoad() {
                super.windowDidLoad()
                ExtendToken.loadTokens()
                TokensTableView.reloadData()
        }
        
        @IBAction func Close(_ sender: Any) {
                self.close()
        }
        
        @IBAction func reloadData(_ sender: Any) {
                waitTips.isHidden = false
                Service.sharedInstance.contractQueue.async {
                        ExtendToken.syncTokens()
                        DispatchQueue.main.async {
                                self.waitTips.isHidden = true
                                self.TokensTableView.reloadData()
                        }
                }
        }
        
        @IBAction func ChangeMainToken(_ sender: NSButton) {
                NSLog("curte tag[%d]", sender.tag)
                
                if self.CurTokenRadio?.tag == sender.tag{
                        return
                }
                
                self.CurTokenRadio?.state = .off
                sender.state = .on
                
                let ok = dialogOKCancel(question: "Warning", text: "Are you sure to change main token setting? This change will make application restart!")
                if !ok{
                        self.CurTokenRadio?.state = .on
                        sender.state = .off
                       return
                }
                
                let tokenInfo = ExtendToken.AllExTokens[sender.tag]
                Service.sharedInstance.srvConf.SetMainToken(token: tokenInfo.TokenI, contract: tokenInfo.PaymentContract)
                dialogOK(question: "Tips", text: "Change success, please restart the application")
                exit(0)
        }
}


extension ExtendWalletController:NSTableViewDataSource{
        func numberOfRows(in tableView: NSTableView) -> Int {
                return ExtendToken.AllExTokens.count
        }
}

extension ExtendWalletController:NSTableViewDelegate{
        
        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
                let tokenInfo = ExtendToken.AllExTokens[row]
                
                guard let idt = tableColumn?.identifier else{
                       return nil
                }

                guard let cell = tableView.makeView(withIdentifier: idt, owner: nil)  else{
                       return nil
                }
                
                if (idt == symbolID){
                        let symbolCell = cell as! NSTableCellView
                        symbolCell.textField?.stringValue =  tokenInfo.Symbol
                        return cell
                }else  if (idt == balanceID){
                        
                        let balanceCell = cell as! NSTableCellView
                        balanceCell.textField?.stringValue =  "\(tokenInfo.Balance.CoinValue())"
                        return cell
                }else{
                        let StatusCell = cell as! NSButton
                        let curToken = Service.sharedInstance.srvConf.CurToken
                        if curToken.caseInsensitiveCompare(tokenInfo.TokenI) ==  .orderedSame{
                                StatusCell.state = .on
                                self.CurTokenRadio = StatusCell
                        }else{
                                StatusCell.state = .off
                        }
                        StatusCell.tag = row
                        StatusCell.target = self
                        StatusCell.action = #selector(ChangeMainToken)
                }

                return cell
        }
}
