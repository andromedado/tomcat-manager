//
//  constants.swift
//  TomcatManager
//
//  Created by Shad Downey on 4/1/17.
//  Copyright © 2017 Shad Downey. All rights reserved.
//

import Foundation
import Cocoa

enum Notifications {
    static let killLauncher = NSNotification.Name(rawValue: "killLauncher")
    static let killManager = NSNotification.Name(rawValue: "killManager")
}

enum Strings {
    static let mainAppIdentifier = "com.shaddowney.TomcatManager"
    static let launcherAppIdentifier = "com.shaddowney.Launcher"
}

enum Images {
    
    enum Tomcat {
        static let hollow = #imageLiteral(resourceName: "hollowTomcat")
        static let color = #imageLiteral(resourceName: "colorTomcat")
        static let solid : NSImage = {
            let tom = #imageLiteral(resourceName: "colorTomcat")
            tom.isTemplate = true
            return tom
        }()
    }
    
    enum Indicator {
        static let off = #imageLiteral(resourceName: "emptyCircle")
        static let present = #imageLiteral(resourceName: "filledCircle")
        static let good = #imageLiteral(resourceName: "greenCircle")
        static let loading = #imageLiteral(resourceName: "blueCircle")
        static let warning = #imageLiteral(resourceName: "yellowCircle")
        static let error = #imageLiteral(resourceName: "redCircle")
    }
    
    
}
