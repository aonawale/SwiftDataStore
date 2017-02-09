//
//  WebClient.swift
//  SwiftDataStore
//
//  Created by Ahmed Onawale on 2/4/17.
//  Copyright © 2017 Ahmed Onawale. All rights reserved.
//

import Reachability

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

public protocol NetworkType {
    var baseURL: String { get }
    init(baseUrl: String)
    func load(url: URL, method: HTTPMethod, params: JSON, headers: [String: String], completion: @escaping NetworkCompletion)
}

public extension NetworkType {
    func load(url: URL, method: HTTPMethod, params: JSON = [:], headers: [String: String] = [:], completion: @escaping NetworkCompletion) {
        // Create Reachability instance
        let reachability = Reachability()!
        
        // Checking internet connection availability
        if !reachability.isReachable {
            completion(nil, NetworkError.noInternetConnection)
        }
        
        // Creating the URLRequest object
        let request = URLRequest(url: url, method: method, params: params, headers: headers)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
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
        }.resume()
    }
}

public struct WebClient: NetworkType {
    public var baseURL: String
    
    public init(baseUrl: String) {
        self.baseURL = baseUrl
    }
}

public extension URL {
    init(scheme: String = "https", host: String, path: String = "/", params: JSON = [:]) {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.path = path.hasPrefix("/") ? path : "/" + path
        components.queryItems = params.map {
            URLQueryItem(name: $0.key, value: String(describing: $0.value))
        }
        self = components.url!
    }
}

public extension URLRequest {
    init(url: URL, method: HTTPMethod, params: JSON, headers: [String: String]) {
        self.init(url: url)
        httpMethod = method.rawValue
        allHTTPHeaderFields = headers
        switch method {
        case .post, .put:
            httpBody = try! JSONSerialization.data(withJSONObject: params, options: [])
        default:
            break
        }
    }
}
