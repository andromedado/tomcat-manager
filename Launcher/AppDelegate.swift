//
//  AppDelegate.swift
//  Launcher
//
//  Created by Shad Downey on 4/1/17.
//  Copyright © 2017 Shad Downey. All rights reserved.
//  Thanks to https://theswiftdev.com/2015/09/17/first-os-x-tutorial-how-to-launch-an-os-x-app-at-login/
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {



    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        guard !appIsRunning(bundleIdentifier: Strings.mainAppIdentifier) else {
            self.terminate()
        }
        
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(AppDelegate.terminate), name: Notifications.killLauncher, object: Strings.mainAppIdentifier)
     
        let path = Bundle.main.bundlePath as NSString
        var components = path.pathComponents
        #if DEBUG
            components.removeLast()
            components.append("TomcatManager")
        #else
            components.removeLast()
            components.removeLast()
            components.removeLast()
            components.append("MacOS")
            components.append("TomcatManager")
        #endif
        
        let newPath = NSString.path(withComponents: components)
        let launched = NSWorkspace.shared().launchApplication(newPath)
//        
//        print("launched: \(launched)")
//        NSWorkspace.shared().runningApplications.forEach { print($0.bundleIdentifier ?? "") }
//        print("done?")
    }
    
    func terminate() -> Never {
        NSApp.terminate(nil)
        exit(0)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

