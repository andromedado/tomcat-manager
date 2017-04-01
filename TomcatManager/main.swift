//
//  main.swift
//  TomcatManager
//
//  Created by Shad Downey on 4/1/17.
//  Copyright © 2017 Shad Downey. All rights reserved.
//

import Foundation
import Cocoa

let delegate = AppDelegate() //alloc main app's delegate class
NSApplication.shared().delegate = delegate //set as app's delegate

// Old versions:
// NSApplicationMain(C_ARGC, C_ARGV)
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv);  //start of run loop
