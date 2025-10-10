//
//  CoreDataWriter.swift
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
import CoreData

extension CoreDataWriter: DatabaseWriterProtocolCombine where ImportedType: CoreDataCompatible {
    
    typealias WriteType = ImportedType
    
    static func deleteEntities(_ entity: WriteType.Type, predicate: NSPredicate?) -> AnyPublisher<Void, Error> {
        
        return Deferred {
            return Future { promise in
                Task {
                    do {
                        try await deleteEntities(entity, predicate: predicate)
                        promise(.success(()))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    static func importRemoteList(_ objectsToImport: [WriteType?]) -> AnyPublisher<Void, Error> {
        
        return Deferred {
            return Future { promise in
                Task {
                    do {
                        try await importRemoteList(objectsToImport)
                        promise(.success(()))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    static func updateRemote(_ objectToImport: WriteType?, predicate: NSPredicate?) -> AnyPublisher<Void, Error> {
        
        return Deferred {
            return Future { promise in
                Task {
                    do {
                        try await updateRemote(objectToImport, predicate: predicate)
                        promise(.success(()))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    static func importValues(_ entity: WriteType.Type, predicate: NSPredicate?, values:  [String: Any]) -> AnyPublisher<Void, Error>  {
        
        return Deferred {
            return Future { promise in
                Task {
                    do {
                        try await importValues(entity, predicate: predicate, values: values)
                        promise(.success(()))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

