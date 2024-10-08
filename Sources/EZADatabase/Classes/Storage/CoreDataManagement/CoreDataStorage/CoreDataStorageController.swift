//
//  CoreDataStorageController.swift
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
@preconcurrency import CoreData

class FrameworkPersistentContainer: NSPersistentCloudKitContainer, @unchecked Sendable {}

private extension DispatchQueue {
    static let coreDataConcurrent: DispatchQueue = DispatchQueue(label: UUID().uuidString, qos: .userInitiated, attributes: .concurrent)
}

class CoreDataStorageController: NSObject, @unchecked Sendable {
    
    private static let kEZADatabaseModelName = "EZADatabaseModelName";
    
    //Static Properties
    //
    static let shared: CoreDataStorageController = CoreDataStorageController()
    
    //Private Properties
    //
    private var persistentContainer: NSPersistentContainer!
    private var backgroundContext: NSManagedObjectContext?
    
    //Public Properties
    //
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func loadStore(completionClosure: ((Error?) -> Void)?) {
        
        guard let containerName = Bundle.main.infoDictionary?[Self.kEZADatabaseModelName] as? String else {
            fatalError("EZADatabaseModelName should be specified in Info.plist. Make sure it's equal to .xcdatamodel file name")
        }
        
        persistentContainer = FrameworkPersistentContainer(name: containerName)
        persistentContainer.loadPersistentStores() { (description, error) in
            completionClosure?(error)
        }
        
        // Initialize background context to perform all operations in background.
        //
        backgroundContext = persistentContainer.newBackgroundContext()
        backgroundContext?.undoManager = nil
        backgroundContext?.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        backgroundContext?.automaticallyMergesChangesFromParent = true
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}


//MARK: - DataStorageInterface

extension CoreDataStorageController: CoreDataStorageInterface {
    
    func destroy(completion: ((Error?) -> Void)?) {
        
        backgroundContext?.reset()
        viewContext.reset()
        defer {
            backgroundContext = nil
        }
        
        do {
            let coordinator = persistentContainer.persistentStoreCoordinator
            let stores = coordinator.persistentStores
            for store in stores {
                guard let url = store.url else { continue }
                try coordinator.destroyPersistentStore(at: url, ofType: store.type, options: nil)
            }
            completion?(nil)
        } catch {
            completion?(error)
        }
    }
    
    func deleteAllTables(except names: [String], completion: ((Error?) -> Void)?) {
        
        let context = backgroundContext
        let allEntitiyNames = persistentContainer.managedObjectModel.entities.compactMap { $0.name }
        let toBeRemoved = allEntitiyNames.filter { !names.contains($0) }
        
        save {
            do {
                for name in toBeRemoved {
                    let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: name)
                    let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                    try context?.executeAndMergeChanges(using: deleteRequest)
                }
            } catch {
                completion?(error)
            }
        } completionBlock: {
            completion?(nil)
        }
    }
    
    func setValues<Type: CoreDataCompatible>(type: Type.Type, values: [String: Any?], predicate: NSPredicate?, completion: @escaping () -> Void) {
        
        let context = backgroundContext
        
        let entityName = String(describing: Type.ManagedType.self)
        let fetchRequest = NSFetchRequest<Type.ManagedType>(entityName: entityName)
        fetchRequest.predicate = predicate
        
        save {
            let result = context?.safeFetch(fetchRequest)
            result?.forEach({ (obj) in
                
                values.forEach { (key, value) in
                    
                    let old = obj.value(forKey: key)
                    let oldString = String(describing: old)
                    let newString = String(describing: value)
                    
                    if oldString != newString {
                        obj.setValue(value, forKeyPath: key)
                    } else {
                        print("Old: \(oldString), New: \(newString)")
                    }
                }
            })
        } completionBlock: {
            completion()
        }
    }
    
    func findRelation<Type: CoreDataExportable>(predicate: NSPredicate?) -> Type? {
        let result: [Type]? = query(predicate: predicate, context: backgroundContext!, sortDescriptors: nil, fetchLimit: 1)
        return result?.first
    }
    
    func insertSync<Type: CoreDataCompatible>(object: Type?, predicate: NSPredicate?) -> Type.ManagedType? {
        
        guard let object = object else { return nil }
        let predicate = predicate ?? NSPredicate(key: Type.primaryKeyName, value: object.primaryKey)
        return self.insert(object: object, predicate: predicate, context: self.backgroundContext!)
    }
    
    func fetchedResultsProvider<Type: CoreDataCompatible>(mainPredicate: NSPredicate,
                                                          optionalPredicates: [NSPredicate]?,
                                                          sorting sortDescriptors: [NSSortDescriptor],
                                                          sectionName: String?,
                                                          fetchLimit: Int?) -> FetchedResultsProvider<Type>
    {
        return FetchedResultsProvider<Type>(mainPredicate,
                                            optionalPredicates: optionalPredicates,
                                            sorting: sortDescriptors,
                                            context: viewContext,
                                            sectionName: sectionName,
                                            fetchLimit: fetchLimit)
    }
    
