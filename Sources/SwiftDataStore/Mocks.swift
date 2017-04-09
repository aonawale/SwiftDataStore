//
//  Mocks.swift
//  SwiftDataStore
//
//  Created by Ahmed Onawale on 4/9/17.
//  Copyright © 2017 Ahmed Onawale. All rights reserved.
//

import OHHTTPStubs
@testable import SwiftDataStore

final class Mock {
    struct User {
        static func index() {
            stub(condition: isMethodGET()) { req in
                let json = [["id":"1", "email": "foo@bar.com", "name": "foo"],
                            ["id":"2", "name": "foo"], ["id":"3", "name": "foo"]]
                return Mock.response(for: json)
            }
        }
        
        static func one(id: String, condition: @escaping OHHTTPStubsTestBlock = isMethodGET()) {
            stub(condition: condition) { req in
                return Mock.response(for: ["id": id, "email": "foo@bar.com", "name": "foo"])
            }
        }
        
        static func notFound() {
            stub(condition: isMethodGET()) { req in
                return Mock.response(for: ["message": "Not Found"], statusCode: 404)
            }
        }
    }
    
    static func response(body: Any = [:], statusCode: Int32, condition: @escaping OHHTTPStubsTestBlock = isMethodGET()) {
        stub(condition: condition) { req in
            return response(for: body, statusCode: statusCode)
        }
    }
    
    private static func response(for json: Any, statusCode: Int32 = 200) -> OHHTTPStubsResponse {
        let data = try! JSONSerialization.data(withJSONObject: json, options: [])
        return OHHTTPStubsResponse(data: data, statusCode: statusCode, headers: nil)
    }
}
