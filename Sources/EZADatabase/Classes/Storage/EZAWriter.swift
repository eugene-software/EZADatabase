//
//  AppDatabaseImporter.swift
//  TempProject
//
//  Created Eugene Software on 11/12/21.
//  Copyright © 2021 ___ORGANIZATIONNAME___. All rights reserved.
//
//  This file is generated by custom SKELETON Xcode template.
//

import Foundation
import Combine

public protocol DatabaseWriterProtocol {
    
    associatedtype WriteType
    
    /// Efficiently removes all objects by entity name from the database.
    ///
    /// - Parameters:
    ///   - entity: Object type to be deleted from database
    ///   - predicate: predicate for searching existing object and delete it
    /// - Returns: An empty promise when the work is finished
    ///
    @discardableResult
    static func deleteEntities(_ entity: WriteType.Type, predicate: NSPredicate?) -> AnyPublisher<Void, Error>
    
    /// Efficiently saves Updatable object list to the database.
    ///
    /// - Parameters:
    ///   - objectToImport: Object to be imported to database
    /// - Returns: An empty promise when the work is finished
    ///
    @discardableResult
    static func updateRemote(_ objectToImport: WriteType?, predicate: NSPredicate?) -> AnyPublisher<Void, Error>
    
    /// Efficiently saves Updatable object list to the database.
    ///
    /// - Parameters:
    ///   - objectsToImport: Objects to be imported to database
    /// - Returns: An empty promise when the work is finished
    ///
    @discardableResult
    static func importRemoteList(_ objectsToImport: [WriteType?]) -> AnyPublisher<Void, Error>
    
    /// Efficiently imports particular values for object by predicate and type
    ///
    /// - Parameters:
    ///   - entity: Type of objects in DB (table)
    ///   - predicate: Predicate for search
    ///   - values: Values to be updated for found objects
    /// - Returns: An empty promise when the work is finished
    ///
    @discardableResult
    static func importValues(_ entity: WriteType.Type, predicate: NSPredicate?, values: [String: Any]) -> AnyPublisher<Void, Error>
}


public class EZAWriter<ImportedType: CoreDataCompatible>: DatabaseWriterProtocol {
    
    public typealias WriteType = ImportedType
    typealias Writer = CoreDataWriter
    
    @discardableResult
    public static func deleteEntities(_ entity: WriteType.Type, predicate: NSPredicate?) -> AnyPublisher<Void, Error> {
        return Writer<WriteType>.deleteEntities(entity, predicate: predicate)
    }
    
    @discardableResult
    public static func updateRemote(_ objectToImport: WriteType?, predicate: NSPredicate?) -> AnyPublisher<Void, Error> {
        return Writer<WriteType>.updateRemote(objectToImport, predicate: predicate)
    }
    
    @discardableResult
    public static func importRemoteList(_ objectsToImport: [WriteType?]) -> AnyPublisher<Void, Error> {
        return Writer<WriteType>.importRemoteList(objectsToImport)
    }
    
    @discardableResult
    public static func importValues(_ entity: WriteType.Type, predicate: NSPredicate?, values:  [String: Any]) -> AnyPublisher<Void, Error> {
        return Writer<WriteType>.importValues(entity, predicate: predicate, values: values)
    }
}
