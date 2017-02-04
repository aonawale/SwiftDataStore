//
//  StoreTests.swift
//  SwiftDataStore
//
//  Created by Ahmed Onawale on 2/4/17.
//  Copyright © 2017 Ahmed Onawale. All rights reserved.
//

import Quick
import Nimble
import OHHTTPStubs
@testable import SwiftDataStore

class StoreTests: SwiftDataStoreTests {
    override func spec() {
        describe("Find resource: - `User`") {
            
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
            
            beforeSuite {
                // Stub HTTP GET requests for `jsonplaceholder.typicode.com`
                stub(condition: isHost("jsonplaceholder.typicode.com") && isMethodGET()) { req in
                    let users = [["id":"1", "email": "foo@bar.com", "name": "foo"], ["id":"2", "name": "foo"], ["id":"3", "name": "foo"]]
                    // can the last path component be converted to an Int?
                    // if yes, the request is a find record with id
                    if let path = req.url?.lastPathComponent, let id = Int(path) {
                        if let response = users.first(where: { $0["id"] == "\(id)"}) {
                            let data = try! JSONSerialization.data(withJSONObject: response, options: .prettyPrinted)
                            return OHHTTPStubsResponse(data: data, statusCode: 200, headers: nil)
                        } else {
                            let data = try! JSONSerialization.data(withJSONObject: ["message": "Not Found"], options: .prettyPrinted)
                            return OHHTTPStubsResponse(data: data, statusCode: 404, headers: nil)
                        }
                    } else {
                        let data = try! JSONSerialization.data(withJSONObject: users, options: .prettyPrinted)
                        return OHHTTPStubsResponse(data: data, statusCode: 200, headers: nil)
                    }
                }
            }
            
            it("Finds all users") {
                self.store.find(all: User.self) { users = $0; error = $1 }
                expect(error).toEventually(beNil())
                expect(users).toEventually(haveCount(3))
            }
            
            it("Finds one user with id") {
                self.store.find(record: User.self, id: ID(2)) { user = $0; error = $1 }
                expect(error).toEventually(beNil())
                expect(user).toEventuallyNot(beNil())
                expect(user?.id).toEventually(equal(ID(2)))
                expect(user?.email).toEventually(beNil())
            }
            
            it("Returns status 404 with custom error when message resource is not found") {
                self.store.find(record: User.self, id: ID(9)) { user = $0; error = $1 }
                expect(error).toEventuallyNot(beNil())
                expect(user).toEventually(beNil())
                expect(error).toEventually(matchError(ServiceError.custom("Not Found")))
            }
            
            it("Peeks a record in the store") {
                self.store.find(all: User.self) { users = $0; error = $1 }
                let user = self.store.peek(record: User.self, id: ID(3))
                expect(user).toEventuallyNot(beNil())
                expect(user?.id).toEventually(equal(ID(3)))
                expect(user?.name).toEventually(equal("Foo"))
            }
        }
    }
}
