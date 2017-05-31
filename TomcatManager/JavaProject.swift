//
//  JavaProject.swift
//  TomcatManager
//
//  Created by Shad Downey on 5/31/17.
//  Copyright © 2017 Shad Downey. All rights reserved.
//

import Foundation


class JavaProject {

    let finalName : String

    var pomPath : String?
    var version : String?
    var artifactId : String?

    var hasLogs : Bool = false
    var isBuilding : Bool = false
    var isBuilt : Bool = false

    var pomFile : POMFile?

    init(finalName : String) {
        if finalName.contains(".war") {
            self.finalName = finalName.replacingOccurrences(of: ".war", with: "")
        } else {
            self.finalName = finalName
        }
    }
    
    convenience init(pomFile : POMFile) {
        self.init(finalName:pomFile.finalName ?? pomFile.path)
        self.pomFile = pomFile
        self.pomPath = pomFile.path
        self.version = pomFile.version
        self.artifactId = pomFile.artifactId
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

    @objc
    func openPomFile() {
        guard let path = self.pomPath else { return }
        runCommandAsUser(command: "open \"\(path)\"")
    }

    func absorb(_ other : JavaProject) {
        self.pomFile = self.pomFile ?? other.pomFile
        self.pomPath = self.pomPath ?? other.pomPath
        self.version = self.version ?? other.version
        self.artifactId = self.artifactId ?? other.artifactId
    }

    func updateState(_ completion : (() -> Void)? = nil) {
        //Check for FS changes
        completion?()
    }

    @objc
    func openLogs() {
        guard self.hasLogs else { return }
        runCommandAsUser(command: "open \"\(self.buildLogFile)\"")
    }

    @objc
    func cleanAndPackage() {
        guard let pomPath = self.pomPath else { return }
        if self.hasLogs {
            runCommandAsUser(command: "rm \"\(self.buildLogFile)\"")
        }
        runCommandAsUser(command: "mvn -DskipTests -DskipRestdoc clean package -f \"\(pomPath)\" > \(self.buildLogFile)")
    }

}

