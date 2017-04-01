//
//  PreferencesController.swift
//  TomcatManager
//
//  Created by Shad Downey on 4/1/17.
//  Copyright © 2017 Shad Downey. All rights reserved.
//

import Cocoa

class PreferencesController: NSWindowController {
    
    @IBOutlet weak var launchAtLoginConfig: NSButton!
    @IBOutlet weak var showAtLaunchConfig: NSButton!
    
    var preferences : Preferences!
    
    static func build(withPref prefs: Preferences) -> PreferencesController {
        let vc = PreferencesController(windowNibName: "PreferencesController")
        vc.preferences = prefs
        return vc
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()

        self.window?.title = ""
        self.launchAtLoginConfig.state = Preferences.BooleanPreference.launchOnLogin.value ? NSOnState : NSOffState
        self.showAtLaunchConfig.state = Preferences.BooleanPreference.showAtLaunch.value ? NSOnState : NSOffState
    }
    
    @IBAction func action(_ sender: Any) {
        guard let button = sender as? NSButton else { return }
        switch button {
        case self.launchAtLoginConfig:
            Preferences.BooleanPreference.launchOnLogin.setValue(button.state == NSOnState)
        case self.showAtLaunchConfig:
            Preferences.BooleanPreference.showAtLaunch.setValue(button.state == NSOnState)
        default:
            ()
        }
    }
    
}
