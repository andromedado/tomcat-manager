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
    func webAppMenuItemsReady(_ menuItems : [NSMenuItem]) -> Void
}

class WebAppManager : NSObject {

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

        fileprivate func update(menuItem : NSMenuItem, withWebApp webApp : WebApp, tomcatIsUp : Bool) {
            var selector : Selector? = nil
            switch self {
            case .root:
                menuItem.title = webApp.name
                if webApp.isDeployed {
                    if tomcatIsUp {
                        if webApp.isExtracted {
                            menuItem.image = Images.Indicator.good
                        } else {
                            menuItem.image = Images.Indicator.loading
                        }
                    } else {
                        menuItem.image = Images.Indicator.present
                    }
                } else {
                    if webApp.isBuilding {
                        menuItem.image = Images.Indicator.warning
                    } else if webApp.hasLogs {
                        menuItem.image = Images.Indicator.error
                    } else {
                        menuItem.image = Images.Indicator.off
                    }
                }
                return
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
        
        static let all : [MenuItemType] = {
            var types : [MenuItemType] = []
            while let type = MenuItemType(rawValue: types.count) {
                types.append(type)
            }
            return types
        }()
    }
    
    weak var delegate : WebAppManagerDelegate?

    static var shared : WebAppManager {
        return kSharedManager
    }

    var webApps : [WebApp : [MenuItemType : NSMenuItem]] = [:]

    fileprivate var pomApps : [WebApp]?
    fileprivate var deployedApps : [WebApp]?

    fileprivate var tomcatUp : Bool {
        return self.delegate?.tomcatIsUp() ?? false
    }

    func scan() {
        WebApp.scanWebAppsDir { (apps) in
            self.deployedApps = apps
            self.checkFinishedScanning()
        }
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

            var allItems : [MenuItemType : NSMenuItem] = [:]
            let submenu = NSMenu()

            MenuItemType.all.forEach {(type) in
                let item = NSMenuItem(title: type.name, action: nil, keyEquivalent: "")
                allItems[type] = item
                if type.belongsOnSubmenu {
                    submenu.addItem(item)
                }
                if type.wantsSeparator {
                    submenu.addItem(NSMenuItem.separator())
                }
            }

            allItems[.root]!.submenu = submenu

            webApps[app] = allItems
            
            app.delegate = self
        })

        let rootItems : [NSMenuItem] = webApps.map { (_, dict) -> NSMenuItem in
            return dict[.root]!
        }

        self.delegate?.webAppMenuItemsReady(rootItems)
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
                type.update(menuItem: item, withWebApp: webApp, tomcatIsUp: self.tomcatUp)
            }
        }
    }

}

extension WebAppManager : WebAppDelegate {
    func wasRemoved(_ webApp: WebApp) {
        self.updateWebAppItem(webApp)
    }
}

