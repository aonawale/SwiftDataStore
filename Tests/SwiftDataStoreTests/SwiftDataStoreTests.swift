//
//  SwiftDataStoreTests.swift
//  SwiftDataStoreTests
//
//  Created by Ahmed Onawale on 2/4/17.
//  Copyright © 2017 Ahmed Onawale. All rights reserved.
//

import Quick
import OHHTTPStubs
@testable import SwiftDataStore

struct AuthorAdapter: AdapterType {
    var host: String {
        return "jsonplaceholder.typicode.com"
    }
}

struct User: Record {
    let id: ID
    let name: String
    let email: String?
    
    init(id: ID, hash: JSON) {
        self.id = id
        name = hash["name"] as! String
        email = hash["email"] as? String
    }
    
    init(id: Int, name: String) {
        self.id = ID(id)
        self.name = name
        self.email = nil
    }
    
    static var adapterClass: AdapterType.Type {
        return AuthorAdapter.self
    }
}

struct Post: Record {
    let id: ID
    let title: String
    let body: String?
    
    init(id: ID, hash: JSON) {
        self.id = id
        title = hash["title"] as! String
        body = hash["body"] as? String
    }
    
    init(id: Int, title: String) {
        self.id = ID(id)
        self.title = title
        self.body = nil
    }
    
    static var adapterClass: AdapterType.Type {
        return AuthorAdapter.self
    }
}

class SwiftDataStoreTests: QuickSpec {
    
    let store = Store.sharedStore
    
    override func spec() {
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
            
            /*
                OHHTTPStubs limitation
                OHHTTPStubs don't simulate data upload. The NSURLProtocolClient @protocol does
                not provide a way to signal the delegate that data has been sent (only that some
                has been loaded), so any data in the HTTPBody or HTTPBodyStream of an NSURLRequest,
                or data provided to -[NSURLSession uploadTaskWithRequest:fromData:]; will be
                ignored, and more importantly, the 
                -URLSession:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend: 
                delegate method will never be called when you stub the request using OHHTTPStubs
            */
            // Because of this limitation, we'll assume all POST request is a success
            stub(condition: isHost("jsonplaceholder.typicode.com") && isMethodPOST()) { req in
                let user = ["id":"1", "email": "foo@bar.com", "name": "foo"]
                let data = try! JSONSerialization.data(withJSONObject: user, options: [])
                return OHHTTPStubsResponse(data: data, statusCode: 200, headers: nil)
            }
        }
    }
}
