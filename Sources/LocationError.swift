//
//  LocationError.swift
//  CoreLocationKit-iOS
//
//  Created by Carlos Duclos on 8/30/18.
//  Copyright © 2018 CoreLocationKit. All rights reserved.
//

import Foundation

public enum LocationError: Error {
    
    /// Time exceeded
    case timeout
    
    /// Location no determined
    case notDetermined
    
    /// Denied permissions to get position
    case denied
    
    /// Restricted permissions to get position
    case restricted
    
    /// GPS disabled
    case disabled
    
    /// General error
    case error
    
    /// Error with description
    case other(String)
}
