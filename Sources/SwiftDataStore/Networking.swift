//
//  Networking.swift
//  SwiftDataStore
//
//  Created by Ahmed Onawale on 2/4/17.
//  Copyright © 2017 Ahmed Onawale. All rights reserved.
//

import Foundation

public enum Scheme: String {
    case http
    case https
}

extension Scheme: CustomStringConvertible {
    public var description: String {
        return rawValue
    }
}

public enum HTTPMethod: String {
    case get
    case post
    case put
    case patch
    case delete
}

extension HTTPMethod {
    var name: String {
        return rawValue.uppercased()
    }
}

extension HTTPMethod: CustomStringConvertible {
    public var description: String {
        return name
    }
}

public protocol NetworkProtocol {
    func load(request: URLRequest, completion: @escaping DataTaskCompletion) -> URLSessionDataTask?
}

public struct Ajax: NetworkProtocol {
    public func load(request: URLRequest, completion: @escaping DataTaskCompletion) -> URLSessionDataTask? {
        let task = URLSession.shared.dataTask(with: request) { completion($0, $1, $2) }
        task.resume()
        return task
    }
}
