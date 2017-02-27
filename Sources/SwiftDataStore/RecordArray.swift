//
//  RecordArray.swift
//  SwiftDataStore
//
//  Created by Ahmed Onawale on 2/5/17.
//  Copyright © 2017 Ahmed Onawale. All rights reserved.
//

/// RecordArray: A wrapper around Swift `Array`
/// with an additional `meta` property holding information
/// about elements of the array
public struct RecordArray<T: Record> {
    typealias Element = T
    
    /// This property contains extra information about the
    /// contents of the array
    let meta: JSON?
    fileprivate let elements: [Element]
    
    init<S : Sequence>(_ sequence: S, meta: JSON? = nil) where S.Iterator.Element == Element {
        elements = sequence.map { $0 }
        self.meta = meta
    }
}

extension RecordArray: Collection {
    public typealias Index = Int
    
    public var startIndex: Int {
        return elements.startIndex
    }
    
    public var endIndex: Int {
        return elements.endIndex
    }
    
    public subscript(i: Int) -> T {
        return elements[i]
    }
    
    public func index(after i: Int) -> Int {
        return elements.index(after: i)
    }
}

extension RecordArray: Sequence {
    public func makeIterator() -> IndexingIterator<Array<T>> {
        return elements.makeIterator()
    }
}
