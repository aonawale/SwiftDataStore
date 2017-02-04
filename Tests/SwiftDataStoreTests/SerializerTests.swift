//
//  SerializerTests.swift
//  SwiftDataStore
//
//  Created by Ahmed Onawale on 2/4/17.
//  Copyright © 2017 Ahmed Onawale. All rights reserved.
//

import Quick
import Nimble

class SerializerTests: SwiftDataStoreTests {
    override func spec() {
        describe("Serializer tests") {
            var response: Any?
            var error: Error?
            
            beforeEach {
                // reset to default values
                response = nil
                error = nil
            }
            
            it("Serializes record") {
                let serializer = JSONSerializer()
                let serialzed = serializer.serialize(record: User(id: ID(1), name: "Foo"))
                expect(serialzed).toNot(beNil())
            }
        }
    }
}
