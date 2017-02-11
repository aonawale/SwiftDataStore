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
    
    init<T: Model>(cacheType: CacheType, Type: T.Type) {
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
    
    mutating func get<T: Model>(cacheType: CacheType, Type: T.Type) -> Cacheable {
        let lookupKey = LookupKey(cacheType: cacheType, Type: Type)
        var instance = cache[lookupKey]
        if let instance = instance {
            return instance
        }
        instance = cacheType == .adapter ? adapterInstance(for: Type) : serializerInstance(for: Type)
        cache[lookupKey] = instance
        return instance!
    }
    
    private func serializerInstance<T: Model>(for Type: T.Type) -> Cacheable {
        return Type.serializerClass.init()
    }
    
    private func adapterInstance<T: Model>(for Type: T.Type) -> Cacheable {
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
    
    @discardableResult func load<T: Model>(_ record: T) -> T {
        let Type = type(of: record.self)
        let lookupKey = LookupKey(cacheType: .record, Type: Type)
        var recordSet = records.get(lookupKey)
        recordSet.insert(record)
        records[lookupKey] = recordSet
        return record
    }
    
    func get<T: Model>(_ Type: T.Type) -> [T] {
        let lookupKey = LookupKey(cacheType: .record, Type: Type)
        return records.get(lookupKey).elements as! [T]
    }
    
    func get<T: Model>(_ Type: T.Type, id: ID) -> T? {
        let lookupKey = LookupKey(cacheType: .record, Type: Type)
        return records.get(lookupKey)[id] as? T
    }
    
    func clear<T: Model>(_ Type: T.Type) {
        let lookupKey = LookupKey(cacheType: .record, Type: Type)
        records[lookupKey] = RecordSet()
    }
    
    func clear<T: Model>(_ record: T) {
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
    
    func find<T: Model>(all Type: T.Type, completion: @escaping (RecordArray<T>?, Error?) -> Void) {
        let completionHandler = handler(for: Type, requestType: .findAll, completion: completion)
        adapter(for: Type).find(all: Type, completion: completionHandler)
    }
    
    func find<T: Model>(record Type: T.Type, id: ID, completion: @escaping (T?, Error?) -> Void) {
        let completionHandler = handler(for: Type, requestType: .findAll, completion: completion)
        adapter(for: Type).find(record: Type, id: id, completion: completionHandler)
    }
    
    private func handler<T: Model>(for Type: T.Type, requestType: RequestType, completion: @escaping (RecordArray<T>?, Error?) -> Void) -> (Any?, Error?) -> Void {
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
    
    private func handler<T: Model>(for Type: T.Type, requestType: RequestType, completion: @escaping (T?, Error?) -> Void) -> (Any?, Error?) -> Void {
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
    
    @discardableResult func push<T: Model>(payload: [JSON], for Type: T.Type) throws -> RecordArray<T> {
        return RecordArray(try payload.map { try push(payload: $0, for: Type) })
    }
    
    @discardableResult func push<T: Model>(payload: JSON, for Type: T.Type) throws -> T {
        do {
            let record = try serializer(for: Type).normalize(Type: Type, hash: payload)
            return push(record: record)
        } catch {
            throw error
        }
    }
    
    @discardableResult func push<T: Model>(record: T) -> T {
        return recordManager.load(record)
    }
    
    @discardableResult func push<S: Sequence & Collection, T: Model>(records: S) -> RecordArray<T> where S.Iterator.Element == T {
        return RecordArray(records.map { self.push(record: $0) })
    }
    
    func serializer<T: Model>(for Type: T.Type) -> SerializerType {
        return instanceCache.get(cacheType: .serializer, Type: Type) as! SerializerType
    }
    
    func adapter<T: Model>(for Type: T.Type) -> AdapterType {
        return instanceCache.get(cacheType: .adapter, Type: Type) as! AdapterType
    }
    
    func unload<T: Model>(record: T) {
        recordManager.clear(record)
    }
    
    func unload<T: Model>(all Type: T.Type) {
        recordManager.clear(Type)
    }
    
    func peek<T: Model>(all Type: T.Type) -> RecordArray<T> {
        return RecordArray(recordManager.get(Type))
    }
    
    func peek<T: Model>(record Type: T.Type, id: ID) -> T? {
        return recordManager.get(Type, id: id)
    }
}
