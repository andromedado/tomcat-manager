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
    
    var preferencesWindow : Preferences?
    
    var tomcatUp : Bool = false {
        didSet {
            guard oldValue != self.tomcatUp else { return }
            self.statusItem.image = tomcatUp ? Images.Tomcat.color : Images.Tomcat.hollow
            rebuildMenu()
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
        
        statusItem.image = #imageLiteral(resourceName: "hollowTomcat")
        
        rebuildMenu()
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] (timer) in
            guard let strongSelf = self else {
                timer.invalidate()
                return
            }
            strongSelf.update()
        }
        
        setupManager()
        update()
    }
    
    func setupManager() {
        let res = runCommandAsUser(command: "echo $CATALINA_HOME")
        
        guard res.output.count == 1 else {
            //TODO Announce Problem
            return
        }
        
        let catalinaHome = res.output[0]
        self.manager = TomcatManager(catalinaHome: catalinaHome)
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
        menu.addItem(NSMenuItem(title: "Quit Manager", action: #selector(AppDelegate.quit), keyEquivalent: "q"))
        
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
            preferencesWindow = Preferences(windowNibName: "Preferences")
        }
        
        preferencesWindow?.showWindow(nil)
        preferencesWindow?.window?.makeMain()
    }
    
    func quit() {
        NSApplication.shared().terminate(nil)
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

