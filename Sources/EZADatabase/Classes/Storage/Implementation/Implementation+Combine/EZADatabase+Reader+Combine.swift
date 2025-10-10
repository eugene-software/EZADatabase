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


extension EZADatabase: DatabaseReaderProtocolCombine where T: CoreDataCompatible {

    public typealias ReadType = T
    private typealias Reader = CoreDataReader

    public static func exportRemoteSingle(predicate: NSPredicate?, sort: [NSSortDescriptor]?) -> ReadType? {
        return Reader<ReadType>.exportRemoteSingle(predicate: predicate, sort: sort)
    }
    
    public static func exportRemote(predicate: NSPredicate?, sort: [NSSortDescriptor]?) -> AnyPublisher<ReadType?, Error> {
        return Reader<ReadType>.exportRemote(predicate: predicate, sort: sort)
    }
    
    public static func exportRemoteList(predicate: NSPredicate?, sort: [NSSortDescriptor]?) -> AnyPublisher<[ReadType]?, Error> {
        return Reader<ReadType>.exportRemoteList(predicate: predicate, sort: sort)
    }
    
    public static func observe(predicate: NSPredicate?, sort: [NSSortDescriptor]? = nil) -> AnyPublisher<[ReadType], Error> {
        return Reader<ReadType>.observe(predicate: predicate, sort: sort)
    }
    
    public static func fetchedResultsProvider(mainPredicate: NSPredicate,
                                       optionalPredicates: [NSPredicate]?,
                                       sorting sortDescriptors: [NSSortDescriptor],
                                       sectionName: String?,
                                       fetchLimit: Int?) -> FetchedResultsProvider<ReadType>?
    {
        return Reader<ReadType>.fetchedResultsProvider(mainPredicate: mainPredicate,
                                                       optionalPredicates: optionalPredicates,
                                                       sorting: sortDescriptors,
                                                       sectionName: sectionName,
                                                       fetchLimit: fetchLimit)
    }
    
    public static func compute(_ type: ReadType.Type, operation: DatabaseReaderComputationOperation, keyPath: String, predicate: NSPredicate) -> Int? {
        return Reader<ReadType>.compute(type, operation: operation, keyPath: keyPath, predicate: predicate)
    }
}
