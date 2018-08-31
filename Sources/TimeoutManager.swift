//
//  TimeoutManager.swift
//  CoreLocationKit-iOS
//
//  Created by Carlos Duclos on 8/31/18.
//  Copyright © 2018 CoreLocationKit. All rights reserved.
//

import Foundation

public class TimeoutManager {
    
    typealias Callback = (() -> (Void))
    
    /// This is the timeout interval
    public private(set) var interval: TimeInterval
    
    /// This is the start moment of the timeout
    public private(set) var start: Date? = nil
    
    /// Callback fired at the end of the timeout interval
    private var fireCallback: Callback? = nil
    
    /// Timer object
    private var timer: Timer? = nil
    
    /// Return the remaining time from timeout session
    public var aliveTime: TimeInterval? { 
        guard let s = self.start else { return nil }
        guard self.hasTimedout == false else { return 0 }
        return fabs(s.timeIntervalSinceNow)
    }
    
    /// Return `true` if timer has expired
    public var hasTimedout: Bool = false
    
    /// Initialize a new manager with given timeout interval
    ///
    /// - Parameter timeout: interval
    internal init(_ interval: TimeInterval, callback: @escaping Callback) {
        self.fireCallback = callback
        self.interval = interval
    }
    
    internal func startTimeout() {
        self.hasTimedout = false
        self.reset()
        self.timer = Timer.scheduledTimer(timeInterval: interval, target: self,
                                          selector: #selector(timerFired), userInfo: nil, repeats: false)
    }
    
    internal func forceTimeout() {
        self.abort()
    }
    
    /// Stop current timer
    internal func abort() {
        self.reset()
    }
    
    /// Objc function received on timer's fire event
    @objc func timerFired() {
        self.hasTimedout = true
        self.fireCallback?()
        self.reset()
    }
    
    /// Reset timer session and stop any other session
    private func reset() {
        self.timer?.invalidate()
        self.timer = nil
        self.start = Date()
    }
}
