//
//  functions.swift
//  TomcatManager
//
//  Created by Shad Downey on 4/1/17.
//  Copyright © 2017 Shad Downey. All rights reserved.
//

import Cocoa

func appIsRunning(bundleIdentifier : String) -> Bool {
    return nil != NSWorkspace.shared().runningApplications.first { (app) -> Bool in
        return app.bundleIdentifier == bundleIdentifier
    }
}

typealias ShellResponse = (output: [String], error: [String], exitCode: Int32)

extension String {
    func cleanedOfEscapeSequences() -> String {
        let escapeCharacter = "\u{1B}"
        if self.contains(escapeCharacter) {
            return self.replacingOccurrences(of: "\(escapeCharacter)[\\S]{0,2}", with: "", options: String.CompareOptions.regularExpression)
        }
        return self
    }

    var shellOutputCleaned : String {
        return self.trimmingCharacters(in: .newlines).cleanedOfEscapeSequences()
    }
}

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
        string = string.shellOutputCleaned
        if string.characters.count > 0 {
            output = string.components(separatedBy: "\n")
        }
    }

    let errdata = errpipe.fileHandleForReading.readDataToEndOfFile()
    if var string = String(data: errdata, encoding: .utf8) {
        string = string.shellOutputCleaned
        if string.characters.count > 0 {
            error = string.components(separatedBy: "\n")
        }
    }
    
    task.waitUntilExit()
    let status = task.terminationStatus
    
    if !silent {
        print("cmd: \n\(args.joined(separator: " "))")
        print("stdout:\n\(output.joined(separator:"\n"))\n")
        print("stderr:\n\(error.joined(separator:"\n"))")
    }
    
    return (output, error, status)
}

@discardableResult
func runCommandAsUser(command : String, silent : Bool = false) -> ShellResponse {
    return runCommand(cmd: "/bin/bash", silent: silent, args: "-l", "-c", command)
}


