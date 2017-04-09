//
//  Store.swift
//  SwiftDataStore
//
//  Created by Ahmed Onawale on 2/4/17.
//  Copyright © 2017 Ahmed Onawale. All rights reserved.
//

fileprivate enum CacheType: String {
    case adapter
    case serializer
    case record
}

fileprivate struct LookupKey: Hashable {
    let hashValue: Int
    let cacheType: CacheType
    let cacheName: String
    
    init<T: Record>(cacheType: CacheType, type: T.Type) {
        self.cacheType = cacheType
        let name = String(describing: type).lowercased()
        self.cacheName = "\(cacheType.rawValue):\(name)"
        self.hashValue = cacheName.hashValue
    }
}

fileprivate extension LookupKey {
    static func ==(lhs: LookupKey, rhs: LookupKey) -> Bool {
        return lhs.cacheName == rhs.cacheName
    }
}

fileprivate final class InstanceCache {
    private lazy var cache = [LookupKey: Cacheable]()
    
    func get<T: Record>(cacheType: CacheType, type: T.Type) -> Cacheable {
        let lookupKey = LookupKey(cacheType: cacheType, type: type)
        var instance = cache[lookupKey]
        if let instance = instance {
            return instance
        }
        instance = cacheType == .adapter ? adapterInstance(for: type) : serializerInstance(for: type)
        cache[lookupKey] = instance
        return instance!
    }
    
    private func serializerInstance<T: Record>(for type: T.Type) -> Cacheable {
        return type.serializerType.init()
    }
    
    private func adapterInstance<T: Record>(for type: T.Type) -> Cacheable {
        return type.adapterType.init()
    }
}

fileprivate extension Dictionary {
    func get(_ key: Key) -> RecordSet {
        guard let recordSet = self[key] as? RecordSet else { return RecordSet() }
        return recordSet
    }
}
fileprivate final class RecordManager {
    private lazy var records = Dictionary<LookupKey, RecordSet>()
    
    @discardableResult func load<T: Record>(_ record: T) -> T {
        let type = type(of: record)
        let lookupKey = LookupKey(cacheType: .record, type: type)
        var recordSet = records.get(lookupKey)
        recordSet.insert(record)
        records[lookupKey] = recordSet
        return record
    }
    
    func get<T: Record>(_ type: T.Type) -> [T] {
        let lookupKey = LookupKey(cacheType: .record, type: type)
        return records.get(lookupKey).elements as? [T] ?? []
    }
    
    func get<T: Record>(_ type: T.Type, id: ID) -> T? {
        let lookupKey = LookupKey(cacheType: .record, type: type)
        return records.get(lookupKey)[id] as? T
    }
    
    func remove<T: Record>(all type: T.Type) {
        let lookupKey = LookupKey(cacheType: .record, type: type)
        records[lookupKey] = RecordSet()
    }
    
    func remove<T: Record>(_ record: T) {
        let type = type(of: record.self)
        let lookupKey = LookupKey(cacheType: .record, type: type)
        var recordSet = records.get(lookupKey)
        recordSet.remove(record)
        records[lookupKey] = recordSet
    }
}

public final class Store {
    public static let shared = Store()
    private let recordManager = RecordManager()
    private let instanceCache = InstanceCache()
    
    // Disable initialization
    private init() {}
    
    @discardableResult func create<T: Record>(record: T, adapterOptions: AnyHashableJSON = [:],
                                   completion: @escaping (T?, Error?) -> Void) -> URLSessionDataTask? {
        let type = type(of: record)
        let snapshot = Snapshot(record: record, adapterOptions: adapterOptions)
        let _completion = handler(for: type, request: .create, completion: completion)
        return adapter(for: type).create(type: type, store: self, snapshot: snapshot, completion: _completion)
    }
    
    @discardableResult func find<T: Record>(all type: T.Type, adapterOptions: AnyHashableJSON = [:],
                                 completion: @escaping (RecordArray<T>?, Error?) -> Void) -> URLSessionDataTask? {
        let snapshot = Snapshot(adapterOptions: adapterOptions)
        let _completion = handler(for: type, request: .findAll, completion: completion)
        return adapter(for: type).find(all: type, store: self, snapshot: snapshot, completion: _completion)
    }

