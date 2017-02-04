//
//  AdapterTests.swift
//  SwiftDataStore
//
//  Created by Ahmed Onawale on 2/4/17.
//  Copyright © 2017 Ahmed Onawale. All rights reserved.
//

import Quick
import Nimble

class AdapterTests: SwiftDataStoreTests {
    override func spec() {
        describe("Adapter tests") {
            var response: Any?
            var error: Error?
            
            beforeEach {
                // reset to default values
                response = nil
                error = nil
            }
            
            it("Create record") {
                let adapter = UserAdapter()
                let user = User(id: ID(1), name: "Foo")
                adapter.create(record: user) { response = $0; error = $1 }
                expect(error).toEventually(beNil())
                expect(response).toNot(beNil())
            }
        }
    }
}
