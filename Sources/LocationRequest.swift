//
//  LocationRequest.swift
//  CoreLocationKit-iOS
//
//  Created by Carlos Duclos on 8/30/18.
//  Copyright © 2018 CoreLocationKit. All rights reserved.
//

import Foundation
import CoreLocation

public class LocationRequest {
    
    public typealias CompletionCallback = (Result<CLLocation>) -> Void
    
    /// Request identifier
    public private(set) var id = UUID().uuidString
    
    /// Last location
    public internal(set) var location: CLLocation?
    
    /// Mode
    public private(set) var mode: Mode
    
    /// Timeout manager
    public private(set) var timeout: TimeoutManager?
    
    /// Returns whether this is a subscription request or not
    public var isRecurring: Bool {
        return self.mode == .continous || self.mode == .significant
    }
    
    internal var result: Result<CLLocation> = .error(.error)
    
    internal var completion: CompletionCallback?
    
    init(mode: Mode) {
        self.mode = mode
    }
    
    internal func setTimeout(with interval: TimeInterval, intervalCallback: @escaping TimeoutManager.Callback) {
        self.timeout = TimeoutManager(interval, callback: intervalCallback)
    }
}

extension LocationRequest {
    
    /// Type of the request
    public enum Mode {
        
        /// one request, request will stop once success or failure is triggered
        case once
        
        /// reports just significant changes
        case significant
        
        /// continouslly request location until manually stopped
        case continous
    }
}

extension LocationRequest: Equatable {
    
    public static func == (lhs: LocationRequest, rhs: LocationRequest) -> Bool {
        return lhs.id == rhs.id
    }
}

extension LocationRequest: Hashable {
    
    public var hashValue: Int {
        return id.hashValue
    }
}
