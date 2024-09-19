//
//  CoreDataReader.swift
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
import Combine

class CoreDataReader<ExportedType> { }

extension CoreDataReader: DatabaseReaderProtocol where ExportedType: CoreDataCompatible {
    
    typealias ReadType = ExportedType
    
    static func exportRemoteSingle(predicate: NSPredicate?, sort: [NSSortDescriptor]?) -> ReadType? {
        
        let controller = CoreDataStorageController.shared
        let objects: [ReadType.ManagedType]? = controller.list(predicate: predicate,
                                                                sortDescriptors: sort,
                                                                fetchLimit: 1)
        
        return objects?.first?.getObject() as? ReadType
    }
    
    static func exportRemote(predicate: NSPredicate?, sort: [NSSortDescriptor]?) -> AnyPublisher<ReadType?, Error> {
        
        return Deferred {
            return Future { promise in
                
                let controller = CoreDataStorageController.shared
                
                let completion: (([ReadType.ManagedType]?) -> Void) = { result in
                    
                    let object = result?.first?.getObject() as? ReadType
                    promise(.success(object))
                }
                controller.asyncList(predicate: predicate,
                                     sortDescriptors: sort,
                                     fetchLimit: 1,
                                     completion: completion)
            }
        }
        .receive(on: DispatchQueue.main)
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    }
    
    static func exportRemoteList(predicate: NSPredicate?, sort: [NSSortDescriptor]?) -> AnyPublisher<[ReadType]?, Error> {
        
        return Deferred {
            return Future { promise in
                let controller = CoreDataStorageController.shared
                
                let completion: (([ReadType.ManagedType]?) -> Void) = { result in
                    
                    let mapped = result?.compactMap { obj in
                        return obj.getObject() as? ReadType
                    }
                    promise(.success(mapped))
                }
                
                controller.asyncList(predicate: predicate,
                                     sortDescriptors: nil,
                                     fetchLimit: nil,
                                     completion: completion)
            }
        }
        .receive(on: DispatchQueue.main)
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    }
    
    static func observe(predicate: NSPredicate?, sort: [NSSortDescriptor]?) -> AnyPublisher<[ReadType], Error> {
        
        var sort = sort ?? []
        if sort.count == 0 {
            sort.append(.init(key: ReadType.primaryKeyName, ascending: true))
        }
        
        let publisher: AnyPublisher<[ReadType.ManagedType], Error> = 
        CoreDataStorageController.shared.viewContext.publisher(predicate: predicate, sort: sort)
        return publisher
            .map {
                $0.compactMap { $0.getObject() as? ReadType }
            }
            .eraseToAnyPublisher()
    }
    
    static func fetchedResultsProvider(mainPredicate: NSPredicate,
                                       optionalPredicates: [NSPredicate]?,
                                       sorting sortDescriptors: [NSSortDescriptor],
                                       sectionName: String?,
                                       fetchLimit: Int?) -> FetchedResultsProvider<ReadType>
    {
        
        let controller = CoreDataStorageController.shared
        
        return controller.fetchedResultsProvider(mainPredicate: mainPredicate,
                                                 optionalPredicates: optionalPredicates,
                                                 sorting: sortDescriptors,
                                                 sectionName: sectionName,
                                                 fetchLimit: fetchLimit)
    }
    
    static func compute(_ type: ReadType.Type, operation: DatabaseReaderComputationOperation, keyPath: String, predicate: NSPredicate) -> Int? {
        
        let controller = CoreDataStorageController.shared
        
        return controller.compute(ReadType.ManagedType.self, operation: operation.rawValue, keyPath: keyPath, predicate: predicate)
    }
}
