//
//  Record.swift
//  SwiftDataStore
//
//  Created by Ahmed Onawale on 2/4/17.
//  Copyright © 2017 Ahmed Onawale. All rights reserved.
//

/// This protocol outlines the requirement of a type that
/// can be converted to a `JSON`
public protocol JSONRepresentable {
    /// Call this method to get a `JSON` representation of `Self`
    /// - Returns: The json representation of `Self`
    func toJSON() -> JSON
}

/// This protocol outlines the requirement of a type that
/// can created from a `JSON`
public protocol JSONInitializable {
    /// Required initializer
    /// - Parameters:
    ///  - id: An ID struct uniquely identifying `Self`
    ///  - hash: A dictionary of [String: Any]
    init(id: ID, hash: JSON) throws
}

/// Unique Record identifier.
/// Conforms to Hashable protocol
public struct ID: Hashable {
    /// The underlying value of `Self`
    public var value: String
    
    /// Interger value of `Self` if
    /// `Self` can be represented as an Integer
    public var integerValue: Int? {
        return Int(value)
    }
    
    /// Hashable protocol requirement
    public var hashValue: Int {
        return value.hashValue
    }
    
    /// Initializer
    /// - Parameter value: Any type thats conforms to the
    /// CustomStringConvertible protocol    
    init(_ value: CustomStringConvertible) {
        self.value = String(describing: value)
    }
}

/// ID CustomStringConvertible conformance
extension ID: CustomStringConvertible {
    public var description: String {
        return value
    }
}

/// ID Equatable protocol conformance
public func ==(lhs: ID, rhs: ID) -> Bool {
    return lhs.value == rhs.value
}

/// Record
/// This protocol outline requirements for
/// a type that can be managed by the `Store`
public protocol Record: JSONRepresentable, JSONInitializable {
    /// A unique identifier for a `Self`
    var id: ID? { get }
    /// The type class to be used to make network request
    /// for `Self`. Default value is the `JSONAdapter`.
    static var adapterType: Adapter.Type { get }
    /// The type class to be used to serializer and normalize
    /// `Self`. Default value is the `JSONSerializer`.
    static var serializerType: Serializer.Type { get }
}

/// Default Record properties
public extension Record {
    static var adapterType: Adapter.Type {
        return RESTAdapter.self
    }
    
    static var serializerType: Serializer.Type {
        return JSONSerializer.self
    }
    
    static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.id != nil && lhs.id == rhs.id
    }
}

/// Default JSONRepresentable method
public extension JSONRepresentable {
    func toJSON() -> JSON {
        var json = JSON()
        
        for case let (label?, value) in Mirror(reflecting: self).children {
            if let value = value as? JSONRepresentable {
                json[label] = value.toJSON()
            } else if let value = value as? NSObject {
                json[label] = value
            }
        }
        
        return json
    }
}
