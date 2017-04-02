//
//  PreferencesController.swift
//  TomcatManager
//
//  Created by Shad Downey on 4/1/17.
//  Copyright © 2017 Shad Downey. All rights reserved.
//

import Cocoa

fileprivate typealias DataType = (name : String, path : String)

class PreferencesController: NSWindowController {
    
    @IBOutlet weak var launchAtLoginConfig: NSButton!
    @IBOutlet weak var showAtLaunchConfig: NSButton!
    @IBOutlet weak var catalinaHome: NSTextField!
    @IBOutlet weak var bgButton: NSButton!
    @IBOutlet weak var checkmarkView: NSImageView!
    @IBOutlet weak var tableView: NSTableView!
    
    var preferences : Preferences!
    
    fileprivate var data : [DataType] = [
        ("test", "TEST"),
        ("", ""),
        ("Ztest", "dTEST")
    ]
    
    static func build(withPref prefs: Preferences) -> PreferencesController {
        let vc = PreferencesController(windowNibName: "PreferencesController")
        vc.preferences = prefs
        return vc
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self

        self.window?.title = ""
        self.launchAtLoginConfig.state = Preferences.BooleanPreference.launchOnLogin.value ? NSOnState : NSOffState
        self.showAtLaunchConfig.state = Preferences.BooleanPreference.showAtLaunch.value ? NSOnState : NSOffState
        self.catalinaHome.stringValue = Preferences.StringPreference.catalinaHome.value
        
        self.updateCatalinaHomeValidity()
    }
    
    func updateCatalinaHomeValidity() {
        let (stdout, stderr, _) = runCommandAsUser(command: "stat \"\(catalinaHome.stringValue)/bin/startup.sh\"")
        let good = stdout.count > 0 && stderr.count == 0
        self.checkmarkView.isHidden = !good
    }
    
    @IBAction func action(_ sender: Any) {
        guard let control = sender as? NSControl else { return }
        switch control {
        case self.bgButton:
            NSApplication.shared().mainWindow?.makeFirstResponder(nil)
        case self.catalinaHome:
            Preferences.StringPreference.catalinaHome.setValue(catalinaHome.stringValue)
        case self.launchAtLoginConfig:
            Preferences.BooleanPreference.launchOnLogin.setValue(self.launchAtLoginConfig.state == NSOnState)
        case self.showAtLaunchConfig:
            Preferences.BooleanPreference.showAtLaunch.setValue(self.showAtLaunchConfig.state == NSOnState)
        default:
            ()
        }
    }
    
}

extension PreferencesController : NSTextFieldDelegate {

    override func controlTextDidChange(_ obj: Notification) {
        self.updateCatalinaHomeValidity()
    }
    
}

extension PreferencesController : NSTableViewDataSource {
    
    @objc
    func numberOfRows(in tableView: NSTableView) -> Int {
        return data.count
    }
    
//    @objc
//    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
//        return "FOOOO"
//    }
//    
//    @objc
//    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
//        let cell = tableColumn?.dataCell(forRow: row) as? NSCell
//        cell?.stringValue = "BAR"
//    }
    
}

fileprivate enum Column : Int {
    case name
    case path
    
    var identifier : String {
        switch self {
        case .name:
            return "name"
        case .path:
            return "path"
        }
    }
    
    func extractStringFrom(_ data : DataType) -> String {
        switch self {
        case .name:
            return data.name
        case .path:
            return data.path
        }
    }
}

extension PreferencesController : NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let column = tableColumn,
            let columnIdx = tableView.tableColumns.index(of: column),
            row <= self.data.count else { return nil }
        
        let col = Column(rawValue: columnIdx)!
        let data = self.data[row]
        
        if let cell = tableView.make(withIdentifier: col.identifier, owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = col.extractStringFrom(data)
            cell.textField?.isEditable = true
            return cell
        }
        return nil
        
    }
    
}


