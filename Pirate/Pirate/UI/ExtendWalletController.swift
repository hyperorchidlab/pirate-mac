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
        
        let symboID = NSUserInterfaceItemIdentifier(rawValue: "ExtendTokenSymbol")
        let balanceID = NSUserInterfaceItemIdentifier(rawValue: "ExtendTokenBalance")
        
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
                        ExtendToken.loadTokens()
                }
                DispatchQueue.main.async {
                        self.waitTips.isHidden = true
                        self.TokensTableView.reloadData()
                }
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
                
                if tableColumn == tableView.tableColumns[0]{
                        guard let cell = tableView.makeView(withIdentifier: symboID, owner: nil) as? NSTableCellView else{
                                return nil
                        }
                        cell.textField?.stringValue =  tokenInfo.Symbol
                        return cell
                }else {
                        guard let cell = tableView.makeView(withIdentifier: balanceID, owner: nil) as? NSTableCellView else{
                                return nil
                        }
                        cell.textField?.stringValue =  "\(tokenInfo.Balance.CoinValue())"
                        return cell
                }
        }
}
