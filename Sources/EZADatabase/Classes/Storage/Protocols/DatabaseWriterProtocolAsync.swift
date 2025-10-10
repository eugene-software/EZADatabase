//
//  DatabaseWriterProtocolCombine.swift
//  EZADatabase
//
//  Created by Eugeniy Zaychenko on 09.10.2025.
//


import Foundation
import Combine

public protocol DatabaseWriterProtocolAsync {

    associatedtype WriteType: CoreDataCompatible

    /// Efficiently removes all objects by entity name from the database.
    ///
    /// - Parameters:
    ///   - entity: Object type to be deleted from database
    ///   - predicate: predicate for searching existing object and delete it
    /// - Returns: An empty promise when the work is finished
    ///
    @discardableResult
    static func deleteEntities(_ entity: WriteType.Type, predicate: NSPredicate?) async throws

    /// Efficiently saves Updatable object list to the database.
    ///
    /// - Parameters:
    ///   - objectToImport: Object to be imported to database
    /// - Returns: An empty promise when the work is finished
    ///
    @discardableResult
    static func updateRemote(_ objectToImport: WriteType?, predicate: NSPredicate?) async throws

    /// Efficiently saves Updatable object list to the database.
    ///
    /// - Parameters:
    ///   - objectsToImport: Objects to be imported to database
    /// - Returns: An empty promise when the work is finished
    ///
    @discardableResult
    static func importRemoteList(_ objectsToImport: [WriteType?]) async throws

    /// Efficiently imports particular values for object by predicate and type
    ///
    /// - Parameters:
    ///   - entity: Type of objects in DB (table)
    ///   - predicate: Predicate for search
    ///   - values: Values to be updated for found objects
    /// - Returns: An empty promise when the work is finished
    ///
    @discardableResult
    static func importValues(_ entity: WriteType.Type, predicate: NSPredicate?, values: [String: Any]) async throws
}
