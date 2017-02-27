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
        describe("JSON Serializer - Resource serialization and normalization") {
            var serializer: JSONSerializer!
            
            context("when passed a valid JSON object") {
                beforeEach {
                    serializer = JSONSerializer()
                }
                
                it("serializes single record") {
                    let serialzed = serializer.serialize(record: User(id: 1, name: "Foo"))
                    expect(serialzed).toNot(beNil())
                }
                
                it("serializes record array") {
                    let serialzed = serializer.serialize(records: [User(id: 1, name: "Foo"), User(id: 2, name: "Bar")])
                    expect(serialzed).to(haveCount(2))
                }
                
                it("normalizes single record") {
                    let serialzed = try? serializer.normalize(type: User.self, hash: ["id":"1", "email": "foo@bar.com", "name": "foo"])
                    expect(serialzed).notTo(beNil())
                }
                
                it("normalizes record array") {
                    let serialzed = try? serializer.normalize(type: User.self, hash: [["id":"2", "name": "foo"], ["id":"3", "name": "Boo"]])
                    expect(serialzed).to(haveCount(2))
                }
            }
            
            context("when passed an invalid JSON object") {
                beforeEach {
                    serializer = JSONSerializer()
                }
                
                it("throws required id error") {
                    let json = ["email": "foo@bar.com", "name": "foo"]
                    expect{ try serializer.normalize(type: User.self, hash: json) }.to(throwError { error in
                        expect(error).to(matchError(SerializerError.requireID))
                    })
                }
                
                it("throws invalud json error") {
                    let json = ["id": "1", "email": "foo@bar.com"]
                    expect{ try serializer.normalize(type: User.self, hash: json) }.to(throwError { error in
                        expect(error).to(matchError(SerializerError.invalidJSON))
                    })
                }
            }
        }
    }
}
