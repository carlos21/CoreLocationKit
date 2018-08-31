//
//  Result.swift
//  CoreLocationKit-iOS
//
//  Created by Carlos Duclos on 8/30/18.
//  Copyright © 2018 CoreLocationKit. All rights reserved.
//

import Foundation

public enum Result<T> {
    
    /// Represents a successful state
    case success(T)
    
    /// Represents that an error occurred
    case error(LocationError)
}
