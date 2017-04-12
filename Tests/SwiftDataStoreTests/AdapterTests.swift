//
//  AdapterTests.swift
//  SwiftDataStore
//
//  Created by Ahmed Onawale on 2/4/17.
//  Copyright © 2017 Ahmed Onawale. All rights reserved.
//

import Quick
import Nimble
import OHHTTPStubs
@testable import SwiftDataStore

class AdapterTests: QuickSpec {
    let store = Store.shared
    
    override func spec() {
        describe("Adapter tests") {
            var data: Data?
            var error: Error?
            var adapter: AuthorAdapter!
            
            beforeEach {
                // reset to default values
                data = nil
                error = nil
                adapter = AuthorAdapter()
            }
            
            context("when adapter request is successful") {
                it("creates a resource") {
                    Mock.User.one(id: "1", condition: isMethodPOST())
                    let user = User(name: "Foo")
                    let snapshot = Snapshot(record: user)
                    adapter.create(type: User.self, store: self.store, snapshot: snapshot) { data = $0; error = $1 }
                    expect(error).toEventually(beNil())
                    expect(data).toEventuallyNot(beNil())
                }
                
                it("finds all resources") {
                    Mock.User.index()
                    adapter.find(all: User.self, store: self.store, snapshot: Snapshot()) { data = $0; error = $1 }
                    expect(error).toEventually(beNil())
                    expect(data).toEventuallyNot(beNil())
                }
                
                it("finds a resource") {
                    Mock.User.one(id: "1")
                    adapter.find(type: User.self, id: ID(1), store: self.store, snapshot: Snapshot()) { data = $0; error = $1 }
                    expect(error).toEventually(beNil())
                    expect(data).toEventuallyNot(beNil())
                }
            }
            
            context("when adapter request fails") {
                it("returns the specific Adapter error for the response statusCode") {
                    Mock.response(statusCode: 401)
                    adapter.find(all: User.self, store: self.store, snapshot: Snapshot()) { error = $1 }
                    expect(error).toEventually(matchError(AdapterError.unauthorized))
                    
                    Mock.response(statusCode: 403)
                    adapter.find(all: User.self, store: self.store, snapshot: Snapshot()) { error = $1 }
                    expect(error).toEventually(matchError(AdapterError.forbidden))
                    
                    Mock.response(statusCode: 404)
                    adapter.find(all: User.self, store: self.store, snapshot: Snapshot()) { error = $1 }
                    expect(error).toEventually(matchError(AdapterError.notFound))
                    
                    Mock.response(statusCode: 408)
                    adapter.find(all: User.self, store: self.store, snapshot: Snapshot()) { error = $1 }
                    expect(error).toEventually(matchError(AdapterError.timeout))
                    
                    Mock.response(statusCode: 409)
                    adapter.find(all: User.self, store: self.store, snapshot: Snapshot()) { error = $1 }
                    expect(error).toEventually(matchError(AdapterError.conflict))
                    
                    Mock.response(statusCode: 422)
                    adapter.find(all: User.self, store: self.store, snapshot: Snapshot()) { error = $1 }
                    expect(error).toEventually(matchError(AdapterError.invalid))
                    
                    Mock.response(statusCode: 500)
                    adapter.find(all: User.self, store: self.store, snapshot: Snapshot()) { error = $1 }
                    expect(error).toEventually(matchError(AdapterError.server))
                    
                    Mock.response(statusCode: 800)
                    adapter.find(all: User.self, store: self.store, snapshot: Snapshot()) { error = $1 }
                    expect(error).toEventually(matchError(AdapterError.unknown))
                }
            }
        }
    }
}
