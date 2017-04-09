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

class SerializerTests: QuickSpec {
    let store = Store.shared
    
    override func spec() {
        describe("JSON Serializer - Resource serialization and normalization") {
            var serializer: JSONSerializer!
            
            context("when passed a valid Record instance") {
                beforeEach {
                    serializer = JSONSerializer()
                }
                
                it("serializes single record") {
                    let snapshot = Snapshot(record: User(id: 1, name: "Foo"))
                    let serialzed = serializer.serialize(record: snapshot, options: [])
                    expect(serialzed).toNot(beNil())
                }
                
                it("serializes record array") {
                    let snapshots = [User(id: 1, name: "Foo"), User(id: 2, name: "Bar")].map { Snapshot(record: $0) }
                    let serialzed = serializer.serialize(records: snapshots, options: [])
                    expect(serialzed).to(haveCount(2))
                }
                
                it("normalizes single record") {
                    let record = try? serializer.normalize(type: User.self, hash: ["id":"1", "email": "foo@bar.com", "name": "foo"])
                    expect(record).notTo(beNil())
                }
                
                it("normalizes record array") {
                    let record = try? serializer.normalize(type: User.self, hash: [["id":"2", "name": "foo"], ["id":"3", "name": "Boo"]])
                    expect(record).to(haveCount(2))
                }
            }
            
            context("when passed an invalid JSON object") {
                beforeEach {
                    serializer = JSONSerializer()
                }
                
                it("throws requires id error") {
                    let json = ["email": "foo@bar.com", "name": "foo"]
                    expect{ try serializer.normalize(type: User.self, hash: json) }.to(throwError { error in
                        expect(error).to(matchError(SerializerError.requiresID))
                    })
                }
                
                it("throws missing key error") {
                    let json = ["id": "1", "email": "foo@bar.com"]
                    expect{ try serializer.normalize(type: User.self, hash: json) }.to(throwError { error in
                        expect(error).to(matchError(ModelError.invalid(key: "name", expected: "")))
                    })
                }
            }
        }
    }
}
