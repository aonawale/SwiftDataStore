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
    
    init<T: Record>(cacheType: CacheType, Type: T.Type) {
        self.cacheType = cacheType
        let name = String(describing: Type).lowercased()
        self.cacheName = "\(cacheType.rawValue):\(name)"
        self.hashValue = cacheName.hashValue
    }
}

fileprivate extension LookupKey {
    static func ==(lhs: LookupKey, rhs: LookupKey) -> Bool {
        return lhs.cacheName == rhs.cacheName
    }
}

fileprivate struct InstanceCache {
    private lazy var cache = [LookupKey: Cacheable]()
    
    mutating func get<T: Record>(cacheType: CacheType, Type: T.Type) -> Cacheable {
        let lookupKey = LookupKey(cacheType: cacheType, Type: Type)
        var instance = cache[lookupKey]
        if let instance = instance {
            return instance
        }
        instance = cacheType == .adapter ? adapterInstance(for: Type) : serializerInstance(for: Type)
        cache[lookupKey] = instance
        return instance!
    }
    
    private func serializerInstance<T: Record>(for Type: T.Type) -> Cacheable {
        return Type.serializerClass.init()
    }
    
    private func adapterInstance<T: Record>(for Type: T.Type) -> Cacheable {
        return Type.adapterClass.init()
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
        let Type = type(of: record.self)
        let lookupKey = LookupKey(cacheType: .record, Type: Type)
        var recordSet = records.get(lookupKey)
        recordSet.insert(record)
        records[lookupKey] = recordSet
        return record
    }
    
    func get<T: Record>(_ Type: T.Type) -> [T] {
        let lookupKey = LookupKey(cacheType: .record, Type: Type)
        return records.get(lookupKey).elements as! [T]
    }
    
    func get<T: Record>(_ Type: T.Type, id: ID) -> T? {
        let lookupKey = LookupKey(cacheType: .record, Type: Type)
        return records.get(lookupKey)[id] as? T
    }
    
    func clear<T: Record>(_ Type: T.Type) {
        let lookupKey = LookupKey(cacheType: .record, Type: Type)
        records[lookupKey] = RecordSet()
    }
    
    func clear<T: Record>(_ record: T) {
        let Type = type(of: record.self)
        let lookupKey = LookupKey(cacheType: .record, Type: Type)
        var recordSet = records.get(lookupKey)
        recordSet.remove(record)
        records[lookupKey] = recordSet
    }
}

public final class Store {
    public static let sharedStore = Store()
    private let recordManager = RecordManager()
    private lazy var instanceCache = InstanceCache()
    
    // Disable initialization
    private init() {}
    
    func find<T: Record>(all Type: T.Type, completion: @escaping (RecordArray<T>?, Error?) -> Void) {
        let completionHandler = handler(for: Type, requestType: .findAll, completion: completion)
        adapter(for: Type).find(all: Type, completion: completionHandler)
    }
    
    func find<T: Record>(record Type: T.Type, id: ID, completion: @escaping (T?, Error?) -> Void) {
        let completionHandler = handler(for: Type, requestType: .findAll, completion: completion)
        adapter(for: Type).find(record: Type, id: id, completion: completionHandler)
    }
    
    private func handler<T: Record>(for Type: T.Type, requestType: RequestType, completion: @escaping (RecordArray<T>?, Error?) -> Void) -> (Any?, Error?) -> Void {
        return { response, error in
            guard error == nil else { return completion(nil, error) }
            do {
                let _serializer = self.serializer(for: Type)
                let payload = try _serializer.parse(response) as [JSON]
                let normalized = try _serializer.normalize(response: payload, for: Type, requestType: requestType)
                completion(RecordArray(self.push(records: normalized), meta: normalized.meta), nil)
            } catch {
                completion(nil, error)
            }
        }
    }
    
    private func handler<T: Record>(for Type: T.Type, requestType: RequestType, completion: @escaping (T?, Error?) -> Void) -> (Any?, Error?) -> Void {
        return { (response, error) in
            guard error == nil else { return completion(nil, error) }
            do {
                let _serializer = self.serializer(for: Type)
                let payload = try _serializer.parse(response) as JSON
                let record = try _serializer.normalize(response: payload, for: Type, requestType: requestType)
                completion(self.push(record: record), nil)
            } catch {
                completion(nil, error)
            }
        }
    }
    
    @discardableResult func push<T: Record>(payload: [JSON], for Type: T.Type) throws -> RecordArray<T> {
        return RecordArray(try payload.map { try push(payload: $0, for: Type) })
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
    @discardableResult func push<T: Record>(payload: JSON, for Type: T.Type) throws -> T {
        do {
            let record = try serializer(for: Type).normalize(Type: Type, hash: payload)
            return push(record: record)
        } catch {
            throw error
        }
    }
    
    /// Push a records into the store.
    /// - Parameter record: The record to push ito the store.
    /// - Returns: The pushed records.
    @discardableResult func push<T: Record>(record: T) -> T {
        return recordManager.load(record)
    }
    
    /// Push some records into the store.
    /// - Parameter records: The records to push ito the store.
    /// - Returns: A `RecordArray` of the pushed records.
    @discardableResult func push<S: Sequence & Collection, T: Record>(records: S) -> RecordArray<T> where S.Iterator.Element == T {
        return RecordArray(records.map { self.push(record: $0) })
    }
    
    /// This method returns an instance of serializer for the specified type.
    /// - Parameter for: The record type class.
    /// - Returns: An instance of serializer for the specified type.
    func serializer<T: Record>(for Type: T.Type) -> SerializerType {
        return instanceCache.get(cacheType: .serializer, Type: Type) as! SerializerType
    }
    
    /// This method returns an instance of adapter for the specified type.
    /// - Parameter for: The record type class.
    /// - Returns: An instance of adapter for the specified type.
    func adapter<T: Record>(for Type: T.Type) -> AdapterType {
        return instanceCache.get(cacheType: .adapter, Type: Type) as! AdapterType
    }
    
    /// This method will remove the records from the store.
    /// - Parameter record: The record to remove.
    func unload<T: Record>(record: T) {
        recordManager.clear(record)
    }
    
    /// This method will remove all records of the given type from the store.
    /// - Parameter all: The record type class.
    func unload<T: Record>(all Type: T.Type) {
        recordManager.clear(Type)
    }
    
    /// This method will synchronously return all records for the specified type
    /// in the store. It will not make a request to fetch records from the server.
    /// Multiple calls to this function with the same record type will always return
    /// the same records.
    /// - Parameter all: The record type class.
    /// - Returns: A `RecordArray` of the specified type.
    func peek<T: Record>(all Type: T.Type) -> RecordArray<T> {
        return RecordArray(recordManager.get(Type))
    }
    
    /// This method will synchronously return the record with the specifed id from
    /// the store if it's available, otherwise it will return `nil`. A record is
    /// available if it has been fetched earlier, or pushed manually into the store.
    /// - Complexity: O(1)
    /// - Parameters:
    ///     - record: The record type class.
    ///     - id: The id of the record.
    /// - Returns: A Record if it's available in the store, otherwise nil.
    func peek<T: Record>(record Type: T.Type, id: ID) -> T? {
        return recordManager.get(Type, id: id)
    }
}