    @discardableResult func find<T: Record>(record type: T.Type, id: ID, adapterOptions: AnyHashableJSON = [:],
                                 completion: @escaping (T?, Error?) -> Void) -> URLSessionDataTask? {
        let snapshot = Snapshot(adapterOptions: adapterOptions)
        let _completion = handler(for: type, request: .find(id), completion: completion)
        return adapter(for: type).find(type: type, id: id, store: self, snapshot: snapshot, completion: _completion)
    }
    
    private func handler<T: Record>(for type: T.Type, request: Request, completion: @escaping (RecordArray<T>?, Error?) -> Void) -> DataCompletion {
        return { data, error in
            guard let data = data, error == nil else { return completion(nil, error) }
            
            do {
                let records: RecordArray<T> = try self.serializer(for: type).normalize(response: data, for: type, request: request)
                completion(try self.push(records: records), nil)
            } catch {
                completion(nil, error)
            }
        }
    }

    private func handler<T: Record>(for type: T.Type, request: Request, completion: @escaping (T?, Error?) -> Void) -> DataCompletion {
        return { data, error in
            guard let data = data, error == nil else { return completion(nil, error) }
            
            do {
                let record: T = try self.serializer(for: type).normalize(response: data, for: type, request: request)
                completion(try self.push(record: record), nil)
            } catch {
                completion(nil, error)
            }
        }
    }
    
    @discardableResult func push<T: Record>(payload: [JSON], for type: T.Type) throws -> RecordArray<T> {
        return RecordArray(try payload.map { try push(payload: $0, for: type) })
    }
    
    /**
        Push a raw `JSON` payload into the store.
        This method can be used both to push in brand new
        records, as well as to update existing records.
        - Parameters:
            - payload: The payload to push ito the store.
            - for: The type class of the payload being pushed.
        - Returns: A record of the pushed payload.
     
        ```
     
        ```
    */
    @discardableResult func push<T: Record>(payload: JSON, for type: T.Type) throws -> T {
        let record = try serializer(for: type).normalize(type: type, hash: payload)
        return try push(record: record)
    }
    
    /// Push a records into the store.
    /// - Parameter record: The record to push ito the store.
    /// - Returns: The pushed records.
    @discardableResult func push<T: Record>(record: T) throws -> T {
        guard record.id != nil else {
            throw StoreError.invalidRecord("You cannot push a record without id into the store.")
        }
        return recordManager.load(record)
    }
    
    /// Push some records into the store.
    /// - Parameter records: The records to push ito the store.
    /// - Returns: A `RecordArray` of the pushed records.
    @discardableResult func push<S: Sequence & Collection, T: Record>(records: S) throws -> RecordArray<T> where S.Iterator.Element == T {
        let _records = try records.map { try self.push(record: $0) }
        return RecordArray(_records)
    }
    
    /// This method returns an instance of serializer for the specified type.
    /// - Parameter for: The record type class.
    /// - Returns: An instance of serializer for the specified type.
    func serializer<T: Record>(for type: T.Type) -> Serializer {
        return instanceCache.get(cacheType: .serializer, type: type) as! Serializer
    }
    
    /// This method returns an instance of adapter for the specified type.
    /// - Parameter for: The record type class.
    /// - Returns: An instance of adapter for the specified type.
    func adapter<T: Record>(for type: T.Type) -> Adapter {
        return instanceCache.get(cacheType: .adapter, type: type) as! Adapter
    }
    
    /// This method will remove the records from the store.
    /// - Parameter record: The record to remove.
    func unload<T: Record>(record: T) {
        recordManager.remove(record)
    }
    
    /// This method will remove all records of the given type from the store.
    /// - Parameter all: The record type class.
    func unload<T: Record>(all type: T.Type) {
        recordManager.remove(all: type)
    }
    
    /// This method will synchronously return all records for the specified type
    /// in the store. It will not make a request to fetch records from the server.
    /// Multiple calls to this function with the same record type will always return
    /// the same records.
    /// - Parameter all: The record type class.
    /// - Returns: A `RecordArray` of the specified type.
    func peek<T: Record>(all type: T.Type) -> RecordArray<T> {
        return RecordArray(recordManager.get(type))
    }
    
    /// This method will synchronously return the record with the specifed id from
    /// the store if it's available, otherwise it will return `nil`. A record is
    /// available if it has been fetched earlier, or pushed manually into the store.
    /// - Complexity: O(1)
    /// - Parameters:
    ///     - record: The record type class.
    ///     - id: The id of the record.
    /// - Returns: A Record if it's available in the store, otherwise nil.
    func peek<T: Record>(record type: T.Type, id: ID) -> T? {
        return recordManager.get(type, id: id)
    }
}
