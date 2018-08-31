//
//  ThreadSafeArray.swift
//  CoreLocationKit-iOS
//
//  Created by Carlos Duclos on 8/30/18.
//  Copyright © 2018 CoreLocationKit. All rights reserved.
//

import Foundation

/// Thread-safe list
/// All functions and proprierties are thread-safe.
public class ThreadSafeArray<Element> {
    
    /// Serial DispatchQueue
    fileprivate let queue = DispatchQueue(label: "com.darkyswift.corelocationkit.threadsafearray", attributes: .concurrent)
    
    /// Safe elements
    fileprivate var elements = [Element]()
}

public extension ThreadSafeArray {
    
    /// The first element of the collection.
    var first: Element? {
        var result: Element?
        queue.sync { result = elements.first }
        return result
    }
    
    /// The last element of the collection.
    var last: Element? {
        var result: Element?
        queue.sync { result = elements.last }
        return result
    }
    
    /// The number of elements in the array.
    var count: Int {
        var result = 0
        queue.sync { result = elements.count }
        return result
    }
    
    /// A Boolean value indicating whether the collection is empty.
    var isEmpty: Bool {
        var result = false
        queue.sync { result = elements.isEmpty }
        return result
    }
    
    /// A textual representation of the array and its elements.
    var description: String {
        var result = ""
        queue.sync { result = elements.description }
        return result
    }
}

public extension ThreadSafeArray {
    
    /// Returns the first element of the sequence that satisfies the given predicate or nil if no such element is found.
    ///
    /// - Parameter predicate: A closure that takes an element of the sequence as its argument and returns a Boolean value indicating whether the element is a match.
    /// - Returns: The first match or nil if there was no match.
    func first(where predicate: (Element) -> Bool) -> Element? {
        var result: Element?
        queue.sync { result = self.elements.first(where: predicate) }
        return result
    }
    
    /// Returns an array containing, in order, the elements of the sequence that satisfy the given predicate.
    ///
    /// - Parameter isIncluded: A closure that takes an element of the sequence as its argument and returns a Boolean value indicating whether the element should be included in the returned array.
    /// - Returns: An array of the elements that includeElement allowed.
    func filter(_ isIncluded: (Element) -> Bool) -> [Element] {
        var result = [Element]()
        queue.sync { result = self.elements.filter(isIncluded) }
        return result
    }
    
    /// Returns the first index in which an element of the collection satisfies the given predicate.
    ///
    /// - Parameter predicate: A closure that takes an element as its argument and returns a Boolean value that indicates whether the passed element represents a match.
    /// - Returns: The index of the first element for which predicate returns true. If no elements in the collection satisfy the given predicate, returns nil.
    func index(where predicate: (Element) -> Bool) -> Int? {
        var result: Int?
        queue.sync { result = self.elements.index(where: predicate) }
        return result
    }
    
    /// Returns the elements of the collection, sorted using the given predicate as the comparison between elements.
    ///
    /// - Parameter areInIncreasingOrder: A predicate that returns true if its first argument should be ordered before its second argument; otherwise, false.
    /// - Returns: A sorted array of the collection’s elements.
    func sorted(by areInIncreasingOrder: (Element, Element) -> Bool) -> [Element] {
        var result = [Element]()
        queue.sync { result = self.elements.sorted(by: areInIncreasingOrder) }
        return result
    }
    
    /// Returns an array containing the non-nil results of calling the given transformation with each element of this sequence.
    ///
    /// - Parameter transform: A closure that accepts an element of this sequence as its argument and returns an optional value.
    /// - Returns: An array of the non-nil results of calling transform with each element of the sequence.
    func flatMap<ElementOfResult>(_ transform: (Element) -> ElementOfResult?) -> [ElementOfResult] {
        var result = [ElementOfResult]()
        queue.sync { result = self.elements.compactMap(transform) }
        return result
    }
    
    /// Calls the given closure on each element in the sequence in the same order as a for-in loop.
    ///
    /// - Parameter body: A closure that takes an element of the sequence as a parameter.
    func forEach(_ body: (Element) -> Void) {
        queue.sync { self.elements.forEach(body) }
    }
    
