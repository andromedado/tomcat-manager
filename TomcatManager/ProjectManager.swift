//
//  ProjectManager.swift
//  TomcatManager
//
//  Created by Shad Downey on 4/21/17.
//  Copyright © 2017 Shad Downey. All rights reserved.
//

import Foundation
import Cocoa

fileprivate let kUpdateInterval : TimeInterval = 1.0

protocol ProjectManagerDelegate : class, KnowsTomcatStatus {
    func menuItemsReady(_ menuItems: [NSMenuItem])
}

class ProjectManager {

    unowned var delegate : ProjectManagerDelegate

    var webAppManager : WebAppManager

    fileprivate var updateTimer : Timer?

    init(delegate : ProjectManagerDelegate) {
        self.delegate = delegate

        self.webAppManager = WebAppManager()
        self.webAppManager.delegate = self
    }

    func setup() {
        self.webAppManager.scan()
        self.scanPoms { [weak self] (webApps) in
            self?.webAppManager.webAppsFoundScanningPoms(webApps)
        }

        self.updateTimer?.invalidate()
        let timer = Timer.scheduledTimer(withTimeInterval: kUpdateInterval, repeats: true) { [weak self] (timer) in
            guard let strongSelf = self else {
                timer.invalidate()
                return
            }
            strongSelf.update()
        }
        timer.tolerance = kUpdateInterval / 5
        self.updateTimer = timer
    }

    func scanPoms(_ completion : @escaping (([WebApp]) -> Void)) {
        let pomDir = Preferences.StringPreference.repositoryRoot.value
        var webApps : [WebApp] = []

        guard pomDir.lengthOfBytes(using: .utf8) > 0 else {
            completion(webApps)
            return
        }
        runCommandAsUser(command: "find \"\(pomDir)\" -type f -name pom.xml") {(output, _, _) in
            output.forEach { (path) in
                let pom = POMFile(path:path)
                do {
                    try pom.read()
                } catch {
                    //womp
                    print("couldn't read pom \(path)")
                    return
                }

                guard let packaging = pom.packaging else { return }

                switch packaging {
                case "war":
                    webApps.append(WebApp(pomFile: pom))

                default:
                    ()
                }
            }

            completion(webApps)
        }

    }

    func updateMenuItems() {
        self.webAppManager.updateAppItems()
    }

    fileprivate func update() {
        self.webAppManager.update()
    }

}

extension ProjectManager : WebAppManagerDelegate {

    func tomcatIsUp() -> Bool {
        return self.delegate.tomcatIsUp()
    }

    func webAppMenuItemsReady(_ menuItems: [NSMenuItem]) {
        self.delegate.menuItemsReady(menuItems)
    }
}


