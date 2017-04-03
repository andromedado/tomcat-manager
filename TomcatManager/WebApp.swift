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
    var isDeployed : Bool = false
    var isExtracted : Bool = false
    var isUp : Bool = false
    
    init(finalName : String) {
        if finalName.contains(".war") {
            self.finalName = finalName.replacingOccurrences(of: ".war", with: "")
        } else {
            self.finalName = finalName
        }
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
    
    static func scan() -> [WebApp] {
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

