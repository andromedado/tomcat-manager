//
//  AppDelegate.swift
//  TomcatManager
//
//  Created by Shad Downey on 4/1/17.
//  Copyright © 2017 Shad Downey. All rights reserved.
//

import Cocoa

enum MenuSections : Int {
    case tomcat
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
}

class AppDelegate: NSObject, NSApplicationDelegate {
    
    var statusItem : NSStatusItem!
    var manager : TomcatManager?
    
    var preferences : Preferences!
    var preferencesWindow : PreferencesController?
    
    var webApps : [WebApp : [MenuItemType : NSMenuItem]] = [:]
    
    var tomcatMenuItem : NSMenuItem!
    var updater : NSBackgroundActivityScheduler?
    
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


        self.manager = TomcatManager()

        let pomApps = WebApp.scanPoms()
        let deployedApps = WebApp.scanWebAppsDir()

        var finalApps : [WebApp] = pomApps

        deployedApps.forEach({(app) in
            if let idx = finalApps.index(of: app) {
                //exists already
                finalApps[idx].absorb(app)
            } else {
                finalApps.append(app)
            }
        })

        finalApps.forEach({ (app) in
            app.updateState()

            let item = NSMenuItem(webApp: app, tomcatIsUp: self.tomcatUp)

            let submenu = NSMenu()
            item.submenu = submenu

            let removalItem = NSMenuItem(title: "remove", action: nil, keyEquivalent: "")
            removalItem.target = app
            removalItem.action = #selector(WebApp.remove)
            submenu.addItem(removalItem)

            webApps[app] = [
                .root : item,
                .remove : removalItem
            ]

            app.delegate = self
        })
        
        let menu = NSMenu()
        
        MenuSections.all.forEach({(section) in
            switch section {
            case .tomcat:
                self.tomcatMenuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "s")
                self.updateTomcatItem()
                menu.addItem(self.tomcatMenuItem)
                menu.addItem(NSMenuItem.separator())
            case .apps:
                if self.webApps.count > 0 {
                    self.webApps.values.forEach({ (items) in
                        menu.addItem(items[.root]!)
                    })
                    menu.addItem(NSMenuItem.separator())
                }
            case .preferences:
                menu.addItem(NSMenuItem(title: "Preferences", action: #selector(AppDelegate.launchPreferences), keyEquivalent: "p"))
                menu.addItem(NSMenuItem.separator())
            case .quit:
                menu.addItem(NSMenuItem(title: "Quit Manager", action: #selector(AppDelegate.terminate), keyEquivalent: "q"))
            }
        })
        
        statusItem.menu = menu
        
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
        let timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { (timer) in
            block(nil)
        }

        timer.tolerance = 0.5
        //

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
        guard let manager = manager else { return }
        tomcatUp = manager.isRunning()
        self.webApps.forEach({ (app, item) in
            app.updateState()
            self.updateWebAppItem(app)
        })
    }
    
    func updateMenu() {
        self.updateTomcatItem()
        self.webApps.keys.forEach { self.updateWebAppItem($0) }
    }
    
    func updateWebAppItem(_ webApp : WebApp) {
        guard let items = webApps[webApp] else { return }
        if webApp.isDeployed {
            items[.remove]?.target = webApp
            items[.remove]?.action = #selector(WebApp.remove)
        } else {
            items[.remove]?.target = nil
            items[.remove]?.action = nil
        }
        items[.root]?.updateWithApp(webApp: webApp, tomcatIsUp: self.tomcatUp)
    }
    
    func updateTomcatItem() {
        if self.tomcatUp {
            self.tomcatMenuItem.title = "Stop Tomcat"
            self.tomcatMenuItem.action = #selector(AppDelegate.stopTomcat)
        } else {
            self.tomcatMenuItem.title = "Start Tomcat"
            self.tomcatMenuItem.action = #selector(AppDelegate.startTomcat)
        }
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

extension AppDelegate : WebAppDelegate {
    func wasRemoved(_ webApp: WebApp) {
        self.updateWebAppItem(webApp)
    }
}

extension NSMenuItem {
    convenience init(webApp : WebApp, tomcatIsUp : Bool) {
        self.init()
        self.updateWithApp(webApp: webApp, tomcatIsUp: tomcatIsUp)
    }
    
    func updateWithApp(webApp : WebApp, tomcatIsUp : Bool) {
        self.title = webApp.name
        if webApp.isDeployed {
            if tomcatIsUp {
                if webApp.isExtracted {
                    self.image = Images.Indicator.good
                } else {
                    self.image = Images.Indicator.loading
                }
            } else {
                self.image = Images.Indicator.present
            }
        } else {
            self.image = Images.Indicator.off
        }
    }
}
