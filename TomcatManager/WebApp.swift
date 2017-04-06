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
    
    fileprivate var webAppDirPath : String {
        return [
            Preferences.StringPreference.catalinaHome.value,
            "webapps",
            finalName
            ].joined(separator: "/")
    }
    
    func updateState() {
        let (eRes, eErr, _) = runCommandAsUser(command: "stat \"\(webAppDirPath)\"", silent: true)
        self.isExtracted = eRes.count > 0 && eErr.count == 0
        let (dRes, dErr, _) = runCommandAsUser(command: "stat \"\(webAppDirPath).war\"", silent: true)
        self.isDeployed = self.isExtracted || (dRes.count > 0 && dErr.count == 0)
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

    static func scanPoms() -> [WebApp] {
        let pomDir = Preferences.StringPreference.repositoryRoot.value
        var apps : [WebApp] = []
        guard pomDir.lengthOfBytes(using: .utf8) > 0 else {
            return apps
        }
        let (output, _, _) = runCommandAsUser(command: "find \"\(pomDir)\" -type f -name pom.xml")

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

        return apps
    }

    static func scanWebAppsDir() -> [WebApp] {
        let path : String = [
            Preferences.StringPreference.catalinaHome.value,
            "webapps",
        ].joined(separator: "/")
        let (res, _, _) = runCommandAsUser(command: "ls \(path) | grep -v 'ROOT'")
        
        let apps = res.map({ (dir) -> WebApp in
            return WebApp(finalName: dir)
        })
        
        return Array(Set(apps))
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

