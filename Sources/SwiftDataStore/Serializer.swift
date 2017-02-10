//
//  Serializer.swift
//  SwiftDataStore
//
//  Created by Ahmed Onawale on 2/4/17.
//  Copyright © 2017 Ahmed Onawale. All rights reserved.
//

public protocol SerializerType: Cacheable {
    var primaryKey: String { get }
    func extract(id hash: JSON) -> ID?
    func extract(meta hash: JSON) -> JSON?
    func serialize(record: Serializable, includeId: Bool) -> JSON
    func serialize(records: [Serializable]) -> [JSON]
    func normalize<T: Model>(Type: T.Type, hash: JSON) throws -> T
    func normalize<T: Model>(Type: T.Type, hash: [JSON]) throws -> [T]
    func normalize<T: Model>(response: JSON, for Type: T.Type, requestType: RequestType) throws -> T
    func normalize<T: Model>(response: [JSON], for Type: T.Type, requestType: RequestType) throws -> RecordArray<T>
    func parse(_ response: Any?) throws -> JSON
    func parse(_ response: Any?) throws -> [JSON]
}

public extension SerializerType {
    var primaryKey: String {
        return "id"
    }
    
    func extract(meta hash: JSON) -> JSON? {
        return hash["meta"] as? JSON
    }
    
    func extract(id hash: JSON) -> ID? {
        guard let id = hash[primaryKey] as? CustomStringConvertible else { return nil }
        return ID(id)
    }
    
    func normalize<T: Model>(Type: T.Type, hash: JSON) throws -> T {
        guard let id = extract(id: hash) else { throw SerializerError.requireID }
        guard let normalized = Type.init(id: id, hash: hash) else { throw SerializerError.invalidJSON }
        return normalized
    }
    
    func normalize<T: Model>(Type: T.Type, hash: [JSON]) throws -> [T] {
        return try hash.map { try normalize(Type: Type, hash: $0) }
    }
    
    func serialize(record: Serializable, includeId: Bool = false) -> JSON {
        return record.JSONRepresentation
    }
    
    func serialize(records: [Serializable]) -> [JSON] {
        return records.map { serialize(record: $0) }
    }
    
    func parse(_ response: Any?) throws -> JSON {
        guard let payload = response as? JSON else { throw SerializerError.invalidJSON }
        return payload
    }
    
    func parse(_ response: Any?) throws -> [JSON] {
        guard let payload = response as? [JSON] else { throw SerializerError.invalidJSON }
        return payload
    }
    
    func normalizeFindAll<T: Model>(response: [JSON], for Type: T.Type) throws -> RecordArray<T> {
        return try normalizeArray(response: response, for: Type)
    }
    
    func normalizeQuery<T: Model>(response: [JSON], for Type: T.Type) throws -> RecordArray<T> {
        return try normalizeArray(response: response, for: Type)
    }
    
    func normalizeArray<T: Model>(response: [JSON], for Type: T.Type) throws -> RecordArray<T> {
        let records = try normalize(Type: Type, hash: response)
        return RecordArray(records)
    }
    
    func normalizeFindRecord<T: Model>(response: JSON, for Type: T.Type, requestType: RequestType) throws -> T {
        return try normalizeSingle(response: response, for: Type, requestType: requestType)
    }
    
    func normalizeSingle<T: Model>(response: JSON, for Type: T.Type, requestType: RequestType) throws -> T {
        return try normalize(Type: Type, hash: response)
    }
    
    func normalize<T: Model>(response: [JSON], for Type: T.Type, requestType: RequestType) throws -> RecordArray<T> {
        switch requestType {
        case .findAll:
            return try normalizeFindAll(response: response, for: Type)
        case .query:
            return try normalizeQuery(response: response, for: Type)
        default:
            return try normalizeArray(response: response, for: Type)
        }
    }
    
    func normalize<T: Model>(response: JSON, for Type: T.Type, requestType: RequestType) throws -> T {
        switch requestType {
        case .findRecord:
            return try normalizeFindRecord(response: response, for: Type, requestType: requestType)
        default:
            return try normalizeSingle(response: response, for: Type, requestType: requestType)
        }
    }
}

public struct JSONSerializer: SerializerType {
    
    public init() {}
    
}
