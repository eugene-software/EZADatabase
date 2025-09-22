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

public enum DatabaseReaderComputationOperation: String {
    
    case min = "min:"
    case max = "max:"
    case average = "average:"
}

public protocol DatabaseReaderProtocol {
    
    associatedtype ReadType: CoreDataCompatible
    
    /// Efficiently exports Updatable object from the database.
    ///
    /// - Parameters:
    ///   - type: Type of object
    ///   - predicate: predicate for searching
    /// - Returns: A promise with object when the work is finished
    ///
    @discardableResult
    static func exportRemote(predicate: NSPredicate?, sort: [NSSortDescriptor]?) -> AnyPublisher<ReadType?, Error>
    
    /// Efficiently exports Updatable object from the database.
    ///
    /// - Parameters:
    ///   - predicate: predicate for searching
    /// - Returns: A single object
    ///
    @discardableResult
    static func exportRemoteSingle(predicate: NSPredicate?, sort: [NSSortDescriptor]?) -> ReadType?
    
    /// Efficiently exports Updatable objects list from the database.
    ///
    /// - Parameters:
    ///   - type: Type of objects
    ///   - predicate: predicate for searching
    ///   - sort: sort descriptors for ordering
    /// - Returns: A publisher with a list of objects when the work is finished
    ///
    @discardableResult
    static func exportRemoteList(predicate: NSPredicate?, sort: [NSSortDescriptor]?)  -> AnyPublisher<[ReadType]?, Error>
    
    /// Efficiently observes objects updates from the database.
    ///
    /// - Parameters:
    ///   - predicate: predicate for searching
    ///   - sort: sort descriptors for ordering
    /// - Returns: A publisher with a list of objects
    ///
    static func observe(predicate: NSPredicate?, sort: [NSSortDescriptor]?) -> AnyPublisher<[ReadType], Error>
    
    /// Efficiently computes an integer value of table's field.
    ///
    /// - Parameters:
    ///   - type: Type of objects
    ///   - operation: an operation of computation
    ///   - keyPath: a name of field to compute
    ///   - predicate: predicate for searching
    /// - Returns: An integer value of computation
    ///
    @discardableResult
    static func compute(_ type: ReadType.Type, operation: DatabaseReaderComputationOperation, keyPath: String, predicate: NSPredicate) -> Int?
    
    /// FetchedResultsProvider object that efficiently adopts database obejcts to appropriate structures
    ///
    /// - Parameters:
    ///   - type: Type of objects
    ///   - mainPredicate: a main predicate to fetch objects
    ///   - optionalPredicates: Optional predicates for additional filtering
    ///   - sorting: Sort descriptors
    ///   - sectionName: a field for sections
    ///   - fetchLimit: fetch limit for request
    /// - Returns: FetchedResultsProviderInterface object
    ///
    static func fetchedResultsProvider(mainPredicate: NSPredicate,
                                       optionalPredicates: [NSPredicate]?,
                                       sorting sortDescriptors: [NSSortDescriptor],
                                       sectionName: String?,
                                       fetchLimit: Int?) -> FetchedResultsProvider<ReadType>?
}

public extension DatabaseReaderProtocol {
    
    static func exportRemoteSingle(predicate: NSPredicate?, sort: [NSSortDescriptor]? = nil) -> ReadType? {
        return exportRemoteSingle(predicate: predicate, sort: sort)
    }
    
    static func exportRemote(predicate: NSPredicate?, sort: [NSSortDescriptor]? = nil) -> AnyPublisher<ReadType?, Error> {
        return exportRemote(predicate: predicate, sort: sort)
    }
    
    static func exportRemoteList(predicate: NSPredicate?, sort: [NSSortDescriptor]? = nil)  -> AnyPublisher<[ReadType]?, Error> {
        return exportRemoteList(predicate: predicate, sort: sort)
    }
    
    static func observe(predicate: NSPredicate?, sort: [NSSortDescriptor]? = nil) -> AnyPublisher<[ReadType], Error> {
        return observe(predicate: predicate, sort: sort)
    }
}


extension EZADatabase: DatabaseReaderProtocol where T: CoreDataCompatible {

    typealias Reader = CoreDataReader
    public typealias ReadType = T
    
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
