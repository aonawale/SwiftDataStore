//
//  SwiftDataStoreTests.swift
//  SwiftDataStoreTests
//
//  Created by Ahmed Onawale on 2/4/17.
//  Copyright © 2017 Ahmed Onawale. All rights reserved.
//

@testable import SwiftDataStore

struct AuthorAdapter: Adapter {
    var host: String {
        return "authorsapi.com"
    }
    
    var client: NetworkProtocol = Ajax()
}

enum ModelError: Error {
    case invalid(key: String, expected: String)
    case missing(key: String)
}

struct User: Record {
    let id: ID?
    let name: String
    let email: String?
    
    init(id: ID, hash: JSON) throws {
        self.id = id
        guard let name = hash["name"] as? String else {
            throw ModelError.invalid(key: "name", expected: "\(String.self)")
        }
        self.name = name
        email = hash["email"] as? String
    }
    
    init(id: Int? = nil, name: String) {
        if let id = id {
            self.id = ID(id)
        } else {
            self.id = nil
        }
        self.name = name
        self.email = nil
    }
    
    static var adapterType: Adapter.Type {
        return AuthorAdapter.self
    }
}

struct Post: Record {
    let id: ID?
    let title: String
    let body: String?
    
    init(id: ID, hash: JSON) {
        self.id = id
        title = hash["title"] as! String
        body = hash["body"] as? String
    }
    
    init(id: Int, title: String) {
        self.id = ID(id)
        self.title = title
        self.body = nil
    }
    
    static var adapterClass: Adapter.Type {
        return AuthorAdapter.self
    }
}