    func insertList<Type: CoreDataCompatible>(objects: [Type?], completion: @escaping () -> Void) {
        
        let objects = objects.compactMap{$0}.chunked(into: 1000)
        let group = DispatchGroup()
        
        objects.forEach { chunk in
            group.enter()
            save {
                chunk.forEach {
                    let predicate = NSPredicate(key: Type.primaryKeyName, value: $0.primaryKey)
                    self.insert(object: $0, predicate: predicate, context: self.backgroundContext!)
                }
            } completionBlock: {
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion()
        }
    }
    
    func insertAsync<Type: CoreDataCompatible>(object: Type?, predicate: NSPredicate?, completion: @escaping () -> Void) {
        
        guard let object = object else {
            completion()
            return
        }
        save {
            let predicate = predicate ?? NSPredicate(key: Type.primaryKeyName, value: object.primaryKey)
            self.insert(object: object, predicate: predicate, context: self.backgroundContext!)
        } completionBlock: {
            completion()
        }
    }
    
    func list<Type: CoreDataExportable>(predicate: NSPredicate?,
                                         sortDescriptors: [NSSortDescriptor]?,
                                         fetchLimit: Int?) -> [Type]? {
        return query(predicate: predicate, context: viewContext, sortDescriptors: sortDescriptors, fetchLimit: fetchLimit)
    }
    
    func asyncList<Type: CoreDataExportable>(predicate: NSPredicate?,
                                              sortDescriptors: [NSSortDescriptor]?,
                                              fetchLimit: Int?,
                                              completion: @escaping ([Type]?) -> Void) {
        
        let context = backgroundContext
        
        context?.perform { [weak self] in
            let result: [Type]? = self?.query(predicate: predicate, context: context!, sortDescriptors: sortDescriptors, fetchLimit: fetchLimit)
            completion(result)
        }
    }
    
    func delete<Type: CoreDataExportable>(_ type: Type.Type, with predicate: NSPredicate?, completion: @escaping () -> Void) {
        
        let context = backgroundContext
        
        let entityName = String(describing: Type.self)
        let fetchRequest = NSFetchRequest<Type>(entityName: entityName)
        fetchRequest.predicate = predicate
        
        save {
            if let result = context?.safeFetch(fetchRequest), !result.isEmpty {
                result.forEach { (obj) in
                    context?.delete(obj)
                }
            }
        } completionBlock: {
            completion()
        }
    }
    
    func compute<Type: CoreDataExportable>(_ type: Type.Type, operation: String, keyPath: String, predicate: NSPredicate?) -> Int? {
        
        let context = viewContext
        let entityName = String(describing: Type.self)
        let fetchRequest = NSFetchRequest<NSDictionary>(entityName: entityName)
        
        fetchRequest.predicate = predicate
        fetchRequest.resultType = .dictionaryResultType
        
        let averageExpressionDesc = NSExpressionDescription()
        averageExpressionDesc.name = operation
        
        let specialAvgExp = NSExpression(forKeyPath: keyPath)
        averageExpressionDesc.expression = NSExpression(forFunction: operation, arguments: [specialAvgExp])
        averageExpressionDesc.expressionResultType = .integer64AttributeType
        
        fetchRequest.propertiesToFetch = [averageExpressionDesc]
        let result = context.safeFetch(fetchRequest)
        return result?.first?[operation] as? Int
    }
}


//MARK: - Private methods

private extension CoreDataStorageController {
    
    func save(saveBlock: @escaping () -> Void, completionBlock: @escaping () -> Void) {
        
        let context = backgroundContext
        
        context?.perform { [weak context] in
            saveBlock()
            context?.saveSelfAndParent() {
                completionBlock()
            }
        }
    }
    
    @discardableResult
    func insert<Type: CoreDataCompatible>(object: Type?, predicate: NSPredicate?, context: NSManagedObjectContext) -> Type.ManagedType? {
        
        let entityName = String(describing: Type.ManagedType.self)
        let result: Type.ManagedType?
        
        if let list: [Type.ManagedType] = query(predicate: predicate, context: context, fetchLimit: 1), !list.isEmpty {
            result = list.first
        } else {
            result = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context) as? Type.ManagedType
        }
        result?.configure(with: object as! Type.ManagedType.ExportType, in: self)
        return result
    }
    
    func query<Type: NSManagedObject>(predicate: NSPredicate?, context: NSManagedObjectContext, sortDescriptors: [NSSortDescriptor]? = nil, fetchLimit: Int? = nil) -> [Type]? {
        
        // Fetch entity with appropriate class
        //
        let entityName = String(describing: Type.self)
        let fetchRequest = NSFetchRequest<Type>(entityName: entityName)
        fetchRequest.sortDescriptors = sortDescriptors
        fetchRequest.predicate = predicate
        
        if let limit = fetchLimit {
            fetchRequest.fetchLimit = limit
        }
        
        return context.safeFetch(fetchRequest)
    }
}


//MARK: Convenience saving context
//
private extension NSManagedObjectContext {
    
    func safeFetch<T>(_ request: NSFetchRequest<T>) -> [T]? where T : NSFetchRequestResult {
        
        do {
            return try fetch(request)
        }
        catch {
            return nil
        }
    }
    func saveContextInstantly() {
        
        // Nothing to save
        //
        if !self.hasChanges { return }
        
        do {
            try save()
        } catch {
//            Crashlytics.crashlytics().record(error: error)
            fatalError("Error  saving context: \(error)")
        }
    }
    
    func saveSelfAndParent(completion: (() -> Void)?) {
        saveContextInstantly()
        
        if (parent != nil) {
            parent?.perform({[weak self] in
                self?.parent?.saveSelfAndParent(completion: completion)
            })
        } else {
            completion?()
        }
    }
}

private extension NSManagedObjectContext {
    
    /// Executes the given `NSBatchDeleteRequest` and directly merges the changes to bring the given managed object context up to date.
    ///
    /// - Parameter batchDeleteRequest: The `NSBatchDeleteRequest` to execute.
    /// - Throws: An error if anything went wrong executing the batch deletion.
    func executeAndMergeChanges(using batchDeleteRequest: NSBatchDeleteRequest) throws {
        
        batchDeleteRequest.resultType = .resultTypeObjectIDs
        let result = try execute(batchDeleteRequest) as? NSBatchDeleteResult
        let changes: [AnyHashable: Any] = [NSDeletedObjectsKey: result?.result as? [NSManagedObjectID] ?? []]
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self])
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

