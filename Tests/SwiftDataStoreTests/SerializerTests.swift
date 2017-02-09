//
//  SerializerTests.swift
//  SwiftDataStore
//
//  Created by Ahmed Onawale on 2/4/17.
//  Copyright © 2017 Ahmed Onawale. All rights reserved.
//

import Quick
import Nimble
@testable import SwiftDataStore

class SerializerTests: SwiftDataStoreTests {
    override func spec() {
        describe("User serializer and normalization") {
            context("JSON Serializer") {
                it("serializes single record") {
                    let serializer = JSONSerializer()
                    let serialzed = serializer.serialize(record: User(id: 1, name: "Foo"))
                    expect(serialzed).toNot(beNil())
                }
                
                it("serializes record array") {
                    let serializer = JSONSerializer()
                    let serialzed = serializer.serialize(records: [User(id: 1, name: "Foo"), User(id: 2, name: "Bar")])
                    expect(serialzed).to(haveCount(2))
                }
                
                it("normalizes single record") {
                    let serializer = JSONSerializer()
                    let serialzed = try? serializer.normalize(Type: User.self, hash: ["id":"1", "email": "foo@bar.com", "name": "foo"])
                    expect(serialzed).notTo(beNil())
                }
                
                it("normalizes record array") {
                    let serializer = JSONSerializer()
                    let serialzed = try? serializer.normalize(Type: User.self, hash: [["id":"2", "name": "foo"], ["id":"3", "name": "Boo"]])
                    expect(serialzed).to(haveCount(2))
                }
            }
        }
    }
}
