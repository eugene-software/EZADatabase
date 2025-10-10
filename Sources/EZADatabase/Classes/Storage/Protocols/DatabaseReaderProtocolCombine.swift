//
//  DatabaseReaderProtocolCombine.swift
//  EZADatabase
//
//  Created by Eugeniy Zaychenko on 09.10.2025.
//

import Foundation
import Combine

public protocol DatabaseReaderProtocolCombine {
    
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


public extension DatabaseReaderProtocolCombine {

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
