//
//  MenuController.swift
//  Pirate
//
//  Created by hyperorchid on 2019/9/29.
//  Copyright © 2019年 hyperorchid. All rights reserved.
//

import Cocoa

class MenuController: NSObject {
        @IBOutlet weak var statusMenu: NSMenu!
        
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        override func awakeFromNib() {
                let icon = NSImage(named: "statusIcon")
                icon?.isTemplate = true
                statusItem.image = icon
                statusItem.menu = statusMenu
        }
        
        @IBAction func quitClicked(sender: NSMenuItem) {
                NSApplication.shared.terminate(self)
        }
}
