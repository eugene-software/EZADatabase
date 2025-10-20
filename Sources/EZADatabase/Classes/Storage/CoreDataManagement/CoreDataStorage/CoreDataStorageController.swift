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
	private var persistentContainer: NSPersistentContainer?
    private var backgroundContext: NSManagedObjectContext?
    
    //Public Properties
    //
	var isStoreLoaded: Bool { persistentContainer != nil }

	var viewContext: NSManagedObjectContext {
		guard let container = persistentContainer else {
			preconditionFailure("EZADatabase is not initialized. Call EZADatabase.openDatabase() before accessing viewContext.")
		}
		return container.viewContext
	}

    // MARK: - Initialization
    /// Loads persistent stores synchronously.
    func loadStore() {
		guard let containerName = Bundle.main.infoDictionary?[Self.kEZADatabaseModelName] as? String else {
			fatalError("EZADatabaseModelName should be specified in Info.plist. Make sure it's equal to .xcdatamodel file name")
		}
        let semaphore = DispatchSemaphore(value: 0)
		let container = FrameworkPersistentContainer(name: containerName)
        DispatchQueue.coreDataConcurrent.async {
            container.loadPersistentStores { _, error in
                if let error {
                    fatalError(error.localizedDescription)
                }
                semaphore.signal()
            }
        }
        semaphore.wait()
		// Assign and initialize contexts after stores are loaded
		persistentContainer = container
		backgroundContext = container.newBackgroundContext()
		backgroundContext?.undoManager = nil
		backgroundContext?.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
		backgroundContext?.automaticallyMergesChangesFromParent = true
		container.viewContext.automaticallyMergesChangesFromParent = true
		container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}


//MARK: - DataStorageInterface

extension CoreDataStorageController: CoreDataStorageInterface {
    
    func destroy() async throws {
        backgroundContext?.reset()
        viewContext.reset()
        defer { backgroundContext = nil }
		do {
			guard let persistentContainer = persistentContainer else { throw NSError(domain: "EZADatabase", code: -1) }
			let coordinator = persistentContainer.persistentStoreCoordinator
            let stores = coordinator.persistentStores
            for store in stores {
                guard let url = store.url else { continue }
                try coordinator.destroyPersistentStore(at: url, ofType: store.type, options: nil)
            }
        } catch {
            throw error
        }
    }
    
    func deleteAllTables(except names: [String]) async throws {
		let context = backgroundContext
		guard let persistentContainer = persistentContainer else { throw EZADatabaseError.persistentContainerUnavailable }
		let allEntitiyNames = persistentContainer.managedObjectModel.entities.compactMap { $0.name }
        let toBeRemoved = allEntitiyNames.filter { !names.contains($0) }
        try await withCheckedThrowingContinuation { continuation in
            self.save {
                do {
                    for name in toBeRemoved {
                        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: name)
                        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                        try context?.executeAndMergeChanges(using: deleteRequest)
                    }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            } completionBlock: {
                // no-op; continuation already resumed
            }
        }
    }
    
    func setValues<Type: CoreDataCompatible>(type: Type.Type, values: [String: Any?], predicate: NSPredicate?) async {
        let context = backgroundContext
        let entityName = String(describing: Type.ManagedType.self)
        let fetchRequest = NSFetchRequest<Type.ManagedType>(entityName: entityName)
        fetchRequest.predicate = predicate
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            self.save {
                let result = context?.safeFetch(fetchRequest)
                result?.forEach({ (obj) in
                    values.forEach { (key, value) in
                        let old = obj.value(forKey: key)
                        let oldString = String(describing: old)
                        let newString = String(describing: value)
                        if oldString != newString {
                            obj.setValue(value, forKeyPath: key)
                        }
                    }
                })
            } completionBlock: {
                continuation.resume()
            }
        }
    }
    
    func findRelation<Type: CoreDataExportable>(predicate: NSPredicate?) -> Type? {
		guard let context = backgroundContext else { return nil }
		let result: [Type]? = query(predicate: predicate, context: context, sortDescriptors: nil, fetchLimit: 1)
        return result?.first
    }
    
    func insertSync<Type: CoreDataCompatible>(object: Type?, predicate: NSPredicate?) -> Type.ManagedType? {
        
        guard let object = object else { return nil }
		let predicate = predicate ?? NSPredicate(key: Type.primaryKeyName, value: object.primaryKey)
		guard let context = self.backgroundContext else { return nil }
		return self.insert(object: object, predicate: predicate, context: context)
    }
    
    func fetchedResultsProvider<Type: CoreDataCompatible>(mainPredicate: NSPredicate,
                                                          optionalPredicates: [NSPredicate]?,
                                                          sorting sortDescriptors: [NSSortDescriptor],
                                                          sectionName: String?,
                                                          fetchLimit: Int?) -> FetchedResultsProvider<Type>
    {
        guard persistentContainer != nil else {
            preconditionFailure("EZADatabase is not initialized. Call EZADatabase.openDatabase() before creating FetchedResultsProvider.")
        }
        return FetchedResultsProvider<Type>(mainPredicate,
                                            optionalPredicates: optionalPredicates,
                                            sorting: sortDescriptors,
                                            context: viewContext,
                                            sectionName: sectionName,
                                            fetchLimit: fetchLimit)
    }
    
    func insertList<Type: CoreDataCompatible>(objects: [Type?]) async {
        let chunks = objects.compactMap{$0}.chunked(into: 1000)
        for chunk in chunks {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                self.save {
                    chunk.forEach {
					guard let context = self.backgroundContext else { return }
					let predicate = NSPredicate(key: Type.primaryKeyName, value: $0.primaryKey)
					self.insert(object: $0, predicate: predicate, context: context)
                    }
                } completionBlock: {
                    continuation.resume()
                }
            }
        }
    }
    
    func insertAsync<Type: CoreDataCompatible>(object: Type?, predicate: NSPredicate?) async {
        guard let object = object else { return }
		await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
			self.save {
				guard let context = self.backgroundContext else { return }
				let predicate = predicate ?? NSPredicate(key: Type.primaryKeyName, value: object.primaryKey)
				self.insert(object: object, predicate: predicate, context: context)
			} completionBlock: {
				continuation.resume()
			}
		}
    }
    
    func list<Type: CoreDataExportable>(predicate: NSPredicate?,
                                         sortDescriptors: [NSSortDescriptor]?,
                                         fetchLimit: Int?) -> [Type]? {
        return query(predicate: predicate, context: viewContext, sortDescriptors: sortDescriptors, fetchLimit: fetchLimit)
    }
    
    func asyncList<Type: CoreDataExportable>(predicate: NSPredicate?,
                                             sortDescriptors: [NSSortDescriptor]?,
                                             fetchLimit: Int?) async -> [Type]? {
        let context = backgroundContext
		return await withCheckedContinuation { (continuation: CheckedContinuation<[Type]?, Never>) in
			context?.perform { [weak self] in
				guard let context = context else { continuation.resume(returning: nil); return }
				let result: [Type]? = self?.query(predicate: predicate, context: context, sortDescriptors: sortDescriptors, fetchLimit: fetchLimit)
				continuation.resume(returning: result)
			}
		}
    }
    
    func delete<Type: CoreDataExportable>(_ type: Type.Type, with predicate: NSPredicate?) async throws {
        let context = backgroundContext
        let entityName = String(describing: Type.self)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.predicate = predicate

        try await withCheckedThrowingContinuation { continuation in
            self.save {
                do {
                    let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                    try context?.executeAndMergeChanges(using: deleteRequest)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            } completionBlock: {
                // no-op; continuation already resumed
            }
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

