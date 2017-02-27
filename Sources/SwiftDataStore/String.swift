//
//  String.swift
//  SwiftDataStore
//
//  Created by Ahmed Onawale on 2/12/17.
//  Copyright © 2017 Ahmed Onawale. All rights reserved.
//

extension String {
    func remove(trailing char: Character) -> String {
        var string = self
        if characters.count >= 2 && hasSuffix(String(char)) {
            string.remove(at: string.index(before: string.endIndex))
        }
        return string
    }
    
    func remove(leading char: Character) -> String {
        var string = self
        if hasPrefix(String(char)) {
            string.remove(at: string.startIndex)
        }
        return string
    }
    
    func remove(leading lhs: Character, trailing rhs: Character) -> String {
        return remove(leading: lhs).remove(trailing: rhs)
    }
    
    func trim() -> String {
        return trimmingCharacters(in: CharacterSet.whitespaces)
    }
}
