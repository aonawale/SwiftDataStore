//
//  Model.swift
//  SwiftDataStore
//
//  Created by Ahmed Onawale on 2/4/17.
//  Copyright © 2017 Ahmed Onawale. All rights reserved.
//

/// Unique Model identifier.
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

/// ID Equatable protocol conformance
public func ==(lhs: ID, rhs: ID) -> Bool {
    return lhs.value == rhs.value
}

/// Model
/// This protocol outline requirements for
/// a type that can be managed by the `Store`
public protocol Model: Serializable, Normalizable {
    /// A unique identifier for a `Self`
    var id: ID { get }
    /// The type class to be used to make network request
    /// for `Self`. Default value is the `JSONAdapter`.
    static var adapterClass: AdapterType.Type { get }
    /// The type class to be used to serializer and normalize
    /// `Self`. Default value is the `JSONSerializer`.
    static var serializerClass: SerializerType.Type { get }
}

/// Default Model properties
public extension Model {
    static var adapterClass: AdapterType.Type {
        return JSONAdapter.self
    }
    
    static var serializerClass: SerializerType.Type {
        return JSONSerializer.self
    }
}

func ==<T: Model>(lhs: T, rhs: T) -> Bool {
    return lhs.id == rhs.id
}

/// This protocol outline requirements for
/// a type that can be represented as a JSON
public protocol JSONRepresentable {
    var JSONRepresentation: JSON { get }
}

/// This protocol outline requirements for
/// a type that can be serialized
public protocol Serializable: JSONRepresentable { }

/// Default Serializable properties
public extension Serializable {
    var JSONRepresentation: JSON {
        var representation = JSON()
        
        for case let (label?, value) in Mirror(reflecting: self).children {
            switch value {
            case let value as JSONRepresentable:
                representation[label] = value.JSONRepresentation
            default: break
            }
        }
        
        return representation
    }
}

/// This protocol outline requirements for
/// a type that can be normalized
public protocol Normalizable: JSONRepresentable {
    /// Failable Required initializer
    /// - Parameters:
    ///  - id: An ID struct uniquely identifying `Self`
    ///  - hash: A dictionary of [String: Any] containing
    ///    properties and values of `Self`
    init?(id: ID, hash: JSON)
}
