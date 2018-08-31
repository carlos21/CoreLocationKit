//
//  CoreLocationKit.swift
//  CoreLocationKit
//
//  Created by Carlos Duclos on 8/30/18.
//  Copyright © 2018 CoreLocationKit. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

/// Shortcut to locator manager
public let LocationKit: CoreLocationKit = CoreLocationKit.shared

public class CoreLocationKit: NSObject {
    
    /// Shared instance of the location manager
    internal static let shared = CoreLocationKit()
    
    /// Current queued location requests
    private var locationRequests = ThreadSafeArray<LocationRequest>()
    
    /// Core location internal manager
    internal var manager: CLLocationManager
    
    /// Event manager
    internal var eventManager = EventManager()
    
    /// Current authorization status
    public var authorizationStatus: CLAuthorizationStatus {
        return CLLocationManager.authorizationStatus()
    }
    
    private var _currentLocation: CLLocation?
    public var currentLocation: CLLocation? {
        guard let location = _currentLocation else { return nil }
        guard CLLocationCoordinate2DIsValid(location.coordinate) else { return nil }
        guard location.coordinate.latitude != 0, location.coordinate.longitude != 0 else { return nil }
        return location
    }
    
    public override init() {
        manager = CLLocationManager()
        super.init()
        manager.delegate = self
        
        // iOS 9 requires setting allowsBackgroundLocationUpdates to true in order to receive
        // background location updates.
        // We only set it to true if the location background mode is enabled for this app,
        // as the documentation suggests it is a fatal programmer error otherwise.
        if #available(iOSApplicationExtension 9.0, *) {
            if Application.hasBackgroundCapabilities {
                self.manager.allowsBackgroundLocationUpdates = true
            }
        }
    }
    
    public func requestPosition(interval: TimeInterval? = nil, completion: @escaping LocationRequest.CompletionCallback) -> LocationRequest {
        let request = LocationRequest(mode: .once)
        request.completion = completion
        
        if let interval = interval {
            request.setTimeout(with: interval) { [weak self] in
                guard let `self` = self else { return }
                self.locationRequestDidTimedOut(request)
            }
        }
        
        addLocation(request)
        return request
    }
    
    /// Adds the given location request to the array of requests, updates
    /// the maximum desired accuracy, and starts location updates if needed.
    ///
    /// - Parameter request: request to add
    private func addLocation(_ request: LocationRequest) {
        switch request.mode {
        case .significant:
            startMonitoringSignificantLocationChangesIfNeeded()
            
        case .once, .continous:
            startUpdateLocationIfNeeded()
        }
        
        locationRequests.append(request)
    }
    
    /// Returns active requests excluding the one with given mode
    ///
    /// - Parameter mode: mode
    /// - Returns: filtered list
    private func activeLocationRequest(excludingMode mode: LocationRequest.Mode) -> [LocationRequest] {
        return locationRequests.filter { $0.mode != mode }
    }
    
    /// Return active request of the given type
    ///
    /// - Parameter mode: type to get
    /// - Returns: filtered list
    private func activeLocationRequest(forMode mode: LocationRequest.Mode) -> [LocationRequest] {
        return locationRequests.filter { $0.mode == mode }
    }
    
    private func requestAuthorizationIfNeeded(_ authorizationLevel: AuthorizationLevel? = nil) {
        let level = authorizationLevel ?? Application.authorizationLevelFromInfoPlist
        manager.requestAuthorization(forLevel: level)
    }
    
    internal func locationRequestDidTimedOut(_ request: LocationRequest) {
        if let _ = self.locationRequests.index(where: { $0 == request }) {
            self.completeLocationRequest(request)
        }
    }
    
    private func startUpdateLocationIfNeeded() {
        requestAuthorizationIfNeeded()
        
        let requests = activeLocationRequest(excludingMode: .significant)
        if requests.count == 0 {
            manager.startUpdatingLocation()
        }
    }
    
    private func startMonitoringSignificantLocationChangesIfNeeded() {
        requestAuthorizationIfNeeded()
        
        let requests = activeLocationRequest(forMode: .significant)
        if requests.count == 0 {
            manager.startMonitoringSignificantLocationChanges()
        }
    }
    
    private func processLocationRequests() {
        let location = currentLocation
        locationRequests.forEach { request in
            guard !(request.timeout?.hasTimedout ?? false) else {
                request.location = location
                completeLocationRequest(request)
                return
            }
            
            guard let mostRecentLocation = location else { return }
            
            if request.isRecurring {
                request.location = mostRecentLocation
                processRecurringRequest(request)
            } else {
                completeLocationRequest(request)
            }
        }
    }
    
    /// Handles calling a recurring location request's block with the current location.
    ///
    /// - Parameter request: request
    private func processRecurringRequest(_ request: LocationRequest?) {
        guard let request = request, request.isRecurring else { return }
        DispatchQueue.main.async {
            request.completion?(request.result)
        }
    }
    
}

extension CoreLocationKit {
    
    /// Immediately completes all active location requests.
    /// Used in cases such as when the location services authorization
    /// status changes to `.denied` or `.restricted`.
    public func completeAllLocationRequests() {
        locationRequests.forEach {
            self.completeLocationRequest($0)
        }
    }
    
    /// Complete passed location request and remove from queue if possible.
    ///
    /// - Parameter request: request
    public func completeLocationRequest(_ request: LocationRequest?) {
        guard let request = request else { return }
        
        request.timeout?.abort() // stop any running timer
        removeLocationRequest(request) // remove from queue
        
        DispatchQueue.main.async {
            request.completion?(request.result)
        }
    }
    
    /// Removes a given location request from the array of requests,
    /// updates the maximum desired accuracy, and stops location updates if needed.
    ///
    /// - Parameter request: request to remove
    private func removeLocationRequest(_ request: LocationRequest?) {
        guard let request = request else { return }
        locationRequests.remove(where: { $0 == request })
        
        switch request.mode {
        case .once, .continous:
            stopUpdatingLocationIfPossible()
            
        case .significant:
            stopMonitoringSignificantLocationChangesIfPossible()
        }
    }
    
    /// Checks to see if there are any outstanding locationRequests,
    /// and if there are none, informs CLLocationManager to stop sending
    /// location updates. This is done as soon as location updates are no longer
    /// needed in order to conserve the device's battery.
    private func stopUpdatingLocationIfPossible() {
        let requests = self.activeLocationRequest(excludingMode: .significant)
        if requests.count == 0 {
            manager.stopUpdatingLocation()
        }
    }
    
    /// Checks to see if there are any outsanding significant location request in queue.
    /// If not we can stop monitoring for significant location changes and conserve device's battery.
    private func stopMonitoringSignificantLocationChangesIfPossible() {
        let requests = self.activeLocationRequest(forMode: .significant)
        if requests.count == 0 {
            manager.stopMonitoringSignificantLocationChanges()
        }
    }
}

extension CoreLocationKit: CLLocationManagerDelegate {
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let recentLocation = locations.min { $0.timestamp.timeIntervalSinceNow < $1.timestamp.timeIntervalSinceNow }
        _currentLocation = recentLocation
        processLocationRequests()
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationRequests.forEach { request in
            if request.isRecurring {
                processRecurringRequest(request)
            } else {
                completeLocationRequest(request)
            }
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        eventManager.callbacks.values.forEach { $0(status) }
        guard status != .denied && status != .restricted  else {
            completeAllLocationRequests(); return
        }
        
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            locationRequests.forEach { $0.timeout?.startTimeout() }
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        
    }
}
