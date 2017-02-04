//
//  SwiftDataStoreTests.swift
//  SwiftDataStoreTests
//
//  Created by Ahmed Onawale on 2/4/17.
//  Copyright © 2017 Ahmed Onawale. All rights reserved.
//

import Quick
@testable import SwiftDataStore

class SwiftDataStoreTests: QuickSpec {
    
    let store = Store.sharedStore
    
    struct UserAdapter: AdapterTest {
        var host: String {
            return "jsonplaceholder.typicode.com"
        }
    }
    
    struct User: Model {
        let id: ID
        let name: String
        let email: String?
        
        init(id: ID, hash: JSON) {
            self.id = id
            name = hash["name"] as! String
            email = hash["email"] as? String
        }
        
        static var adapterClass: AdapterType.Type {
            return UserAdapter.self
        }
    }
    
    override func tearDown() {
        super.tearDown()
        store.unload(all: User.self)
    }
    
}
