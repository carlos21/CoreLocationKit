//
//  Event.swift
//  CoreLocationKit-iOS
//
//  Created by Carlos Duclos on 8/31/18.
//  Copyright © 2018 CoreLocationKit. All rights reserved.
//

import Foundation
import CoreLocation

extension CoreLocationKit {
    
    public class EventManager {
        
        public typealias Identifier = UInt64
        
        /// Identifier
        private var nextIdentifierID: Identifier = 0
        
        /// Did Change Auth Closure type
        public typealias AuthorizationDidChangeEvent = ((CLAuthorizationStatus) -> (Void))
        
        /// Listeners of auth status change
        internal var callbacks: [Identifier : AuthorizationDidChangeEvent] = [:]
        
        /// Add a listener for authorization change status
        ///
        /// - Parameter callback: callback to call
        /// - Returns: identifier used to remove the listener in a second time.
        public func listen(forAuthChanges callback: @escaping AuthorizationDidChangeEvent) -> Identifier {
            nextIdentifierID += 1
            callbacks[nextIdentifierID] = callback
            return nextIdentifierID
        }
        
        /// Remove listener from identifier.
        ///
        /// - Parameter identifier: identifier
        /// - Returns: `true` if removed, `false` otherwise
        @discardableResult
        public func remove(identifier: Identifier) -> Bool {
            return (self.callbacks.removeValue(forKey: identifier) != nil)
        }
        
        /// Remove all registered listeners.
        public func removeAll() {
            self.callbacks.removeAll()
        }
    }
}
