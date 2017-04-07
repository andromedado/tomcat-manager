//
//  Preferences.swift
//  TomcatManager
//
//  Created by Shad Downey on 4/1/17.
//  Copyright © 2017 Shad Downey. All rights reserved.
//

import Foundation
import ServiceManagement

fileprivate let kPreferenceStorageKeyPrefix = "com.shad.tomcatPrefs."

fileprivate protocol CanSetup {
    func setup()
}

fileprivate protocol PersistablePreference : CanSetup {
    associatedtype ValueType
    
    var keyValue : String { get }
    var value : ValueType { get }
    func setValue(_ value : ValueType)
    func getDefaultValue(_ callback : @escaping ((ValueType) -> Void)) -> Void
}

extension PersistablePreference {
    func setup() {
        self.getDefaultValue { (value) in
            self.setValue(value)
        }
    }
}

fileprivate protocol HasStaticDefaultValue : PersistablePreference {
    var defaultValue : ValueType { get }
}

extension HasStaticDefaultValue {
    func getDefaultValue(_ callback : @escaping ((ValueType) -> Void)) -> Void {
        callback(self.defaultValue)
    }
}

class Preferences {
    
    enum StringPreference : String, PersistablePreference {
        typealias ValueType = String
        
        case catalinaHome
        case repositoryRoot
        
        static let all : [StringPreference] = [
            .catalinaHome,
            .repositoryRoot
        ]
        
        var keyValue : String {
            return kPreferenceStorageKeyPrefix + self.rawValue
        }

        func getDefaultValue(_ callback: @escaping ((String) -> Void)) {
            switch self {
            case .catalinaHome:
                runCommandAsUser(command: "echo $CATALINA_HOME") { (res, _, _) in
                    callback(res.first ?? "")
                }
            case .repositoryRoot:
                runCommandAsUser(command: "echo $HOME") {(res, _, _) in
                    if let dir = res.first {
                        callback(dir + "/projects")
                    }
                    callback("")
                }
            }
        }

        var value : String {
            return UserDefaults.standard.string(forKey: self.keyValue) ?? ""
        }
        
        func setValue(_ value : String) {
            UserDefaults.standard.setValue(value, forKey: self.keyValue)
        }
    }
    
    enum BooleanPreference : String, PersistablePreference, HasStaticDefaultValue {
        typealias ValueType = Bool
        
        case launchOnLogin
        case showAtLaunch
        
        static let all : [BooleanPreference] = [
            .launchOnLogin,
            .showAtLaunch
        ]
        
        var keyValue : String {
            return kPreferenceStorageKeyPrefix + self.rawValue
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
    
    enum DatePreference : String, PersistablePreference, HasStaticDefaultValue {
        typealias ValueType = Date?
        
        case lastLaunch
        
        static let all : [DatePreference] = [
            .lastLaunch
        ]
        
        var keyValue : String {
            return kPreferenceStorageKeyPrefix + self.rawValue
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
        return DatePreference.all as [CanSetup] + BooleanPreference.all as [CanSetup] + StringPreference.all as [CanSetup]
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

