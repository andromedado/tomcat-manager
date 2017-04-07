//
//  WebAppManager.swift
//  TomcatManager
//
//  Created by Shad Downey on 4/6/17.
//  Copyright © 2017 Shad Downey. All rights reserved.
//

import Cocoa

fileprivate let kSharedManager = WebAppManager()

protocol WebAppManagerDelegate : class {
    func tomcatIsUp() -> Bool
    func finishedScanningFor(webApps : [WebApp : [MenuItemType : NSMenuItem]]) -> Void
}

class WebAppManager : NSObject {

    weak var delegate : WebAppManagerDelegate?

    static var shared : WebAppManager {
        return kSharedManager
    }

    var webApps : [WebApp : [MenuItemType : NSMenuItem]] = [:]

    fileprivate var pomApps : [WebApp]?
    fileprivate var deployedApps : [WebApp]?

    func scan() {
        WebApp.scanPoms { (pomApps) in
            self.pomApps = pomApps
            self.checkFinishedScanning()
        }
        WebApp.scanWebAppsDir { (apps) in
            self.deployedApps = apps
            self.checkFinishedScanning()
        }
    }

    fileprivate var tomcatUp : Bool {
        return self.delegate?.tomcatIsUp() ?? false
    }

    fileprivate func checkFinishedScanning() {
        guard let pomApps = self.pomApps,
            let deployedApps = self.deployedApps else { return }

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
            submenu.addItem(removalItem)

            let cleanAndPackage = NSMenuItem(title: "clean & package", action: nil, keyEquivalent: "")
            submenu.addItem(cleanAndPackage)

            let deploy = NSMenuItem(title: "deploy", action: nil, keyEquivalent: "")
            submenu.addItem(deploy)

            webApps[app] = [
                .root : item,
                .remove : removalItem,
                .deploy : deploy,
                .cleanAndPackage : cleanAndPackage
            ]
            
            app.delegate = self
        })

        self.delegate?.finishedScanningFor(webApps: webApps)
    }

    func update() {
        self.webApps.forEach({ (app, item) in
            app.updateState()
            self.updateWebAppItem(app)
        })
    }

    func updateAppItems() {
        self.webApps.keys.forEach { self.updateWebAppItem($0) }
    }

    fileprivate func updateWebAppItem(_ webApp : WebApp) {
        guard let items = webApps[webApp] else { return }
        onMain {
            if webApp.isDeployed {
                items[.remove]?.target = webApp
                items[.remove]?.action = #selector(WebApp.remove)
            } else {
                items[.remove]?.target = nil
                items[.remove]?.action = nil
            }
            if webApp.canBuild {
                items[.cleanAndPackage]?.target = webApp
                items[.cleanAndPackage]?.action = #selector(WebApp.cleanAndPackage)
            } else {
                items[.cleanAndPackage]?.target = nil
                items[.cleanAndPackage]?.action = nil
            }
            if webApp.canDeploy {
                items[.deploy]?.target = webApp
                items[.deploy]?.action = #selector(WebApp.deploy)
            } else {
                items[.deploy]?.target = nil
                items[.deploy]?.action = nil
            }
            items[.root]?.updateWithApp(webApp: webApp, tomcatIsUp: self.tomcatUp)
        }
    }

}

extension WebAppManager : WebAppDelegate {
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


