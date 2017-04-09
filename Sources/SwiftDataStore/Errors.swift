//
//  Errors.swift
//  SwiftDataStore
//
//  Created by Ahmed Onawale on 2/5/17.
//  Copyright © 2017 Ahmed Onawale. All rights reserved.
//

public enum AdapterError: Int, Error {
    case unauthorized = 401
    case forbidden = 403
    case notFound = 404
    case timeout = 408
    case conflict = 409
    case invalid = 422
    case server = 500
    
    case abort
    case badResponse
    case unknown
    
    init(_ code: Int) {
        if let error = AdapterError(rawValue: code) {
            self = error
        } else {
            self = .unknown
        }
    }
}

public enum SerializerError: Error {
    case requiresID
    case invalidJSON
}

extension SerializerError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .requiresID:
            return "Requires id"
        case .invalidJSON:
            return "Invalid JSON"
        }
    }
}
