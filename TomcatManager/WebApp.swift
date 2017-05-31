//
//  WebApp.swift
//  TomcatManager
//
//  Created by Shad Downey on 4/2/17.
//  Copyright © 2017 Shad Downey. All rights reserved.
//

import Foundation

protocol WebAppDelegate : class {
    func wasRemoved(_ webApp: WebApp)
}

class WebApp : JavaProject {
    
    weak var delegate : WebAppDelegate?

    var isDeployed : Bool = false
    var isExtracted : Bool = false
    var isUp : Bool = false
    var canDeploy : Bool = false

    var builtWarPath : String? {
        guard let pomPath = self.pomPath else { return nil }
        return pomPath.replacingOccurrences(of: "pom.xml", with: "target/\(self.finalName).war")
    }

    fileprivate func couldDeploy(_ callback : @escaping (Bool) -> Void) -> Void {
        guard let builtWarPath = self.builtWarPath else {
            callback(false)
            return
        }
        pathExists(path: builtWarPath, callback: callback)
    }
    
    fileprivate var webAppDirPath : String {
        return [
            Preferences.StringPreference.catalinaHome.value,
            "webapps",
            finalName
            ].joined(separator: "/")
    }
    
    override func updateState(_ completion : (() -> Void)? = nil) {
        var count : Int = 0
        var expectedCount : Int = 0

        let done : () -> () = {
            count += 1
            if (count == expectedCount) {
                completion?()
            }
        }

        //Locking Queue Open Until Everything is kicked off
        expectedCount += 1

        expectedCount += 1
        super.updateState { 
            done()
        }

        expectedCount += 1
        pathExists(path: webAppDirPath) {(exists) in
            self.isExtracted = exists
            done()
        }

        expectedCount += 1
        pathExists(path: "\(webAppDirPath).war") {(exists) in
            self.isDeployed = exists
            done()
        }

        expectedCount += 1
        couldDeploy {(could) in
            self.canDeploy = could
            done()
        }

        expectedCount += 1
        pathExists(path: self.buildLogFile) { (exists) in
            self.hasLogs = exists
            done()
        }

        if let pomPath = self.pomPath {
            expectedCount += 1
            runCommandAsUser(command: "ps -eaf | grep 'mvn' | grep '\(pomPath)' | grep -v grep", silent: true) {(res, _, _) in
                self.isBuilding = res.count > 0
                done()
            }
        } else {
            self.isBuilding = false
        }

        //Releasing Locked Queue
        done()
    }

    @objc
    func remove() {
        runCommandAsUser(command: "rm -rf \"\(webAppDirPath)\"")
        runCommandAsUser(command: "rm \"\(webAppDirPath).war\"")
        self.updateState()
        if !self.isDeployed {
            self.delegate?.wasRemoved(self)
        }
    }

    @objc
    func deploy() {
        guard let builtWarPath = self.builtWarPath else { return }
        runCommandAsUser(command: "cp \"\(builtWarPath)\" \"\(webAppDirPath).war\"")
    }

    static func scanWebAppsDir(_ completion : @escaping (([WebApp]) -> Void)) -> Void {
        let path : String = [
            Preferences.StringPreference.catalinaHome.value,
            "webapps",
        ].joined(separator: "/")
        runCommandAsUser(command: "ls \(path) | grep -v 'ROOT'") {(res, _, _) in
            let apps = res.map({ (dir) -> WebApp in
                return WebApp(finalName: dir)
            })

            completion(Array(Set(apps)))
        }
    }

    override func cleanAndPackage() {
        if self.canDeploy,
            let builtPath = self.builtWarPath {
            runCommandAsUser(command: "rm \"\(builtPath)\"")
        }
        super.cleanAndPackage()
    }
    
}

func ==(lhs : WebApp, rhs : WebApp) -> Bool {
    return lhs.finalName == rhs.finalName
}

extension WebApp : Equatable {}

extension WebApp : Hashable {
    var hashValue: Int {
        return self.finalName.hashValue
    }
}

