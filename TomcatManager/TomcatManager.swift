//
//  TomcatManager.swift
//  TomcatManager
//
//  Created by Shad Downey on 4/1/17.
//  Copyright © 2017 Shad Downey. All rights reserved.
//

import Foundation

class TomcatManager {
    
    fileprivate var catalinaHome : String {
        return Preferences.StringPreference.catalinaHome.value
    }
    
    init() {
    }
    
    @discardableResult
    fileprivate func bin(_ script : String) -> ShellResponse {
        let cmd : String = [catalinaHome, "bin", script].joined(separator: "/")
        return runCommandAsUser(command:cmd)
    }
    
    func tomcatPID() -> String? {
        let (output, _, _) = runCommandAsUser(command: "ps -eaf | grep tomcat | grep 'org.apache.catalina.startup.Bootstrap' | grep -v grep | awk '{ print $2 }'", silent: true)
        return output.first
    }
    
    func isRunning() -> Bool {
        return tomcatPID() != nil
    }
    
    func startup() {
        self.bin("startup.sh")
    }
    
    func shutdown() {
        self.bin("shutdown.sh")
        runCommandAsUser(command: "ps -eaf | grep tomcat | grep -v grep | awk '{ print $2 }' | xargs kill -9")
    }
    
}

