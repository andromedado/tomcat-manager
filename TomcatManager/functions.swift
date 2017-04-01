//
//  functions.swift
//  TomcatManager
//
//  Created by Shad Downey on 4/1/17.
//  Copyright © 2017 Shad Downey. All rights reserved.
//

import Cocoa
import ServiceManagement

func registerLauncher() {
    
    let worked = SMLoginItemSetEnabled(Strings.launcherAppIdentifier as CFString, true)
    
    print("worked: \(worked)")
}

func appIsRunning(bundleIdentifier : String) -> Bool {
    return nil != NSWorkspace.shared().runningApplications.first { (app) -> Bool in
        return app.bundleIdentifier == bundleIdentifier
    }
}

typealias ShellResponse = (output: [String], error: [String], exitCode: Int32)

@discardableResult
func runCommand(cmd : String, silent : Bool = false, args : String...) -> ShellResponse {
    
    var output : [String] = []
    var error : [String] = []
    
    let task = Process()
    task.launchPath = cmd
    task.arguments = args
    
    let outpipe = Pipe()
    task.standardOutput = outpipe
    let errpipe = Pipe()
    task.standardError = errpipe
    
    task.launch()
    
    let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
    if var string = String(data: outdata, encoding: .utf8) {
        string = string.trimmingCharacters(in: .newlines)
        if string.characters.count > 0 {
            output = string.components(separatedBy: "\n")
        }
    }
    
    let errdata = errpipe.fileHandleForReading.readDataToEndOfFile()
    if var string = String(data: errdata, encoding: .utf8) {
        string = string.trimmingCharacters(in: .newlines)
        if string.characters.count > 0 {
            error = string.components(separatedBy: "\n")
        }
    }
    
    task.waitUntilExit()
    let status = task.terminationStatus
    
    if !silent {
        print("stdout:\n\(output.joined(separator:"\n"))\n")
        print("stderr:\n\(error.joined(separator:"\n"))")
    }
    
    return (output, error, status)
}

@discardableResult
func runCommandAsUser(command : String, silent : Bool = false) -> ShellResponse {
    return runCommand(cmd: "/bin/bash", silent: silent, args: "-l", "-c", command)
}


