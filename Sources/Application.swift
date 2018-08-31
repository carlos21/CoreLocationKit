//
//  Application.swift
//  CoreLocationKit-iOS
//
//  Created by Carlos Duclos on 8/30/18.
//  Copyright © 2018 CoreLocationKit. All rights reserved.
//

import Foundation
import UIKit.UIDevice

public struct Application {
    
    public static var hasBackgroundCapabilities: Bool {
        guard let capabilities = Bundle.main.infoDictionary?["UIBackgroundModes"] as? [String] else { return false }
        return capabilities.contains("location")
    }
    
    public static func validateInfoPlistRequiredKeys(for level: AuthorizationLevel) -> Bool {
        let osVersion = (UIDevice.current.systemVersion as NSString).floatValue
        switch level {
        case .always:
            if osVersion < 11 {
                return (hasPlistValue(forKey: "NSLocationAlwaysUsageDescription") ||
                    hasPlistValue(forKey: "NSLocationAlwaysAndWhenInUseUsageDescription"))
            }
            return hasPlistValue(forKey: "NSLocationAlwaysAndWhenInUseUsageDescription") &&
                hasPlistValue(forKey: "NSLocationWhenInUseUsageDescription")
            
        case .whenInUse:
            return hasPlistValue(forKey: "NSLocationWhenInUseUsageDescription")
        }
    }
    
    /// Return is specified value is set in Info.plist of the host application
    ///
    /// - Parameter key: key to validate
    /// - Returns: `true` if exists
    private static func hasPlistValue(forKey key: String) -> Bool {
        guard let dictionary = Bundle.main.infoDictionary else { return false }
        let empty = (dictionary[key] as? String)?.isEmpty ?? true
        return !empty
    }
    
    /// Return the highest authorization level based upon the value added info applications'
    /// Info.plist file.
    public static var authorizationLevelFromInfoPlist: AuthorizationLevel {
        let osVersion = (UIDevice.current.systemVersion as NSString).floatValue
        
        if osVersion < 11 {
            let hasAlwaysKey = hasPlistValue(forKey: "NSLocationAlwaysUsageDescription") &&
                hasPlistValue(forKey: "NSLocationAlwaysAndWhenInUseUsageDescription")
            let hasWhenInUse = hasPlistValue(forKey: "NSLocationWhenInUseUsageDescription")
            if hasAlwaysKey {
                return .always
            } else if hasWhenInUse {
                return .whenInUse
            } else {
                // At least one of the keys NSLocationAlwaysUsageDescription or NSLocationWhenInUseUsageDescription MUST
                // be present in the Info.plist file to use location services on iOS 8+.
                fatalError("To use location services in iOS 8+, your Info.plist must provide a value for either NSLocationWhenInUseUsageDescription or NSLocationAlwaysUsageDescription.")
            }
        } else {
            // In iOS11 stuff are changed again
            let hasAlwaysAndWhenInUse = hasPlistValue(forKey:"NSLocationAlwaysAndWhenInUseUsageDescription")
            let hasWhenInUse = hasPlistValue(forKey: "NSLocationWhenInUseUsageDescription")
            if hasAlwaysAndWhenInUse && hasWhenInUse {
                return .always
            } else if hasWhenInUse {
                return .whenInUse
            } else {
                // Key NSLocationWhenInUseUsageDescription MUST be present in the Info.plist file to use location services on iOS 11
                // For Always access NSLocationAlwaysAndWhenInUseUsageDescription must also be present.
                fatalError("To use location services in iOS 11+, your Info.plist must provide a value for NSLocationAlwaysUsageDescription and if requesting always access you must provide a value for  NSLocationAlwaysAndWhenInUseUsageDescription as well.")
            }
        }
    }
}
