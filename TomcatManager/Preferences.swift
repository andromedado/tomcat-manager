//
//  Preferences.swift
//  TomcatManager
//
//  Created by Shad Downey on 4/1/17.
//  Copyright © 2017 Shad Downey. All rights reserved.
//

import Foundation
import ServiceManagement

fileprivate protocol CanSetup {
    func setup()
}

fileprivate protocol PersistablePreference : CanSetup {
    associatedtype ValueType
    
    var keyValue : String { get }
    var value : ValueType { get }
    func setValue(_ value : ValueType)
    var defaultValue : ValueType { get }
}

extension PersistablePreference {
    func setup() {
        self.setValue(self.defaultValue)
    }
}

class Preferences {
    
    internal enum BooleanPreference : String {
        typealias ValueType = Bool
        
        case launchOnLogin
        case showAtLaunch
        
        static let all : [BooleanPreference] = [
            .launchOnLogin,
            .showAtLaunch
        ]
        
        var keyValue : String {
            return "com.shad.tomcatManagerPref." + self.rawValue
        }
        
        var defaultValue : Bool {
            switch self {
            case .launchOnLogin:
                return true
            case .showAtLaunch:
                return true
            }
        }
        
        var value : Bool {
            return UserDefaults.standard.bool(forKey: self.keyValue)
        }
        
        func setValue(_ value : Bool) {
            UserDefaults.standard.set(value, forKey: self.keyValue)
            switch self {
            case .launchOnLogin:
                SMLoginItemSetEnabled(Strings.launcherAppIdentifier as CFString, value)
            default:
                ()
            }
        }
    }
    
    enum DatePreference : String, PersistablePreference {
        typealias ValueType = Date?
        
        case lastLaunch
        
        static let all : [DatePreference] = [
            .lastLaunch
        ]
        
        var keyValue : String {
            return "com.shad.tomcatManagerPref." + self.rawValue
        }
        
        var defaultValue: Date? {
            switch self {
            case .lastLaunch:
                return Date()
            }
        }
        
        var value : Date? {
            return UserDefaults.standard.object(forKey: self.keyValue) as? Date
        }
        
        func setValue(_ value : Date?) {
            if let newVal = value {
                UserDefaults.standard.set(newVal, forKey: self.keyValue)
            } else {
                UserDefaults.standard.removeObject(forKey: self.keyValue)
            }
        }
    }
    
    fileprivate func allPreferences() -> [CanSetup] {
        return DatePreference.all as [CanSetup] + BooleanPreference.all as [CanSetup]
    }
    
    init() {
        if DatePreference.lastLaunch.value == nil {
            //First Launch, set defaults
            allPreferences().forEach({ (pref) in
                pref.setup()
            })
        }
        DatePreference.lastLaunch.setValue(Date())
    }
    
    
}

extension Preferences.BooleanPreference : PersistablePreference { }

