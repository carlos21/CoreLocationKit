//
//  CLLocationManager.swift
//  CoreLocationKit-iOS
//
//  Created by Carlos Duclos on 8/30/18.
//  Copyright © 2018 CoreLocationKit. All rights reserved.
//

import Foundation
import CoreLocation

public extension CLLocationManager {
    
    internal func requestAuthorization(forLevel level: AuthorizationLevel) {
        let status = CLLocationManager.authorizationStatus()
        guard status != .notDetermined else { return }
        
        switch level {
        case .always: requestAlwaysAuthorization()
        case .whenInUse: requestWhenInUseAuthorization()
        }
    }
}
