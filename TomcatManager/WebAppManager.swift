//
//  WebAppManager.swift
//  TomcatManager
//
//  Created by Shad Downey on 4/6/17.
//  Copyright © 2017 Shad Downey. All rights reserved.
//

import Cocoa

fileprivate let kSharedManager = WebAppManager()

protocol WebAppManagerDelegate : class, KnowsTomcatStatus {
    func webAppMenuItemsReady(_ menuItems : [NSMenuItem]) -> Void
}

class WebAppManager : NSObject {

    enum MenuItemType : Int {
        case root
        case pomInfo
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
            case .pomInfo:
                return "Pom Info"
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
            var selectorPresenceControlsEnabled = true

            switch self {
            case .root:
                menuItem.title = webApp.name
                selectorPresenceControlsEnabled = false
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
            case .pomInfo:
                selectorPresenceControlsEnabled = false
                if let pom = webApp.pomFile {
                    var items : [NSMenuItem] = []

                    if webApp.pomPath != nil {
                        let item = NSMenuItem(title: "pom.xml", action: nil, keyEquivalent: "")
                        item.target = webApp
                        item.action = #selector(WebApp.openPomFile)
                        items.append(item)
                    }

                    let extractors : [(String, ((POMFile) -> String?))] = [
                        ("Version", { $0.version }),
                        ("Artifact Id", { $0.artifactId }),
                    ]

                    let miscInfo = extractors.flatMap({ (name, extractor) -> NSMenuItem? in
                        guard let val = extractor(pom) else { return nil }
                        return NSMenuItem(title: "\(name): \(val)", action: nil, keyEquivalent: "")
                    })

                    if miscInfo.count > 0 {
                        if items.count > 0 {
                            items.append(NSMenuItem.separator())
                        }
                        items.append(contentsOf: miscInfo)
                    }

                    if pom.dependencies.count > 0 {
                        if items.count > 0 {
                            items.append(NSMenuItem.separator())
                        }
                        items.append(NSMenuItem(title: "Dependencies", action: nil, keyEquivalent: ""))
                        pom.dependencies.forEach({ (dep) in
                            let item = NSMenuItem(title: "\(dep.artifactId) : \(dep.version)", action: nil, keyEquivalent: "")
                            item.isEnabled = true
                            item.indentationLevel = 1
                            items.append(item)
                        })
                    }

                    if items.count > 0 {
                        let submenu = NSMenu(title: "Pom Info")
                        items.forEach { submenu.addItem($0) }
                        submenu.autoenablesItems = false
                        menuItem.submenu = submenu
                    } else {
                        menuItem.submenu = nil
                    }

                } else {
                    menuItem.submenu = nil
                }
            }
            menuItem.target = selector == nil ? nil : webApp
            menuItem.action = selector
            if selectorPresenceControlsEnabled {
                menuItem.isEnabled = selector != nil
            }
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

    fileprivate(set) var menuItems : [NSMenuItem] = []

    fileprivate var tomcatUp : Bool {
        return self.delegate?.tomcatIsUp() ?? false
    }

    func scan() {
        WebApp.scanWebAppsDir { (apps) in
            self.deployedApps = apps
            self.checkFinishedScanning()
        }
    }

    func webAppsFoundScanningPoms(_ apps : [WebApp]) {
        self.pomApps = apps
        self.checkFinishedScanning()
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
                item.isEnabled = true
                allItems[type] = item
                if type.belongsOnSubmenu {
                    submenu.addItem(item)
                }
                if type.wantsSeparator {
                    submenu.addItem(NSMenuItem.separator())
                }
            }

            submenu.autoenablesItems = false
            allItems[.root]!.submenu = submenu

            webApps[app] = allItems
            
            app.delegate = self
        })

        self.menuItems = webApps.map { (_, dict) -> NSMenuItem in
            return dict[.root]!
        }

        self.delegate?.webAppMenuItemsReady(self.menuItems)
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

