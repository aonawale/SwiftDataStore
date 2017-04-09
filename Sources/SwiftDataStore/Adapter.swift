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

public enum Request {
    case findAll
    case find(ID)
    case query(Query)
    case queryRecord(Query)
    case create
    case update(ID)
    case delete(ID)
}

extension Request {
    /// The method type of this request
    var method: HTTPMethod {
        switch self {
        case .create:
            return .post
        case .update:
            return .put
        case .delete:
            return .delete
        default:
            return .get
        }
    }
}

public protocol Adapter: Cacheable {
    var host: Host { get }
    var namespace: Namespace { get }
    var headers: Headers { get }
    var cachePolicy: URLRequest.CachePolicy { get }
    var timeoutInterval: TimeInterval { get }
    var client: NetworkProtocol { get }
    
    func isSuccess(response: HTTPURLResponse, data: Data) -> Bool
    func isInvalid(response: HTTPURLResponse, data: Data) -> Bool
    
    func method(for request: Request) -> HTTPMethod
    func headers(for request: Request) -> Headers
    func path<T: Record>(for Type: T.Type) -> String
    func data<T: Record>(for request: Request, store: Store, type: T.Type, snapshot: Snapshot) throws -> Data?
    
    func handle(response: URLResponse?, data: Data?, error: Error?) throws -> Data
    
    func urlFor<T: Record>(findAll type: T.Type, snapshot: Snapshot) throws -> URL
    func urlFor<T: Record>(find type: T.Type, id: ID) throws -> URL
    func urlFor<T: Record>(create type: T.Type, snapshot: Snapshot) throws -> URL
    
    func requestFor<T: Record>(create type: T.Type, store: Store, snapshot: Snapshot) throws -> URLRequest
    func requestFor<T: Record>(findAll type: T.Type, store: Store, snapshot: Snapshot) throws -> URLRequest
    
    func find<T: Record>(type: T.Type, id: ID, store: Store, snapshot: Snapshot, completion: @escaping DataCompletion) -> URLSessionDataTask?
    func find<T: Record>(all type: T.Type, store: Store, snapshot: Snapshot, completion: @escaping DataCompletion) -> URLSessionDataTask?
    func create<T: Record>(type: T.Type, store: Store, snapshot: Snapshot, completion: @escaping DataCompletion) -> URLSessionDataTask?
}

public extension Adapter {
    var scheme: Scheme {
        return .https
    }
    
    var namespace: Namespace {
        return ""
    }
    
    var cachePolicy: URLRequest.CachePolicy {
        return .useProtocolCachePolicy
    }
    
    var timeoutInterval: TimeInterval {
        return 60.0
    }
    
    var headers: Headers {
        return [
            "Accept": "application/json",
            "Content-Type": "application/json"
        ]
    }
    
    func path<T: Record>(for type: T.Type) -> String {
        return String(describing: type).lowercased().pluralize()
    }
    
    func method(for request: Request) -> HTTPMethod {
        return request.method
    }
    
    func headers(for request: Request) -> Headers {
        return headers
    }
    
    func data<T: Record>(for request: Request, store: Store, type: T.Type, snapshot: Snapshot) throws -> Data? {
        var hash = JSON()
        let serializer = store.serializer(for: type)
        
        switch request {
        case .create:
            serializer.serialize(into: &hash, snapshot: snapshot, options: [])
            return try serializer.serialize(json: hash)
        case .update(_):
            serializer.serialize(into: &hash, snapshot: snapshot, options: [.includeId])
            return try serializer.serialize(json: hash)
        default:
            return nil
        }
    }
    
    func buildUrl<T: Record>(for request: Request, store: Store, type: T.Type, snapshot: Snapshot) throws -> URL {
        switch request {
        case .create:
            return try urlFor(create: type, snapshot: snapshot)
        case .find(let id):
            return try urlFor(find: type, id: id)
        default:
            return try url(for: request, type: type)
        }
    }
    
    private func url<T: Record>(for request: Request, type: T.Type) throws -> URL {
        var paths = [namespace, path(for: type)]
        var components = URLComponents()
        components.scheme = scheme.description
        components.host = host
        switch request {
        case .query(let query), .queryRecord(let query):
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        case .update(let id), .delete(let id), .find(let id):
            paths.append(id.value)
        default:
            break
        }
        components.path = paths.joined(separator: "/")
        guard let url = components.url else { throw AdapterError.url }
        return url
    }
    
