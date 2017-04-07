//
//  WebAppManager.swift
//  TomcatManager
//
//  Created by Shad Downey on 4/6/17.
//  Copyright © 2017 Shad Downey. All rights reserved.
//

import Cocoa

fileprivate let kSharedManager = WebAppManager()

enum MenuItemType : Int {
    case root
    case logs
    case cleanAndPackage
    case deploy
    case remove

    var name : String {
        switch self {
        case .root:
            return "<root>"
        case .logs:
            return "Logs"
        case .cleanAndPackage:
            return "Package"
        case .deploy:
            return "Deploy"
        case .remove:
            return "Remove deployed war"
        }
    }

    fileprivate func update(menuItem : NSMenuItem, withWebApp webApp : WebApp) {
        var selector : Selector? = nil
        switch self {
        case .root:
            ()
        case .logs:
            if webApp.hasLogs {
                selector = #selector(WebApp.openLogs)
            }
        case .remove:
            if webApp.isDeployed {
                selector = #selector(WebApp.remove)
            }
        case .cleanAndPackage:
            if webApp.canBuild {
                selector = #selector(WebApp.cleanAndPackage)
            }
        case .deploy:
            if webApp.canDeploy {
                selector = #selector(WebApp.deploy)
            }
        }
        menuItem.target = selector == nil ? nil : webApp
        menuItem.action = selector
    }

    fileprivate var wantsSeparator : Bool {
        switch self {
        case .logs:
            return true
        default:
            return false
        }
    }

    fileprivate var belongsOnSubmenu : Bool {
        switch self {
        case .root:
            return false
        default:
            return true
        }
    }

    static let submenuTypes : [MenuItemType] = {
        var types : [MenuItemType] = []
        var i = 0
        while let type = MenuItemType(rawValue: i) {
            if type.belongsOnSubmenu {
                types.append(type)
            }
            i += 1
        }
        return types
    }()
}

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

            let submenu = NSMenu()

            var allItems : [MenuItemType : NSMenuItem] = [:]

            MenuItemType.submenuTypes.forEach {(type) in
                let item = NSMenuItem(title: type.name, action: nil, keyEquivalent: "")
                allItems[type] = item
                submenu.addItem(item)
                if type.wantsSeparator {
                    submenu.addItem(NSMenuItem.separator())
                }
            }

            let item = NSMenuItem(webApp: app, tomcatIsUp: self.tomcatUp)

            item.submenu = submenu

            allItems[.root] = item

            webApps[app] = allItems
            
            app.delegate = self
        })

        self.delegate?.finishedScanningFor(webApps: webApps)
    }

    func update() {
        self.webApps.forEach({ (app, item) in
            app.updateState {
                self.updateWebAppItem(app)
            }
        })
    }

    func updateAppItems() {
        self.webApps.keys.forEach { self.updateWebAppItem($0) }
    }

    fileprivate func updateWebAppItem(_ webApp : WebApp) {
        guard let items = webApps[webApp] else { return }
        onMain {
            for (type, item) in items {
                type.update(menuItem: item, withWebApp: webApp)
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
            if webApp.isBuilding {
                self.image = Images.Indicator.warning
            } else if webApp.hasLogs {
                self.image = Images.Indicator.error
            } else {
                self.image = Images.Indicator.off
            }
        }
    }
}


