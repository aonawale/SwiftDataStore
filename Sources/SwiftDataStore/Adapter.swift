//
//  Adapter.swift
//  SwiftDataStore
//
//  Created by Ahmed Onawale on 2/4/17.
//  Copyright © 2017 Ahmed Onawale. All rights reserved.
//

import Pluralize

public protocol Cacheable {
    init()
}

public enum RequestType {
    case findRecord
    case findAll
    case query
    case queryRecord
    case createRecord
    case updateRecord
    case deleteRecord
}

public protocol AdapterType: Cacheable {
    var host: String { get }
    var namespace: String { get }
    var headers: JSON { get }
    var client: NetworkType { get }
    func path<T: Model>(for Type: T.Type) -> String
    func find<T: Model>(all Type: T.Type, completion: @escaping NetworkCompletion)
    func find<T: Model>(record Type: T.Type, id: ID, completion: @escaping NetworkCompletion)
    func create<T: Model>(record Type: T.Type, snapshot: Snapshot, completion: @escaping NetworkCompletion)
}

public extension AdapterType {
    var scheme: String {
        return "https"
    }
    
    var client: NetworkType {
        return WebClient(baseUrl: host)
    }
    
    var host: String {
        return ""
    }
    
    var namespace: String {
        return ""
    }
    
    var headers: JSON {
        return [:]
    }
    
    func path<T: Model>(for Type: T.Type) -> String {
        return String(describing: Type).lowercased().pluralize()
    }
    
    private func buildURL<T: Model>(for Model: T.Type, id: ID?) -> URL {
        guard let _id = id else { return URL(scheme: scheme, host: host, path: path(for: Model)) }
        return URL(scheme: scheme, host: host, path: "/\(path(for: Model))/\(_id.value)")
    }
    
    func buildURL<T: Model>(for Type: T.Type, id: ID?, snapshot: Snapshot?, requestType: RequestType, query: JSON?) -> URL {
        switch requestType {
        case .findAll:
            return urlForFind(all: Type)
        case .createRecord:
            return urlForCreate(record: Type)
        case .findRecord where id != nil:
            return urlForFind(record: Type, id: id!)
        default:
            return buildURL(for: Type, id: id)
        }
    }
    
    func urlForFind<T: Model>(all Type: T.Type) -> URL {
        return buildURL(for: Type, id: nil)
    }
    
    func urlForFind<T: Model>(record Type: T.Type, id: ID) -> URL {
        return buildURL(for: Type, id: id)
    }
    
    func urlForCreate<T: Model>(record Type: T.Type) -> URL {
        return buildURL(for: Type, id: nil)
    }
    
    func find<T: Model>(record Type: T.Type, id: ID, completion: @escaping NetworkCompletion) {
        let url = buildURL(for: Type, id: id, snapshot: nil, requestType: .findRecord, query: nil)
        return client.load(url: url, method: .get, completion: completion)
    }
    
    func find<T: Model>(all Type: T.Type, completion: @escaping NetworkCompletion) {
        let url = buildURL(for: Type, id: nil, snapshot: nil, requestType: .findAll, query: nil)
        return client.load(url: url, method: .get, completion: completion)
    }
    
    func create<T: Model>(record Type: T.Type, snapshot: Snapshot, completion: @escaping NetworkCompletion) {
        let url = buildURL(for: Type, id: nil, snapshot: snapshot, requestType: .createRecord, query: nil)
        return client.load(url: url, method: .post, completion: completion)
    }
}

public struct JSONAdapter: AdapterType {
    
    public init() {}
    
}
