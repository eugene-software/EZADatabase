//
//  EZADatabase+Writer.swift
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


extension EZADatabase: DatabaseWriterProtocol where T: CoreDataCompatible {
    
    public typealias WriteType = T
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

