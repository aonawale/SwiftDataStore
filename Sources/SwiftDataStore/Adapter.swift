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
    case findAll
    case find(record: ID)
    case query([String: String])
    case queryRecord([String: String])
    case create(record: Record)
    case update(record: Record)
    case delete(record: Record)
}

public protocol AdapterType: Cacheable {
    var host: String { get }
    var namespace: String { get }
    var headers: [String: String] { get }
    var client: NetworkType { get }
    func path<T: Record>(for Type: T.Type) -> String
    func find<T: Record>(all type: T.Type, completion: @escaping NetworkCompletion)
    func find<T: Record>(record type: T.Type, id: ID, completion: @escaping NetworkCompletion)
    func create<T: Record>(record: T, completion: @escaping NetworkCompletion)
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
    
    var headers: [String: String] {
        return [:]
    }
    
    func path<T: Record>(for type: T.Type) -> String {
        return String(describing: type).lowercased().pluralize()
    }
    
    func url<T: Record>(for type: T.Type, requestType: RequestType) -> URL {
        return URL(scheme: scheme, host: host, path: path(for: type), requestType: requestType)
    }
    
    func request(for url: URL, method: HTTPMethod<Any>) -> URLRequest {
        return URLRequest(url: url, method: method, headers: headers)
    }
    
    func requestForFind<T: Record>(all type: T.Type) -> URLRequest {
        return request(for: urlForFind(all: type), method: .get)
    }
    
    func requestForFind<T: Record>(record type: T.Type, id: ID) -> URLRequest {
        return request(for: urlForFind(all: type), method: .get)
    }
    
    func requestForCreate<T: Record>(record: T, type: T.Type) -> URLRequest {
        return request(for: urlForFind(all: type), method: .post(record))
    }
    
    func urlForFind<T: Record>(all type: T.Type) -> URL {
        return url(for: type, requestType: .findAll)
    }
    
    func urlForFind<T: Record>(record type: T.Type, id: ID) -> URL {
        return url(for: type, requestType: .find(record: id))
    }
    
    func urlForCreate<T: Record>(record: T, type: T.Type) -> URL {
        return url(for: type, requestType: .create(record: record))
    }
    
    func find<T: Record>(record type: T.Type, id: ID, completion: @escaping NetworkCompletion) {
        let _request = request(for: urlForFind(record: type, id: id), method: .get)
        return client.load(request: _request, completion: completion)
    }
    
    func find<T: Record>(all type: T.Type, completion: @escaping NetworkCompletion) {
        let _request = request(for: urlForFind(all: type), method: .get)
        return client.load(request: _request, completion: completion)
    }
    
    func create<T: Record>(record: T, completion: @escaping NetworkCompletion) {
        let type = type(of: record)
        let hash = Store.sharedStore.serializer(for: type).serialize(record: record, includeId: false)
        let _request = request(for: urlForCreate(record: record, type: type), method: .post(hash))
        return client.load(request: _request, completion: completion)
    }
}

public struct JSONAdapter: AdapterType {
    
    public init() {}
    
}
