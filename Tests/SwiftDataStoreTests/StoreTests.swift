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

/// Custome matcher for performing equality on records
public func beUser<T: Record>(_ expectedValue: T?) -> MatcherFunc<T> {
    return MatcherFunc { actualExpression, failureMessage in
        failureMessage.postfixMessage = "equal <\(expectedValue)>"
        guard let actualValue = try actualExpression.evaluate(),
            let expectedValue = expectedValue else { return false }
        return actualValue == expectedValue
    }
}

class StoreTests: SwiftDataStoreTests {
    override func spec() {
        describe("find resource") {
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
        
        describe("Peek records") {
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
        
        describe("loading and unloading records") {
            afterEach {
                self.store.unload(all: User.self)
            }
            
            context("when unloading records") {
                it("unloads all record Type") {
                    let users = [User(id: 3, name: "Baz"), User(id: 4, name: "Foo")]
                    let posts = [Post(id: 2, title: "Blog"), Post(id: 8, title: "Post")]
                    self.store.push(records: users)
                    self.store.push(records: posts)
                    expect(self.store.peek(all: User.self)).to(haveCount(2))
                    expect(self.store.peek(all: Post.self)).to(haveCount(2))
                    self.store.unload(all: User.self)
                    expect(self.store.peek(all: User.self)).to(haveCount(0))
                    expect(self.store.peek(all: Post.self)).to(haveCount(2))
                    self.store.unload(all: Post.self)
                    expect(self.store.peek(all: Post.self)).to(haveCount(0))
                }
                
                it("unloads specified record") {
                    let users = [User(id: 3, name: "Baz"), User(id: 4, name: "Foo")]
                    self.store.push(records: users)
                    expect(self.store.peek(all: User.self)).to(haveCount(2))
                    self.store.unload(record: User(id: 3, name: "Baz"))
                    expect(self.store.peek(all: User.self)).to(haveCount(1))
                }
            }
            
            context("when loading records sequencially") {
                it("push a record into the store") {
                    let user = self.store.push(record: User(id: 1, name: "Foo"))
                    expect(user).toNot(beNil())
                    expect(self.store.peek(all: User.self)).to(haveCount(1))
                }
                
                it("does not duplicate records with the same id") {
                    self.store.push(record: User(id: 1, name: "Foo"))
                    self.store.push(record: User(id: 1, name: "Bar"))
                    self.store.push(record: User(id: 1, name: "Baz"))
                    let users = self.store.peek(all: User.self)
                    expect(users).to(haveCount(1))
                    expect(users.first?.name).to(equal("Baz"))
                }
            }
            
            context("when loading records in batches") {
                it("pushes multiple records into the store") {
                    self.store.push(records: [User(id: 1, name: "Foo"), User(id: 2, name: "Boo")])
                    expect(self.store.peek(all: User.self)).to(haveCount(2))
                }
                
                it("does not duplicate records with the same id") {
                    self.store.push(records: [User(id: 1, name: "Baz"), User(id: 4, name: "Foo"), User(id: 1, name: "Bar")])
                    let users = self.store.peek(all: User.self)
                    expect(users).to(haveCount(2))
                    expect(self.store.peek(record: User.self, id: ID(1))?.name).to(equal("Bar"))
                }
            }
            
            context("when pushing raw JSON data") {
                it("pushes a sngle JSON object") {
                    let json = ["id":"1", "email": "foo@bar.com", "name": "foo"]
                    let user = try? self.store.push(payload: json, for: User.self)
                    expect(user).notTo(beNil())
                    expect(user?.id).to(equal(ID(1)))
                    expect(self.store.peek(record: User.self, id: ID(1))).to(beUser(user))
                }
                
                it("pushes an array of JSON objects") {
                    let json = [["id":"1", "email": "foo@bar.com", "name": "foo"], ["id":"2", "name": "foo"], ["id":"3", "name": "foo"]]
                    let users = try? self.store.push(payload: json, for: User.self)
                    expect(users).to(haveCount(3))
                    expect(self.store.peek(all: User.self)).to(haveCount(3))
                }
            }
            
        }
    }
}
