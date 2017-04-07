//
//  WebApp.swift
//  TomcatManager
//
//  Created by Shad Downey on 4/2/17.
//  Copyright © 2017 Shad Downey. All rights reserved.
//

import Foundation
import Kanna

protocol WebAppDelegate : class {
    func wasRemoved(_ webApp: WebApp)
}

class WebApp {
    
    weak var delegate : WebAppDelegate?

    let finalName : String

    var pomPath : String?
    var version : String?

    var isDeployed : Bool = false
    var isExtracted : Bool = false
    var isUp : Bool = false
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
        return "/tmp/\(self.finalName).buid.log"
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
    
    func updateState() {
        pathExists(path: webAppDirPath) {(exists) in
            self.isExtracted = exists
        }
        pathExists(path: "\(webAppDirPath).war") {(exists) in
            self.isDeployed = exists
        }
        couldDeploy {(could) in
            self.canDeploy = could
        }
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

                guard let xml = Kanna.XML(xml:xmlString, encoding: .utf8) else {
                    print("unable to parse doc into Kanna.XMLDoc")
                    return
                }

                let namespaces : [String:String] = [
                    "pom" : "http://maven.apache.org/POM/4.0.0"
                ]

                let packaging = xml.at_xpath("//pom:packaging", namespaces:namespaces)?.text ?? ""
                let maybeVersion = xml.at_xpath("//pom:version", namespaces:namespaces)?.text
                let maybeFinalName = xml.at_xpath("//pom:finalName", namespaces:namespaces)?.text

                guard packaging == "war",
                    let version = maybeVersion,
                    let finalName = maybeFinalName else { return }
                
                let app = WebApp(finalName: finalName)
                app.version = version
                app.pomPath = pomPath
                apps.append(app)
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

