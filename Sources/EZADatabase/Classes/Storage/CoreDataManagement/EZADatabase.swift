//
//  EZADatabase.swift
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
import UIKit
import CoreData
import Combine

/// A type responsible for initializing the application's database
public class EZADatabase<T> {

}

public extension EZADatabase where T == Any {

    static func openDatabase() {
        CoreDataStorageController.shared.loadStore()
    }
    
    static func deleteDatabase(keeping tablesToKeep: [NSManagedObject.Type]) -> AnyPublisher<Void, Error> {
        
        return Deferred {
            Future { promise in
                let tablesToKeepNames = tablesToKeep.map { String(describing: $0) }
                Task {
                    do {
                        try await CoreDataStorageController.shared.deleteAllTables(except: tablesToKeepNames)
                        promise(.success(()))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    static func reloadDatabase() -> AnyPublisher<Void, Error> {
        return deleteDatabase(keeping: [])
            .map {
                openDatabase()
            }
            .eraseToAnyPublisher()
    }
    
    static func destroyDatabase() -> AnyPublisher<Void, Error> {
        
        return Deferred {
            Future { promise in
                Task {
                    do {
                        try await CoreDataStorageController.shared.destroy()
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
