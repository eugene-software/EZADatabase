//
//  CoreDataStorageInterface.swift
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
import CoreData

public protocol CoreDataCompatible: Hashable, Sendable {
    
    associatedtype ManagedType: CoreDataExportable
    
    /// a primary key for managed object to make internal relationships available
    ///
    var primaryKey: Any { get }
    
    /// a primary key name for managed object to make internal relationships available
    ///
    static var primaryKeyName: String { get }
    
    /// Initializes a new external object with DB object
    /// - Parameters:
    ///   - managedObject: an object to be init with
    ///
    init(managedObject: ManagedType)
}


public protocol CoreDataExportable: NSManagedObject {
    
    associatedtype ExportType: CoreDataCompatible
    
    /// Configures core data object with external object
    /// - Parameters:
    ///   - object: an object to be updated with
    ///   - storage: Data storage object to perform additional operations with DB
    ///
    func configure(with object: ExportType, in storage: CoreDataStorageInterface)
    
    /// Gets external object from CoreData object
    ///
    func getObject() -> ExportType
}


// Data storage common methods
//
public protocol CoreDataStorageInterface {
    
    /// Deletes all tables of database excepting a list of passed table names
    /// - Parameter names: table names which should be kept after delete
    /// - Throws: error if deletion fails
    func deleteAllTables(except names: [String]) async throws
    
    /// Sets values to particular objects by NSPredicate
    /// - Parameters:
    ///   - type: A CoreDataCompatible objects list from which a new is to be created/updated
    ///   - values: a key-value dictionary which should be updated
    ///   - predicate: Predicate for search
    func setValues<Type: CoreDataCompatible>(type: Type.Type, values: [String: Any?], predicate: NSPredicate?) async
    
    /// Synchronously insert a new object or updates existing one
    /// - Parameters:
    ///   - object: A CoreDataCompatible object from which a new one is to be created/updated
    ///   - predicate: Predicate for search
    /// - Returns: NSManagedObjectModel custom object related to Type passed in method
    ///
    func insertSync<Type: CoreDataCompatible>(object: Type?, predicate: NSPredicate?) -> Type.ManagedType?
    
    /// Asynchronously inserts a list of new objects or replace existing ones by primary keys
    /// - Parameters:
    ///   - objects: A CoreDataCompatible objects list from which a new is to be created/updated
    func insertList<Type: CoreDataCompatible>(objects: [Type?]) async
    
    /// Asynchronously inserts new objector replace existing one by primary key
    /// - Parameters:
    ///   - object: A CoreDataCompatible object from which a new one is to be created/updated
    ///   - predicate: Predicate for search
    func insertAsync<Type: CoreDataCompatible>(object: Type?, predicate: NSPredicate?) async
    
    /// Synchronously find an object by predicate or returns nil
    /// - Parameters:
    ///   - predicate: a predicate to fetch needed data
    /// - Returns: a NSManagedObjectModel custom object
    ///
    func findRelation<Type: CoreDataExportable>(predicate: NSPredicate?) -> Type?
    
    /// Fetches a list of objects by passed NSPredicate
    /// - Parameters:
    ///   - predicate: a predicate to fetch needed data
    ///   - sortDescriptors: sorting options
    ///   - fetchLimit: limit of objects to fetch
    /// - Returns: a list of NSManagedObjectModel custom objects
    ///
    func list<Type: CoreDataExportable>(predicate: NSPredicate?,
                                         sortDescriptors: [NSSortDescriptor]?,
                                         fetchLimit: Int?) -> [Type]?
    
    /// Asynchronously Fetches a list of objects by passed NSPredicate
    /// - Parameters:
    ///   - predicate: a predicate to fetch needed data
    ///   - sortDescriptors: sorting options
    ///   - fetchLimit: limit of objects to fetch
    func asyncList<Type: CoreDataExportable>(predicate: NSPredicate?,
                                              sortDescriptors: [NSSortDescriptor]?,
                                              fetchLimit: Int?) async -> [Type]?
    
    /// Deletes a list of objects by passed NSPredicate
    /// - Parameters:
    ///   - type: CoreDataCompatible object custom type
    ///   - predicate: a predicate to delete needed data
    func delete<Type: CoreDataExportable>(_ type: Type.Type, with predicate: NSPredicate?) async
    
    /// Computes Integer result
    /// - Parameters:
    ///   - type: CoreDataCompatible object custom type
    ///   - operation: Name of operation
    ///   - keyPath: Keypath for operation, should be a number
    ///   - predicate: a predicate to select needed data
    ///
    func compute<Type: CoreDataExportable>(_ type: Type.Type, operation: String, keyPath: String, predicate: NSPredicate?) -> Int?
    
    /// Gives FetchedResultsProvider object for UI collections
    /// - Parameters:
    ///   - type: CoreDataCompatible object custom type
    ///   - mainPredicate: a predicate for selecting data
    ///   - optionalPredicates: predicates for filtering data.
    ///   - sorting: sort descriptors for sorting
    ///   - sectionName: sections name field for sorting by sections
    ///   - fetchLimit: a limit to fetch
    /// - Returns: a FetchedResultsProviderInterface for UI collections
    ///
    func fetchedResultsProvider<Type: CoreDataCompatible>(mainPredicate: NSPredicate,
                                                          optionalPredicates: [NSPredicate]?,
                                                          sorting sortDescriptors: [NSSortDescriptor],
                                                          sectionName: String?,
                                                          fetchLimit: Int?) -> FetchedResultsProvider<Type>
}

public extension CoreDataStorageInterface {
    
    func insertSync<Type: CoreDataCompatible>(object: Type?, predicate: NSPredicate? = nil) -> Type.ManagedType? {
        return insertSync(object: object, predicate: predicate)
    }
}
