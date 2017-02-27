//
//  Errors.swift
//  SwiftDataStore
//
//  Created by Ahmed Onawale on 2/5/17.
//  Copyright © 2017 Ahmed Onawale. All rights reserved.
//

struct ModelError: Error {
    
}

public enum NetworkError: Error {
    case noInternetConnection
    case badResponse
    case other(String)
}

extension NetworkError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noInternetConnection:
            return "No Internet connection"
        case .badResponse:
            return "Bad response"
        case .other(let message):
            return message
        }
    }
}

public enum SerializerError: Error {
    case requireID
    case invalidJSON
}

extension SerializerError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .requireID:
            return "Requires id"
        case .invalidJSON:
            return "Invalid JSON"
        }
    }
}
