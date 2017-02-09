//
//  RecordSet.swift
//  SwiftDataStore
//
//  Created by Ahmed Onawale on 2/4/17.
//  Copyright © 2017 Ahmed Onawale. All rights reserved.
//

/// RecordSet
/// Primary Model data store
/// Internally models are stored in a dictionary with type
/// [modelId: model]
public struct RecordSet {
    public typealias Element = Model
    
    fileprivate var contents: [ID: Element] = [:]
    
    /// The number of elements in the Set.
    var count: Int { return contents.count }
    
    /// Returns `true` if the Set is empty.
    var isEmpty: Bool { return contents.isEmpty }
    
    /// The elements of the Set as an array.
    var elements: [Element] { return Array(contents.values) }
    
    /// The elements id of the Set as an array.
    var elementsID: [ID] { return Array(contents.keys) }
    
    /// Returns `true` if the Set contains `element`.
    func contains(_ element: Element) -> Bool {
        return contents[element.id] != nil
    }
    
    subscript(id: ID) -> Element? {
        return contents[id]
    }
    
    /// Add `newElements` to the Set.
    mutating func insert(_ elements: Element...) {
        elements.forEach { contents[$0.id] = $0 }
    }
    
    /// Overloaded version that accepts an array instead of varadic parameters
    mutating func insert(_ elements: [Element]) {
        elements.forEach { contents[$0.id] = $0 }
    }
    
    /// Remove `element` from the Set.
    @discardableResult mutating func remove(_ element: Element) -> Element? {
        return contents.removeValue(forKey: element.id)
    }
}

// MARK: RecordSet Sequence conformance
extension RecordSet : Sequence {
    public typealias RecordSetIterator = DictionaryIterator<ID, Element>
    
    public func makeIterator() -> LazyMapIterator<RecordSetIterator, Element> {
        return contents.values.makeIterator()
    }
}

// MARK: RecordSet Easier initialization
extension RecordSet {
    init<S: Sequence>(_ sequence: S) where S.Iterator.Element == Element {
        sequence.forEach { contents[$0.id] = $0 }
    }
}

// MARK: RecordSet ExpressibleByArrayLiteral conformance
extension RecordSet : ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Element...) {
        self.init(elements)
    }
}

// Hoping to use this to implement function.apply
// we used to have this in other programming languages
@discardableResult func apply<T, U>(fn: (T...) -> U, args: [T]) -> U {
    typealias FunctionType = ([T]) -> U
    return unsafeBitCast(fn, to: FunctionType.self)(args)
}

extension RecordSet {
    /// Returns a new Set including only those elements `x` where `includeElement(x)` is true.
    public func filter(includeElement: (Element) -> Bool) -> RecordSet {
        return RecordSet(elements.filter(includeElement))
    }
    
    /// Returns a new Set where each element `x` is transformed by `transform(x)`.
    public func map<U: Element>(transform: (Element) -> U) -> RecordSet {
        return RecordSet(elements.map(transform))
    }
    
    /// Extends the Set by adding all the elements of `seq`.
    public mutating func extend<S : Sequence>(_ sequence: S) where S.Iterator.Element == Element {
        sequence.forEach { insert($0) }
    }
}

// MARK: RecordSet Algebra
extension RecordSet {
    /// Returns `true` if the Set has the exact same members as `set`.
    func isEqualTo(_ recordSet: RecordSet) -> Bool {
        return self.elementsID == recordSet.elementsID
    }
    
    /// Returns `true` if the Set shares any members with `set`.
    func intersects(_ recordSet: RecordSet) -> Bool {
        return (first { recordSet.contains($0) } != nil)
    }
    
    /// Returns `true` if all members of the Set are part of `set`.
    func isSubsetOf(_ recordSet: RecordSet) -> Bool {
        return (first { !recordSet.contains($0) } != nil)
    }
    
    /// Returns `true` if all members of `set` are part of the Set.
    func isSupersetOf(_ recordSet: RecordSet) -> Bool {
        return recordSet.isSubsetOf(self)
    }
    
    /// Modifies the Set to add all members of `set`.
    mutating func union(_ recordSet: RecordSet) {
        insert(recordSet.elements)
    }
    
    /// Modifies the Set to remove any members also in `set`.
    mutating func subtract(_ recordSet: RecordSet) {
        recordSet.forEach { remove($0) }
    }
    
    /// Modifies the Set to include only members that are also in `set`.
    mutating func intersect(_ recordSet: RecordSet) {
        self = filter { recordSet.contains($0) }
    }
    
    /// Returns a new Set that contains all the elements of both this set and the set passed in.
    func setByUnionWith(_ recordSet: RecordSet) -> RecordSet {
        var recordSet = recordSet
        recordSet.extend(self)
        return recordSet
    }
}

// MARK: Operators
func +=<T: Model>(lhs: inout RecordSet, rhs: T) {
    lhs.insert(rhs)
}

func +=(lhs: inout RecordSet, rhs: RecordSet) {
    lhs.union(rhs)
}

func +(lhs: RecordSet, rhs: RecordSet) -> RecordSet {
    return lhs.setByUnionWith(rhs)
}

func ==(lhs: RecordSet, rhs: RecordSet) -> Bool {
    return lhs.isEqualTo(rhs)
}

// MARK: CustomStringConvertible, CustomDebugStringConvertible
extension RecordSet: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        return "RecordSet (\(elements))"
    }
    
    public var debugDescription: String {
        return description
    }
}