    private func request<T: Record>(for type: T.Type, request: Request, store: Store, snapshot: Snapshot) throws -> URLRequest {
        let url = try buildUrl(for: request, store: store, type: type, snapshot: snapshot)
        var urlRequest = URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval)
        urlRequest.allHTTPHeaderFields = headers(for: request)
        urlRequest.httpMethod = method(for: request).name
        urlRequest.httpBody = try data(for: request, store: store, type: type, snapshot: snapshot)
        return urlRequest
    }
    
    func handle(response: URLResponse?, data: Data?, error: Error?) throws -> Data {
        guard let response = response as? HTTPURLResponse,
            let data = data else {
            throw AdapterError.badResponse
        }
        if isSuccess(response: response, data: data) {
            return data
        } else if isInvalid(response: response, data: data) {
            throw AdapterError.invalid
        }
        throw AdapterError(response.statusCode)
    }
    
    func isSuccess(response: HTTPURLResponse, data: Data) -> Bool {
        return 200..<300 ~= response.statusCode || response.statusCode == 304
    }
    
    func isInvalid(response: HTTPURLResponse, data: Data) -> Bool {
        return response.statusCode == 422
    }
    
    // MARK: URLRequests
    func requestFor<T: Record>(findAll type: T.Type, store: Store, snapshot: Snapshot) throws -> URLRequest {
        return try request(for: type, request: .findAll, store: store, snapshot: snapshot)
    }
    
    func requestFor<T: Record>(find type: T.Type, id: ID, store: Store, snapshot: Snapshot) throws -> URLRequest {
        return try request(for: type, request: .find(id), store: store, snapshot: snapshot)
    }
    
    func requestFor<T: Record>(create type: T.Type, store: Store, snapshot: Snapshot) throws -> URLRequest {
        return try request(for: type, request: .create, store: store, snapshot: snapshot)
    }
    
    // MARK: URLs
    func urlFor<T: Record>(findAll type: T.Type, snapshot: Snapshot) throws -> URL {
        return try url(for: .findAll, type: type)
    }
    
    func urlFor<T: Record>(find type: T.Type, id: ID) throws -> URL {
        return try url(for: .find(id), type: type)
    }
    
    func urlFor<T: Record>(create type: T.Type, snapshot: Snapshot) throws -> URL {
        return try url(for: .create, type: type)
    }
    
    func perform(request: URLRequest, completion: @escaping DataCompletion) -> URLSessionDataTask? {
        return client.load(request: request) {
            do {
                let data = try self.handle(response: $1, data: $0, error: $2)
                completion(data, nil)
            } catch {
                completion(nil, error)
            }
        }
    }
    
    // MARK: Adapter methods
    @discardableResult func find<T: Record>(type: T.Type, id: ID, store: Store,
        snapshot: Snapshot, completion: @escaping DataCompletion) -> URLSessionDataTask? {
        do {
            let request = try requestFor(find: type, id: id, store: store, snapshot: snapshot)
            return perform(request: request, completion: completion)
        } catch {
            completion(nil, error)
        }
        return nil
    }
    
    @discardableResult func find<T: Record>(all type: T.Type, store: Store,
        snapshot: Snapshot, completion: @escaping DataCompletion) -> URLSessionDataTask? {
        do {
            let request = try requestFor(findAll: type, store: store, snapshot: snapshot)
            return perform(request: request, completion: completion)
        } catch {
            completion(nil, error)
        }
        return nil
    }
    
    @discardableResult func create<T: Record>(type: T.Type, store: Store,
        snapshot: Snapshot, completion: @escaping DataCompletion) -> URLSessionDataTask? {
        do {
            let request = try requestFor(create: type, store: store, snapshot: snapshot)
            return perform(request: request, completion: completion)
        } catch {
            completion(nil, error)
        }
        return nil
    }
}

public class RESTAdapter: Adapter {
    public var host: Host
    public var client: NetworkProtocol
    
    public required init() {
        client = Ajax()
        host = ""
    }
}
