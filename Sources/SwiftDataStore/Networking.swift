//
//  WebClient.swift
//  SwiftDataStore
//
//  Created by Ahmed Onawale on 2/4/17.
//  Copyright © 2017 Ahmed Onawale. All rights reserved.
//

import Reachability

public enum HTTPMethod<Body> {
    case get
    case post(Body)
    case put(Body)
    case patch(Body)
    case delete
}

extension HTTPMethod {
    var name: String {
        switch self {
        case .get:
            return "GET"
        case .post:
            return "POST"
        case .put:
            return "PUT"
        case .patch:
            return "PATCH"
        case .delete:
            return "DELETE"
        }
    }
}

public protocol WebClientProtocol {
    func load(request: URLRequest, completion: @escaping NetworkCompletion) -> URLSessionDataTask
}

public protocol NetworkType {
    var baseURL: String { get }
    init(baseUrl: String)
    func load(request: URLRequest, completion: @escaping NetworkCompletion) -> URLSessionDataTask
}

public extension NetworkType {
    @discardableResult func load(request: URLRequest, completion: @escaping NetworkCompletion) -> URLSessionDataTask {
        // Create Reachability instance
        let reachability = Reachability()!
        
        // Checking internet connection availability
        if !reachability.isReachable {
            completion(nil, NetworkError.noInternetConnection)
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // make sure there is no error
            guard error == nil else { return completion(nil, error) }
            
            // make sure we have a valid response
            guard let response = response as? HTTPURLResponse else { return completion(nil, NetworkError.badResponse) }
            
            var object: Any? = nil
            
            // Parsing incoming data
            if let data = data {
                object = try? JSONSerialization.jsonObject(with: data, options: [])
            }
            
            // Check for valid status code response
            if (200..<300) ~= response.statusCode {
                completion(object, nil)
            } else {
                let errorMessage = HTTPURLResponse.localizedString(forStatusCode: response.statusCode)
                completion(nil, NetworkError.other(errorMessage))
            }
        }
        task.resume()
        return task
    }
}

public struct WebClient: NetworkType {
    public var baseURL: String
    
    public init(baseUrl: String) {
        self.baseURL = baseUrl
    }
}

public extension URL {
    init(scheme: Scheme = .https, host: String, path: String = "/", request: Request) {
        var components = URLComponents()
        components.scheme = scheme.description
        components.host = host
        var _path = "/\(path.remove(leading: "/", trailing: "/").trim())"
        switch request {
        case .find(record: let id):
            _path = "\(_path)/\(id.value)"
        case .query(let query), .queryRecord(let query):
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        default:
            break
        }
        components.path = _path

        self = components.url!
    }
}

public extension URLRequest {
    init(url: URL, method: HTTPMethod<Any>, headers: [String: String]) {
        self.init(url: url)
        httpMethod = method.name
        allHTTPHeaderFields = headers
        switch method {
        case .post(let body as JSON), .put(let body as JSON), .patch(let body as JSON):
            httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        case .post(let body as [Any]), .put(let body as [Any]), .patch(let body as [Any]):
            httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        default:
            break
        }
    }
}
