//
//  Snapshot.swift
//  SwiftDataStore
//
//  Created by Ahmed Onawale on 2/5/17.
//  Copyright © 2017 Ahmed Onawale. All rights reserved.
//

public struct Snapshot {
    let record: Record?
    let adapterOptions: AnyHashableJSON
    
    var id: ID? {
        return record?.id
    }
    
    func json() -> JSON? {
        return record?.toJSON()
    }
    
    init(record: Record? = nil, adapterOptions: AnyHashableJSON = AnyHashableJSON()) {
        self.record = record
        self.adapterOptions = adapterOptions
    }
}
