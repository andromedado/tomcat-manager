//
//  EnvManager.swift
//  TomcatManager
//
//  Created by Shad Downey on 4/7/17.
//  Copyright © 2017 Shad Downey. All rights reserved.
//

import Foundation
import Cocoa

protocol EnvManagerDelegate : class {
    func availableEnvironmentsUpdated(_ envs : [Env])
}

protocol EnvDelegate : class {
    func envBecameActive(_ env : Env)
}

class Env {
    let name : String
    var menuItem : NSMenuItem

    weak var delegate : EnvDelegate?

    init(name : String) {
        self.name = name
        self.menuItem = NSMenuItem(title: self.name, action: nil, keyEquivalent: "")
        self.menuItem.target = self
        self.menuItem.action = #selector(Env.switchTo)
    }

    @objc
    func switchTo() {
        let catalinaHome = Preferences.StringPreference.catalinaHome.value
        guard catalinaHome.lengthOfBytes(using: .utf8) > 0 else { return }
        runCommandAsUser(command: "rm \"\(catalinaHome)/dibs\"", callback: {[weak self] (_, _, _) in
            guard let strongSelf = self else { return }
            runCommandAsUser(command: "ln -s \"\(catalinaHome)/dibs_\(strongSelf.name)\" \"\(catalinaHome)/dibs\"", callback: {[weak self] (_, _, _) in
                guard let strongSelf = self else { return }
                strongSelf.delegate?.envBecameActive(strongSelf)
            })
        })
    }
}

fileprivate let kBaseName = "Environment"

class EnvManager {

    weak var delegate : EnvManagerDelegate?

    var menuItem : NSMenuItem

    var currentEnv : String = "" {
        didSet {
            guard oldValue != currentEnv else { return }
            onMain {
                self.menuItem.title = "\(kBaseName) - \(self.currentEnv)"
                self.availableEnvironments.forEach({(env) in
                    if env.name == self.currentEnv {
                        env.menuItem.image = #imageLiteral(resourceName: "check")
                    } else {
                        env.menuItem.image = #imageLiteral(resourceName: "emptyCheck")
                    }
                })
            }
        }
    }

    init() {
        self.menuItem = NSMenuItem(title: kBaseName, action: nil, keyEquivalent: "")
    }

    var availableEnvironments : [Env] = [] {
        didSet {
            onMain {
                let submenu = NSMenu()
                self.availableEnvironments.forEach { submenu.addItem($0.menuItem) }
                self.menuItem.submenu = submenu
            }
            self.delegate?.availableEnvironmentsUpdated(self.availableEnvironments)
        }
    }

    func determineCurrentEnv() {
        let catalinaHome = Preferences.StringPreference.catalinaHome.value
        guard catalinaHome.lengthOfBytes(using: .utf8) > 0 else { return }
        runCommandAsUser(command: "ls -l \"\(catalinaHome)\" | grep dibs | grep -v '[0-9] dibs_' | sed -e 's/.*dibs_//g'") {(res, _, _) in
            guard let envName = res.first else { return }
            self.currentEnv = envName
        }
    }

    func scan() {
        let catalinaHome = Preferences.StringPreference.catalinaHome.value
        guard catalinaHome.lengthOfBytes(using: .utf8) > 0 else { return }
        runCommandAsUser(command: "ls \"\(catalinaHome)\" | grep dibs_") {(res, _, _) in
            var availableEnvironments : [Env] = []
            res.forEach {(dir) in
                let env = Env(name:dir.replacingOccurrences(of: "dibs_", with: ""))
                env.delegate = self
                availableEnvironments.append(env)
            }
            self.availableEnvironments = availableEnvironments
        }
        determineCurrentEnv()
    }

}

extension EnvManager : EnvDelegate {
    func envBecameActive(_ env: Env) {
        self.determineCurrentEnv()
    }
}



