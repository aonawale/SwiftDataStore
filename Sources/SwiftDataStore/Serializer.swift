//
//  Serializer.swift
//  SwiftDataStore
//
//  Created by Ahmed Onawale on 2/4/17.
//  Copyright © 2017 Ahmed Onawale. All rights reserved.
//

public struct SerializationOptions: OptionSet {
    public let rawValue: Int
    
    public static let includeId  = SerializationOptions(rawValue: 1 << 0)
    public static let all: SerializationOptions = [.includeId]
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

public protocol Serializer: Cacheable {
    var primaryKey: PrimaryKey { get }
    
    var writingOptions: JSONSerialization.WritingOptions { get }
    var readingOptions: JSONSerialization.ReadingOptions { get }
    
    func extract(id hash: JSON) throws -> ID
    func extract(meta hash: JSON) -> JSON?
    
    func serialize(json: JSON) throws -> Data
    
    func serialize(record: Snapshot, options: SerializationOptions) -> JSON
    func serialize(records: [Snapshot], options: SerializationOptions) -> [JSON]
    
    func serializeID(record: Snapshot, hash: inout JSON, primaryKey: PrimaryKey)
    func serialize(into hash: inout JSON, snapshot: Snapshot, options: SerializationOptions)
    
    func normalize<T: Record>(type: T.Type, hash: JSON) throws -> T
    func normalize<T: Record>(type: T.Type, hash: [JSON]) throws -> [T]
    
    func normalize<T: Record>(single data: Data, for type: T.Type, request: Request) throws -> T
    func normalize<T: Record>(create data: Data, for type: T.Type, request: Request) throws -> T
    func normalize<T: Record>(findRecord data: Data, for type: T.Type, request: Request) throws -> T
    
    func normalize<T: Record>(many data: Data, for type: T.Type) throws -> RecordArray<T>
    func normalize<T: Record>(query data: Data, for type: T.Type) throws -> RecordArray<T>
    func normalize<T: Record>(findAll data: Data, for type: T.Type) throws -> RecordArray<T>
    
    func normalize<T: Record>(response data: Data, for type: T.Type, request: Request) throws -> T
    func normalize<T: Record>(response data: Data, for type: T.Type, request: Request) throws -> RecordArray<T>
}

public extension Serializer {
    var primaryKey: String {
        return "id"
    }
    
    var writingOptions: JSONSerialization.WritingOptions {
        return []
    }
    
    var readingOptions: JSONSerialization.ReadingOptions {
        return []
    }
    
    func extract(meta hash: JSON) -> JSON? {
        return hash["meta"] as? JSON
    }
    
    func extract(id hash: JSON) throws -> ID {
        guard let id = hash[primaryKey] as? CustomStringConvertible else {
            throw SerializerError.requiresID
        }
        return ID(id)
    }
    
    func normalize<T: Record>(type: T.Type, hash: [JSON]) throws -> [T] {
        return try hash.map { try normalize(type: type, hash: $0) }
    }
    
    // MARK: Serialization
    func serializeID(record: Snapshot, hash: inout JSON, primaryKey: PrimaryKey) {
        hash[primaryKey] = record.id?.value
    }
    
    func serialize(into hash: inout JSON, snapshot: Snapshot, options: SerializationOptions) {
        hash = serialize(record: snapshot, options: options)
    }
    
    func serialize(record: Snapshot, options: SerializationOptions) -> JSON {
        var hash = record.json() ?? JSON()
        if options.contains(.includeId) {
            serializeID(record: record, hash: &hash, primaryKey: primaryKey)
        }
        return hash
    }
    
    func serialize(json: JSON) throws -> Data {
        return try JSONSerialization.data(withJSONObject: json, options: writingOptions)
    }
    
    func serialize(records: [Snapshot], options: SerializationOptions) -> [JSON] {
        return records.map { serialize(record: $0, options: options) }
    }
    
    // MARK: Normalization
    func normalize<T: Record>(type: T.Type, hash: JSON) throws -> T {
        let id = try extract(id: hash)
        return try type.init(id: id, hash: hash)
    }
    
    func normalize(data: Data) throws -> JSON {
        guard let json = try JSONSerialization.jsonObject(with: data, options: readingOptions) as? JSON else {
            throw SerializerError.invalidJSON
        }
        return json
    }
    
    func normalize(data: Data) throws -> [JSON] {
        guard let json = try JSONSerialization.jsonObject(with: data, options: readingOptions) as? [JSON] else {
            throw SerializerError.invalidJSON
        }
        return json
    }
    
    // MARK: Normalize many response
    func normalize<T: Record>(findAll data: Data, for type: T.Type) throws -> RecordArray<T> {
        return try normalize(many: data, for: type)
    }
    
    func normalize<T: Record>(query data: Data, for type: T.Type) throws -> RecordArray<T> {
        return try normalize(many: data, for: type)
    }
    
    func normalize<T: Record>(many data: Data, for type: T.Type) throws -> RecordArray<T> {
        let json: [JSON] = try normalize(data: data)
        let records = try normalize(type: type, hash: json)
        return RecordArray(records)
    }
    
    func normalize<T: Record>(response data: Data, for type: T.Type, request: Request) throws -> RecordArray<T> {
        switch request {
        case .findAll:
            return try normalize(findAll: data, for: type)
        case .query:
            return try normalize(query: data, for: type)
        default:
            return try normalize(many: data, for: type)
        }
    }
    
    // MARK: Normalize single response
    func normalize<T: Record>(single data: Data, for type: T.Type, request: Request) throws -> T {
        let json: JSON = try normalize(data: data)
        return try normalize(type: type, hash: json)
    }
    
    func normalize<T: Record>(findRecord data: Data, for type: T.Type, request: Request) throws -> T {
        return try normalize(single: data, for: type, request: request)
    }
    
    func normalize<T: Record>(create data: Data, for type: T.Type, request: Request) throws -> T {
        return try normalize(single: data, for: type, request: request)
    }
    
    func normalize<T: Record>(response data: Data, for type: T.Type, request: Request) throws -> T {
        switch request {
        case .find:
            return try normalize(findRecord: data, for: type, request: request)
        case .create:
            return try normalize(create: data, for: type, request: request)
        default:
            return try normalize(single: data, for: type, request: request)
        }
    }
}

public class JSONSerializer: Serializer {
    
    public required init() {}
    
}

public class RESTSerializer: Serializer {
    
    public required init() {}
    
    func payloadKey(from type: Record) -> String {
        return String(describing: type).lowercased()
    }
    
}
