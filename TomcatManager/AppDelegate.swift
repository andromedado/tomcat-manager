//
//  AppDelegate.swift
//  TomcatManager
//
//  Created by Shad Downey on 4/1/17.
//  Copyright © 2017 Shad Downey. All rights reserved.
//

import Cocoa

fileprivate let kUpdateInterval : TimeInterval = 1.0

enum MenuSections : Int {
    case tomcat
    case env
    case apps
    case preferences
    case quit
    
    static let all : [MenuSections] = {
        var all : [MenuSections] = []
        var i = 0
        while let one = MenuSections(rawValue: i) {
            all.append(one)
            i += 1
        }
        return all
    }()
}

enum MenuItemType : Int {
    case root
    case remove
    case cleanAndPackage
    case deploy
}

class AppDelegate: NSObject, NSApplicationDelegate {
    
    var statusItem : NSStatusItem!
    var tomcatManager : TomcatManager?
    var webAppManager : WebAppManager?
    var envManager : EnvManager!
    
    var preferences : Preferences!
    var preferencesWindow : PreferencesController?
    
    var tomcatMenuItem : NSMenuItem!
    var updater : NSBackgroundActivityScheduler?

    var webAppsPlaceholderItem : NSMenuItem?
    
    var tomcatUp : Bool = false {
        didSet {
            guard oldValue != self.tomcatUp else { return }
            self.statusItem.image = tomcatUp ? Images.Tomcat.color : Images.Tomcat.hollow
            updateMenu()
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application

        //Kill any previously running managers
        DistributedNotificationCenter.default().postNotificationName(Notifications.killManager, object: Strings.mainAppIdentifier, userInfo: nil, options: [])
        
        statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
        statusItem.image = #imageLiteral(resourceName: "hollowTomcat")
        
        self.preferences = Preferences()
        
        self.scheduleUpdate { [weak self] (completion) in
            defer {
                completion?()
            }
            guard let strongSelf = self else {
                return
            }
            strongSelf.update()
        }


        self.tomcatManager = TomcatManager()

        self.webAppManager = WebAppManager()
        self.webAppManager!.delegate = self

        self.envManager = EnvManager()

        let menu = NSMenu()
        
        MenuSections.all.forEach({(section) in
            switch section {
            case .tomcat:
                self.tomcatMenuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "s")
                self.updateTomcatItem()
                menu.addItem(self.tomcatMenuItem)
                menu.addItem(NSMenuItem.separator())
            case .env:
                menu.addItem(self.envManager.menuItem)
                menu.addItem(NSMenuItem.separator())
            case .apps:
                self.webAppsPlaceholderItem = NSMenuItem()
                menu.addItem(self.webAppsPlaceholderItem!)
            case .preferences:
                menu.addItem(NSMenuItem(title: "Preferences", action: #selector(AppDelegate.launchPreferences), keyEquivalent: "p"))
                menu.addItem(NSMenuItem.separator())
            case .quit:
                menu.addItem(NSMenuItem(title: "Quit Manager", action: #selector(AppDelegate.terminate), keyEquivalent: "q"))
            }
        })
        
        statusItem.menu = menu

        self.webAppManager!.scan()
        self.envManager.scan()
        update()
        
        if appIsRunning(bundleIdentifier: Strings.launcherAppIdentifier) {
            DistributedNotificationCenter.default().postNotificationName(Notifications.killLauncher, object: Strings.mainAppIdentifier, userInfo: nil, options: [])
        }
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(AppDelegate.terminate), name: Notifications.killManager, object: Strings.mainAppIdentifier)
        
        if Preferences.BooleanPreference.showAtLaunch.value {
            self.launchPreferences()
        }
    }

    func scheduleUpdate(_ block : @escaping (_ completion : (() -> Void)?) -> Void) {
//        let timer = Timer(timeInterval: 1.5, repeats: true) { (timer) in
//        }
//
        let timer = Timer.scheduledTimer(withTimeInterval: kUpdateInterval, repeats: true) { (timer) in
            block(nil)
        }

        timer.tolerance = kUpdateInterval / 5

//        let updater = NSBackgroundActivityScheduler(identifier: "com.shad.statusUpdater")
//        self.updater = updater
//        updater.repeats = true
//        updater.interval = 1.0
//        updater.tolerance = 0.5
//        updater.qualityOfService = QualityOfService.background
//        updater.schedule { (completion) in
//            block {
//                completion(.finished)
//            }
//        }

    }
    
    func update() {
        guard let manager = tomcatManager else { return }
        manager.isRunning {(isRunning) in
            self.tomcatUp = isRunning
        }
        self.webAppManager?.update()
    }
    
    func updateMenu() {
        self.updateTomcatItem()
        self.webAppManager?.updateAppItems()
    }
    
    func updateTomcatItem() {
        onMain {
            if self.tomcatUp {
                self.tomcatMenuItem.title = "Stop Tomcat"
                self.tomcatMenuItem.action = #selector(AppDelegate.stopTomcat)
            } else {
                self.tomcatMenuItem.title = "Start Tomcat"
                self.tomcatMenuItem.action = #selector(AppDelegate.startTomcat)
            }
        }
    }
    
    func startTomcat() {
        self.tomcatManager?.startup()
    }
    
    func stopTomcat() {
        self.tomcatManager?.shutdown()
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

extension AppDelegate : WebAppManagerDelegate {
    func tomcatIsUp() -> Bool {
        return self.tomcatUp
    }

    func finishedScanningFor(webApps : [WebApp : [MenuItemType : NSMenuItem]]) {
        if webApps.count > 0 {
            onMain {
                var idx : Int = self.statusItem.menu!.index(of: self.webAppsPlaceholderItem!)
                webApps.values.forEach({ (items) in
                    self.statusItem.menu!.insertItem(items[.root]!, at: idx)
                    idx += 1
                })
                idx = self.statusItem.menu!.index(of: self.webAppsPlaceholderItem!)
                self.statusItem.menu!.removeItem(at:idx)
                self.statusItem.menu!.insertItem(NSMenuItem.separator(), at: idx)
                self.webAppsPlaceholderItem = nil
            }
        }

    }
}

