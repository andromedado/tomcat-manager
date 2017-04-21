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

class WebApp {
    
    weak var delegate : WebAppDelegate?

    let finalName : String

    var pomPath : String?
    var version : String?

    var hasLogs : Bool = false
    var isDeployed : Bool = false
    var isExtracted : Bool = false
    var isUp : Bool = false
    var isBuilding : Bool = false
    var isBuilt : Bool = false

    var canDeploy : Bool = false

    init(finalName : String) {
        if finalName.contains(".war") {
            self.finalName = finalName.replacingOccurrences(of: ".war", with: "")
        } else {
            self.finalName = finalName
        }
    }

    func absorb(_ other : WebApp) {
        self.pomPath = self.pomPath ?? other.pomPath
        self.version = self.version ?? other.version
    }
    
    var name : String {
        return self.finalName
    }

    var buildLogFile : String {
        return "/tmp/\(self.finalName).build.log"
    }

    var canBuild : Bool {
        return self.pomPath != nil
    }

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
    
    func updateState(_ completion : (() -> Void)? = nil) {
        var count : Int = 0
        var expectedCount : Int = 0

        let done : () -> () = {
            count += 1
            if (count == expectedCount) {
                completion?()
            }
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
    }

    @objc
    func openLogs() {
        guard self.hasLogs else { return }
        runCommandAsUser(command: "open \"\(self.buildLogFile)\"")
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
    func cleanAndPackage() {
        guard let pomPath = self.pomPath else { return }
        if self.canDeploy,
            let builtPath = self.builtWarPath {
            runCommandAsUser(command: "rm \"\(builtPath)\"")
        }
        if self.hasLogs {
            runCommandAsUser(command: "rm \"\(self.buildLogFile)\"")
        }
        runCommandAsUser(command: "mvn -DskipTests -DskipRestdoc clean package -f \"\(pomPath)\" > \(self.buildLogFile)")
    }

    @objc
    func deploy() {
        guard let builtWarPath = self.builtWarPath else { return }
        runCommandAsUser(command: "cp \"\(builtWarPath)\" \"\(webAppDirPath).war\"")
    }

    static func scanPoms(_ completion : @escaping (([WebApp]) -> Void)) -> Void {
        let pomDir = Preferences.StringPreference.repositoryRoot.value
        var apps : [WebApp] = []
        guard pomDir.lengthOfBytes(using: .utf8) > 0 else {
            completion(apps)
            return
        }
        runCommandAsUser(command: "find \"\(pomDir)\" -type f -name pom.xml") {(output, _, _) in
            output.forEach({(pomPath) in

                var maybeXMLString : String?
                do {
                    maybeXMLString = try String(contentsOfFile: pomPath)
                } catch {
                    print("bad pom? \(pomPath)")
                    return
                }

                guard let xmlString = maybeXMLString else {
                    print("unable to build parser")
                    return
                }

                do {
                    let doc = try XMLDocument(xmlString: xmlString, options: 0)
                    let packaging = try doc.nodes(forXPath: "//packaging").first?.stringValue ?? ""
                    let maybeVersion = try doc.nodes(forXPath: "//version").first?.stringValue
                    let maybeFinalName = try doc.nodes(forXPath: "//finalName").first?.stringValue

                    guard packaging == "war",
                        let version = maybeVersion,
                        let finalName = maybeFinalName else { return }

                    let app = WebApp(finalName: finalName)
                    app.version = version
                    app.pomPath = pomPath
                    apps.append(app)
                } catch {
                    print(error)
                }
            })
            
            completion(apps)
        }

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

