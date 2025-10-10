//
//  EZADatabase+Reader.swift
//  EZADatabase
//
//  Created by Eugene Software on 11/15/21.
//
//  Copyright (c) 2022 Eugene Software
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation
import Combine


extension EZADatabase: DatabaseReaderProtocolAsync where T: CoreDataCompatible {

    public typealias ReadTypeAsync = T
    private typealias Reader = CoreDataReader

    public static func exportRemote(predicate: NSPredicate?, sort: [NSSortDescriptor]?) async throws -> ReadTypeAsync? {
        return try await Reader<ReadTypeAsync>.exportRemote(predicate: predicate, sort: sort)
    }
    
    public static func exportRemoteList(predicate: NSPredicate?, sort: [NSSortDescriptor]?) async throws -> [ReadTypeAsync]? {
        return try await Reader<ReadTypeAsync>.exportRemoteList(predicate: predicate, sort: sort)
    }
}
