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
    
    fileprivate func bin(_ script : String, callback : ShellCallback? = nil) -> Void {
        let cmd : String = [catalinaHome, "bin", script].joined(separator: "/")
        runCommandAsUser(command:cmd, callback:callback)
    }
    
    func tomcatPID(_ callback : @escaping (String?) -> Void) -> Void {
        runCommandAsUser(command: "ps -eaf | grep tomcat | grep 'org.apache.catalina.startup.Bootstrap' | grep -v grep | awk '{ print $2 }'", silent: true) {(res, _, _) in
            callback(res.first)
        }
    }
    
    func isRunning(_ callback : @escaping (Bool) -> Void) -> Void {
        tomcatPID { (pid) in
            callback(pid != nil)
        }
    }
    
    func startup() {
        self.bin("startup.sh")
    }
    
    func shutdown() {
        self.bin("shutdown.sh")
        runCommandAsUser(command: "ps -eaf | grep tomcat | grep -v grep | awk '{ print $2 }' | xargs kill -9")
    }
    
}