    /// Returns a Boolean value indicating whether the sequence contains an element that satisfies the given predicate.
    ///
    /// - Parameter predicate: A closure that takes an element of the sequence as its argument and returns a Boolean value that indicates whether the passed element represents a match.
    /// - Returns: true if the sequence contains an element that satisfies predicate; otherwise, false.
    func contains(where predicate: (Element) -> Bool) -> Bool {
        var result = false
        queue.sync { result = self.elements.contains(where: predicate) }
        return result
    }
}

public extension ThreadSafeArray {
    
    /// Adds a new element at the end of the array.
    ///
    /// - Parameter element: The element to append to the array.
    func append(_ element: Element) {
        queue.async(flags: .barrier) {
            self.elements.append(element)
        }
    }
    
    /// Adds a new element at the end of the array.
    ///
    /// - Parameter element: The element to append to the array.
    func append(_ elements: [Element]) {
        queue.async(flags: .barrier) {
            self.elements += elements
        }
    }
    
    /// Inserts a new element at the specified position.
    ///
    /// - Parameters:
    ///   - element: The new element to insert into the array.
    ///   - index: The position at which to insert the new element.
    func insert(_ element: Element, at index: Int) {
        queue.async(flags: .barrier) {
            self.elements.insert(element, at: index)
        }
    }
    
    /// Removes and returns the element at the specified position.
    ///
    /// - Parameters:
    ///   - index: The position of the element to remove.
    ///   - completion: The handler with the removed element.
    func remove(at index: Int, completion: ((Element) -> Void)? = nil) {
        queue.async(flags: .barrier) {
            let element = self.elements.remove(at: index)
            
            DispatchQueue.main.async {
                completion?(element)
            }
        }
    }
    
    /// Removes and returns the element at the specified position.
    ///
    /// - Parameters:
    ///   - predicate: A closure that takes an element of the sequence as its argument and returns a Boolean value indicating whether the element is a match.
    ///   - completion: The handler with the removed element.
    func remove(where predicate: @escaping (Element) -> Bool, completion: ((Element) -> Void)? = nil) {
        queue.async(flags: .barrier) {
            guard let index = self.elements.index(where: predicate) else { return }
            let element = self.elements.remove(at: index)
            
            DispatchQueue.main.async {
                completion?(element)
            }
        }
    }
    
    /// Removes all elements from the array.
    ///
    /// - Parameter completion: The handler with the removed elements.
    func removeAll(completion: (([Element]) -> Void)? = nil) {
        queue.async(flags: .barrier) {
            let elements = self.elements
            self.elements.removeAll()
            
            DispatchQueue.main.async {
                completion?(elements)
            }
        }
    }
}

public extension ThreadSafeArray {
    
    /// Accesses the element at the specified position if it exists.
    ///
    /// - Parameter index: The position of the element to access.
    /// - Returns: optional element if it exists.
    subscript(index: Int) -> Element? {
        get {
            var result: Element?
            
            queue.sync {
                guard self.elements.startIndex..<self.elements.endIndex ~= index else { return }
                result = self.elements[index]
            }
            
            return result
        }
        set {
            guard let newValue = newValue else { return }
            
            queue.async(flags: .barrier) {
                self.elements[index] = newValue
            }
        }
    }
}


// MARK: - Equatable
public extension ThreadSafeArray where Element: Equatable {
    
    /// Returns a Boolean value indicating whether the sequence contains the given element.
    ///
    /// - Parameter element: The element to find in the sequence.
    /// - Returns: true if the element was found in the sequence; otherwise, false.
    func contains(_ element: Element) -> Bool {
        var result = false
        queue.sync { result = self.elements.contains(element) }
        return result
    }
}

// MARK: - Infix operators
public extension ThreadSafeArray {
    
    static func += (left: inout ThreadSafeArray, right: Element) {
        left.append(right)
    }
    
    static func += (left: inout ThreadSafeArray, right: [Element]) {
        left.append(right)
    }
}
