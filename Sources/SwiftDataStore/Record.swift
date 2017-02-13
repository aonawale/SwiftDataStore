//
//  Record.swift
//  SwiftDataStore
//
//  Created by Ahmed Onawale on 2/4/17.
//  Copyright © 2017 Ahmed Onawale. All rights reserved.
//

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

/// ID Equatable protocol conformance
public func ==(lhs: ID, rhs: ID) -> Bool {
    return lhs.value == rhs.value
}

/// Record
/// This protocol outline requirements for
/// a type that can be managed by the `Store`
public protocol Record: Serializable, Normalizable {
    /// A unique identifier for a `Self`
    var id: ID { get }
    /// The type class to be used to make network request
    /// for `Self`. Default value is the `JSONAdapter`.
    static var adapterClass: AdapterType.Type { get }
    /// The type class to be used to serializer and normalize
    /// `Self`. Default value is the `JSONSerializer`.
    static var serializerClass: SerializerType.Type { get }
}

/// Default Record properties
public extension Record {
    static var adapterClass: AdapterType.Type {
        return Adapter.self
    }
    
    static var serializerClass: SerializerType.Type {
        return JSONSerializer.self
    }
}

func ==<T: Record>(lhs: T, rhs: T) -> Bool {
    return lhs.id == rhs.id
}

///// This protocol outline requirements for
///// a type that can be represented as a JSON
//public protocol JSONRepresentable {
//    var JSONRepresentation: JSON { get }
//}

/// This protocol outline requirements for
/// a type that can be serialized
public protocol Serializable { }

/// Default Serializable properties
public extension Serializable {
    func toJSON() -> JSON {
        var json = JSON()
        
        for case let (label?, value) in Mirror(reflecting: self).children {
            if let value = value as? Serializable {
                json[label] = value.toJSON()
            } else if let value = value as? NSObject {
                json[label] = value
            }
        }
        
        return json
    }
}

/// This protocol outline requirements for
/// a type that can be normalized
public protocol Normalizable {
    /// Failable Required initializer
    /// - Parameters:
    ///  - id: An ID struct uniquely identifying `Self`
    ///  - hash: A dictionary of [String: Any] containing
    ///    properties and values of `Self`
    init?(id: ID, hash: JSON)
}
