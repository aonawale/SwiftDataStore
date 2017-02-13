//
//  AdapterTests.swift
//  SwiftDataStore
//
//  Created by Ahmed Onawale on 2/4/17.
//  Copyright © 2017 Ahmed Onawale. All rights reserved.
//

import Quick
import Nimble
@testable import SwiftDataStore

class AdapterTests: SwiftDataStoreTests {
    override func spec() {
        describe("Adapter tests") {
            var response: Any?
            var error: Error?
            var adapter: AuthorAdapter!
            
            beforeEach {
                // reset to default values
                response = nil
                error = nil
                adapter = AuthorAdapter()
            }
            
            context("when adapter request is successful") {
                it("creates a record") {
                    let user = User(id: 1, name: "Foo")
                    adapter.create(record: user) { response = $0; error = $1 }
                    expect(error).toEventually(beNil())
                    expect(response).toEventuallyNot(beNil())
                }
            }
            
            // Ignoring this until I find a way to simulate POST request
            xcontext("when adapter request fails") {
                xit("returns an error") {
                    let user = User(id: 1, name: "Foo")
                    adapter.create(record: user) { response = $0; error = $1 }
                    expect(response).toEventually(beNil())
                    expect(error).notTo(beNil())
                }
            }
        }
    }
}
