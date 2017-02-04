//
//  StoreTests.swift
//  SwiftDataStore
//
//  Created by Ahmed Onawale on 2/4/17.
//  Copyright © 2017 Ahmed Onawale. All rights reserved.
//

import Quick
import Nimble
@testable import SwiftDataStore

class StoreTests: SwiftDataStoreTests {
    override func spec() {
        describe("find resource: - `User`") {
            var user: User?
            var users: [User]?
            var error: Error?
            
            beforeEach {
                // reset to default values
                user = nil
                users = nil
                error = nil
            }
            
            afterEach {
                // remove all records in the store
                self.store.unload(all: User.self)
            }
            
            context("when the request is successful") {
                it("finds all users") {
                    self.store.find(all: User.self) { users = $0; error = $1 }
                    expect(error).toEventually(beNil())
                    expect(users).toEventually(haveCount(3))
                }
                
                it("finds one user with id") {
                    self.store.find(record: User.self, id: ID(2)) { user = $0; error = $1 }
                    expect(error).toEventually(beNil())
                    expect(user).toEventuallyNot(beNil())
                    expect(user?.id).toEventually(equal(ID(2)))
                    expect(user?.email).toEventually(beNil())
                }
            }
            
            context("when the request fails") {
                it("returns status 404 with custom error when message resource is not found") {
                    self.store.find(record: User.self, id: ID(9)) { user = $0; error = $1 }
                    expect(error).toEventuallyNot(beNil())
                    expect(user).toEventually(beNil())
                    expect(error).toEventually(matchError(ServiceError.custom("Not Found")))
                }
            }
        }
        
        describe("Peek resource - `User`") {
            context("When the record is loaded in the store") {
                beforeEach {
                    // preload users into the store
                    waitUntil() { done in
                        self.store.find(all: User.self) { _ in done() }
                    }
                }
                afterEach {
                    self.store.unload(all: User.self)
                }
                it("peeks a record in the store") {
                    let user = self.store.peek(record: User.self, id: ID(3))
                    expect(user).toNot(beNil())
                    expect(user?.id).toEventually(equal(ID(3)))
                }
                
                it("peeks all records in the store") {
                    let users = self.store.peek(all: User.self)
                    expect(users).to(haveCount(3))
                }
            }
            context("When the store has no records") {
                it("returns nil") {
                    let user = self.store.peek(record: User.self, id: ID(3))
                    expect(user).to(beNil())
                }
                
                it("returns empty array") {
                    let users = self.store.peek(all: User.self)
                    expect(users).to(beEmpty())
                }
            }
        }
    }
}
