//
//  AppDelegate.swift
//  TomcatManager
//
//  Created by Shad Downey on 3/31/17.
//  Copyright © 2017 Shad Downey. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    var statusItem : NSStatusItem!
    var tomcatOn : Bool? {
        didSet {
            guard oldValue != self.tomcatOn,
                let isOn = self.tomcatOn else { return }
            onMain {
                self.statusItem.image = isOn ? self.onImage : self.offImage
            }
            rebuildMenu()
        }
    }

    let offImage : NSImage = {
        return #imageLiteral(resourceName: "offTomcat")
    }()

    let onImage : NSImage = {
        let img = #imageLiteral(resourceName: "onTomcat")
        img.isTemplate = true
        return img
    }()

    let tomcatAppName = "Bootstrap"
    var timer : Timer!

    func isTomcatUp() -> Bool {
        return NSWorkspace.shared().runningApplications.first(where: {(app) in
            return app.localizedName == tomcatAppName
        }) != nil
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
        statusItem.image = offImage

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] (timer) in
            guard let strongSelf = self else {
                timer.invalidate()
                return
            }
            strongSelf.update()
        }
        timer.fire()
    }

    func update() {
        self.tomcatOn = self.isTomcatUp()
    }

    func rebuildMenu() {
        let menu = NSMenu()

        if self.tomcatOn ?? false {
            menu.addItem(NSMenuItem(title:"Stop Tomcat", action: #selector(AppDelegate.stopTomcat), keyEquivalent: "t"))
        } else {
            menu.addItem(NSMenuItem(title:"Start Tomcat", action: #selector(AppDelegate.startTomcat), keyEquivalent: "t"))
        }

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Logistics", action: nil, keyEquivalent: ""))

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Quit Manager", action: #selector(AppDelegate.quit), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }

    func startTomcat() {
        print("Start Tomcat!")

        @discardableResult
        func shell(_ args: String...) -> Int32 {
            let task = Process()
            task.launchPath = "/usr/bin/env"
            task.arguments = args

            var output : [String] = []
            var error : [String] = []

            let outpipe = Pipe()
            task.standardOutput = outpipe
            let errpipe = Pipe()
            task.standardError = errpipe

            task.launch()

            let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
            if var string = String(data: outdata, encoding: .utf8) {
                string = string.trimmingCharacters(in: .newlines)
                output = string.components(separatedBy: "\n")
            }

            let errdata = errpipe.fileHandleForReading.readDataToEndOfFile()
            if var string = String(data: errdata, encoding: .utf8) {
                string = string.trimmingCharacters(in: .newlines)
                error = string.components(separatedBy: "\n")
            }

            task.waitUntilExit()
            print("stdout: \(output.joined(separator:"\n"))")
            print("stderr: \(error.joined(separator:"\n"))")
            return task.terminationStatus
        }
        
//        shell("source", "/Users/shad/.bashrc")
        shell("ls", "-la", "/Users/shad/")

//        let task = Process()
//        task.launchPath = "/usr/bin/env"
//        task.arguments = ["ls -la"]
//        task.launch()
//        task.waitUntilExit()
//        print("stdout: \(task.standardOutput)")
//        print("stderr: \(task.standardError)")
    }

    func stopTomcat() {
        print("Stop Tomcat!")
    }

    func quit() {
        exit(0)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

