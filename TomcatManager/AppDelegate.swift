//
//  AppDelegate.swift
//  TomcatManager
//
//  Created by Shad Downey on 4/1/17.
//  Copyright © 2017 Shad Downey. All rights reserved.
//

import Cocoa


class AppDelegate: NSObject, NSApplicationDelegate {
    
    var statusItem : NSStatusItem!
    var manager : TomcatManager?
    
    var preferences : Preferences!
    var preferencesWindow : PreferencesController?
    
    var tomcatUp : Bool = false {
        didSet {
            guard oldValue != self.tomcatUp else { return }
            self.statusItem.image = tomcatUp ? Images.Tomcat.color : Images.Tomcat.hollow
            rebuildMenu()
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application

        //Kill any previously running managers
        DistributedNotificationCenter.default().postNotificationName(Notifications.killManager, object: Strings.mainAppIdentifier, userInfo: nil, options: [])
        
        statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
        statusItem.image = #imageLiteral(resourceName: "hollowTomcat")
        
        self.preferences = Preferences()
        
        rebuildMenu()
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] (timer) in
            guard let strongSelf = self else {
                timer.invalidate()
                return
            }
            strongSelf.update()
        }
        
        self.manager = TomcatManager()
        
        update()
        
        if appIsRunning(bundleIdentifier: Strings.launcherAppIdentifier) {
            DistributedNotificationCenter.default().postNotificationName(Notifications.killLauncher, object: Strings.mainAppIdentifier, userInfo: nil, options: [])
        }
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(AppDelegate.terminate), name: Notifications.killManager, object: Strings.mainAppIdentifier)
        
        if Preferences.BooleanPreference.showAtLaunch.value {
            self.launchPreferences()
        }
    }
    
    func update() {
        guard let manager = manager else { return }
        tomcatUp = manager.isRunning()
    }
    
    func rebuildMenu() {
        let menu = NSMenu()
        
        if self.tomcatUp {
            menu.addItem(NSMenuItem(title: "Stop Tomcat", action: #selector(AppDelegate.stopTomcat), keyEquivalent: "s"))
        } else {
            menu.addItem(NSMenuItem(title: "Start Tomcat", action: #selector(AppDelegate.startTomcat), keyEquivalent: "t"))
        }
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Preferences", action: #selector(AppDelegate.launchPreferences), keyEquivalent: "p"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Manager", action: #selector(AppDelegate.terminate), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    func startTomcat() {
        self.manager?.startup()
    }
    
    func stopTomcat() {
        self.manager?.shutdown()
    }
    
    func launchPreferences() {
        if preferencesWindow == nil {
            preferencesWindow = PreferencesController.build(withPref: preferences)
        }
        
        preferencesWindow?.showWindow(nil)
        preferencesWindow?.window?.makeMain()
    }
    
    func terminate() -> Never {
        NSApp.terminate(nil)
        exit(0)
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

