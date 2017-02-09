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
            var users: RecordArray<User>?
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
                    expect(error).toEventually(matchError(NetworkError.other("not found")))
                }
            }
        }
        
        describe("Peek resource - `User`") {
            context("when the record is loaded in the store") {
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
            context("when the store has no records") {
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
        
        describe("loading and unloading resources - `User`") {
            afterEach {
                self.store.unload(all: User.self)
            }
            
            it("push a record into the store") {
                let user = self.store.push(record: User(id: 1, name: "Foo"))
                expect(user).toNot(beNil())
                expect(user.id).toEventually(equal(ID(1)))
            }
            
            it("push multiple records into the store") {
                let users = self.store.push(records: [User(id: 1, name: "Foo"), User(id: 2, name: "Boo")])
                expect(users).to(haveCount(2))
            }
            
            it("unloads all record Type") {
                let records: [Model] = [User(id: 3, name: "Baz"), User(id: 4, name: "Foo"), Post(id: 1, title: "Bar")]
                self.store.push(records: records)
                expect(self.store.peek(all: User.self)).to(haveCount(3))
            }
            
            context("does not duplicate records with the same id") {
                it("when pushing records multiple times") {
                    self.store.push(record: User(id: 1, name: "Foo"))
                    self.store.push(record: User(id: 1, name: "Bar"))
                    self.store.push(record: User(id: 1, name: "Baz"))
                    let users = self.store.peek(all: User.self)
                    expect(users).to(haveCount(1))
                    expect(users.first?.name).to(equal("Baz"))
                }
                
                it("when pushing mutiple records at once") {
                    self.store.push(records: [User(id: 1, name: "Baz"), User(id: 4, name: "Foo"), User(id: 1, name: "Bar")])
                    let users = self.store.peek(all: User.self)
                    expect(users).to(haveCount(2))
                    expect(self.store.peek(record: User.self, id: ID(1))?.name).to(equal("Bar"))
                }
            }
            
            
        }
    }
}
