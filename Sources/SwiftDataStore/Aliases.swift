//
//  Aliases.swift
//  SwiftDataStore
//
//  Created by Ahmed Onawale on 2/5/17.
//  Copyright © 2017 Ahmed Onawale. All rights reserved.
//

public typealias Host = String
public typealias Namespace = String
public typealias PrimaryKey = String
public typealias JSON = [String: Any]
public typealias Query = [String: String]
public typealias Headers = [String: String]
public typealias AnyHashableJSON = [AnyHashable: Any]
public typealias DataCompletion = (Data?, Error?) -> Void
public typealias DataTaskCompletion = (Data?, URLResponse?, Error?) -> Void
