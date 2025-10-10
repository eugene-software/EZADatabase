//
//  DatabaseReaderProtocolCombine.swift
//  EZADatabase
//
//  Created by Eugeniy Zaychenko on 09.10.2025.
//

import Foundation
import Combine

public protocol DatabaseReaderProtocolAsync {

    associatedtype ReadType: CoreDataCompatible

    /// Efficiently exports Updatable object from the database.
    ///
    /// - Parameters:
    ///   - type: Type of object
    ///   - predicate: predicate for searching
    /// - Returns: A promise with object when the work is finished
    ///
    @discardableResult
    static func exportRemote(predicate: NSPredicate?, sort: [NSSortDescriptor]?) async throws -> ReadType?

    /// Efficiently exports Updatable objects list from the database.
    ///
    /// - Parameters:
    ///   - type: Type of objects
    ///   - predicate: predicate for searching
    ///   - sort: sort descriptors for ordering
    /// - Returns: A publisher with a list of objects when the work is finished
    ///
    @discardableResult
    static func exportRemoteList(predicate: NSPredicate?, sort: [NSSortDescriptor]?) async throws -> [ReadType]?
}


public extension DatabaseReaderProtocolAsync {

    static func exportRemote(predicate: NSPredicate?, sort: [NSSortDescriptor]? = nil) async throws -> ReadType? {
        return try await exportRemote(predicate: predicate, sort: sort)
    }

    static func exportRemoteList(predicate: NSPredicate?, sort: [NSSortDescriptor]? = nil)  async throws -> [ReadType]? {
        return try await exportRemoteList(predicate: predicate, sort: sort)
    }
}
