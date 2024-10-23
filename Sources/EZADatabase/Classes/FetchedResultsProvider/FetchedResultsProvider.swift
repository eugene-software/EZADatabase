//
//  FetchedResultsProvider.swift
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
import UIKit

public class FetchedResultsProvider<U: CoreDataCompatible>: NSObject, @unchecked Sendable {
    
    private var cancellables: [AnyCancellable] = []
    
    private var kDefaultFetchLimit: Int = 20
    
    private var classicFRCDelegate: ClassicFRCDelegate?
    private var diffableFRCDelegate: DiffableFRCDelegate?
    
    public weak var delegate: FetchedResultsProviderDelegate? {
        didSet {
            classicFRCDelegate = ClassicFRCDelegate()
            fetchedResultsController?.delegate = classicFRCDelegate
            observeClassicFRCDelegate()
            reloadFetchController()
        }
    }
    
    public var diffableDataSourcePublisher: AnyPublisher<NSDiffableDataSourceSnapshot<String, U>?, Never> {
        diffableDataSourceSubject.handleEvents(receiveSubscription: {[weak self] _ in
            self?.diffableFRCDelegate = DiffableFRCDelegate()
            self?.fetchedResultsController?.delegate = self?.diffableFRCDelegate
            self?.observeDiffableFRCDelegate()
            self?.reloadFetchController()
        })
        .eraseToAnyPublisher()
    }
    
    private var fetchedResultsController: NSFetchedResultsController<U.ManagedType>?
    private var mainPredicate: NSPredicate
    private var optionalPredicates: [NSPredicate]?
    private var fetchLimit: Int?
    private var sortDescriptors: [NSSortDescriptor]
    private var sectionName: String?
    private let context: NSManagedObjectContext
    private var diffableDataSourceSubject: CurrentValueSubject<NSDiffableDataSourceSnapshot<String, U>?, Never> = .init(nil)
    
    
    init(_ mainPredicate: NSPredicate,
         optionalPredicates: [NSPredicate]?,
         sorting sortDescriptors: [NSSortDescriptor],
         context: NSManagedObjectContext,
         sectionName: String? = nil,
         fetchLimit: Int? = nil) {
        
        self.mainPredicate = mainPredicate
        self.optionalPredicates = optionalPredicates
        self.fetchLimit = fetchLimit
        self.sortDescriptors = sortDescriptors
        self.sectionName = sectionName
        self.context = context
        super.init()
    }
}


//MARK: - Public

public extension FetchedResultsProvider {
    
    func indexPathForObject(using predicate: NSPredicate) -> IndexPath? {
        
        if let object = fetchedResultsController?.fetchedObjects?.filter({ predicate.evaluate(with: $0) }).first {
            return fetchedResultsController?.indexPath(forObject: object)
        }
        return nil
    }
    
    var allObjects: [U]? {
        return fetchedResultsController?.fetchedObjects?.map { $0.getObject() as! U }
    }
    
    func configure(limit: Int?) {
        
        fetchLimit = limit
        reloadFetchController()
    }
    
    var contentExist: Bool {
        return fetchedResultsController?.fetchedObjects?.count != 0
    }
    
    func title(for section: Int) -> String? {
        return section < numberOfSections ? fetchedResultsController?.sections?[section].name : nil
    }
    
    func add(predicate: NSPredicate?) {
        
        guard let predicate = predicate else { return }
        optionalPredicates?.append(predicate)
        reloadFetchController()
    }
    
    func update(with predicate: NSPredicate?) {
        
        optionalPredicates = [predicate].compactMap { $0 }
        reloadFetchController()
    }
    
    func object(at indexPath: IndexPath) -> U? {
        
        guard indexPath.section < numberOfSections else { return nil }
        guard indexPath.item < (numberOfItems(in: indexPath.section) ?? 0) else { return nil }
        
        guard let managedObject = fetchedResultsController?.object(at: indexPath) else {
            return nil
        }

        return managedObject.getObject() as? U
    }
    
    func numberOfItems(in section: Int) -> Int? {
        return section < numberOfSections ? fetchedResultsController?.sections?[section].numberOfObjects : 0
    }
    
    var numberOfSections: Int {
        return fetchedResultsController?.sections?.count ?? 0
    }
}

private extension FetchedResultsProvider {
 
    func createFetchRequest() -> NSFetchRequest<U.ManagedType> {
        
        let name = String(describing: U.ManagedType.self)
        let fetchRequest = NSFetchRequest<U.ManagedType>(entityName: name)
        updateFetchRequest(fetchRequest)
        
        return fetchRequest
    }
    
    func updateFetchRequest(_ fetchRequest: NSFetchRequest<U.ManagedType>) {
        
        NSFetchedResultsController<U.ManagedType>.deleteCache(withName: nil)
        
        var predicates = optionalPredicates ?? []
        predicates.append(mainPredicate)
        
        let compound = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        fetchRequest.predicate = compound
        fetchRequest.sortDescriptors = sortDescriptors
        
        if let limit = fetchLimit {
            fetchRequest.fetchLimit = limit
            fetchRequest.fetchBatchSize = fetchRequest.fetchLimit
        }
    }
    
    func reloadFetchController() {
        
        if fetchedResultsController == nil {
            fetchedResultsController = NSFetchedResultsController(fetchRequest: createFetchRequest(),
                                                                  managedObjectContext: context,
                                                                  sectionNameKeyPath: sectionName,
                                                                  cacheName: nil)
            fetchedResultsController?.delegate = diffableFRCDelegate ?? classicFRCDelegate
            
        } else if let request = fetchedResultsController?.fetchRequest {
            updateFetchRequest(request)
        }
        
        do {
            try fetchedResultsController?.performFetch()
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.didReloadContent()
            }
            
        } catch {
            print(error)
        }
    }
    
    func observeDiffableFRCDelegate() {
        
        diffableFRCDelegate?.snapshotChangePublisher
            .sink {[weak self] snapshot in
                
                guard let controller = self?.fetchedResultsController else { return }
                let snapshot = snapshot as NSDiffableDataSourceSnapshot<String, NSManagedObjectID>
                let another = snapshot.mapObjects { id in
                    let object = controller.managedObjectContext.object(with: id) as! (any CoreDataExportable)
                    return object.getObject() as? U
                }
                self?.diffableDataSourceSubject.send(another)
            }
            .store(in: &cancellables)
    }
    
    func observeClassicFRCDelegate() {
        
        Task {
            await MainActor.run {
                classicFRCDelegate?.willChangePublisher
                    .sink { [weak self] _ in
                        self?.delegate?.willUpdateList()
                    }
                    .store(in: &cancellables)
                
                classicFRCDelegate?.didChangePublisher
                    .sink {[weak self] _ in
                        self?.delegate?.didUpdateList()
                    }
                    .store(in: &cancellables)
                
                classicFRCDelegate?.didChangeObjectChangePublisher
                    .sink {[weak self] event in
                        
                        switch event.type {
                        case .insert:
                            self?.delegate?.insertObject(at: event.newIndexPath)
                        case .delete:
                            self?.delegate?.deleteObject(at: event.indexPath)
                        case .move:
                            if event.indexPath == event.newIndexPath {
                                self?.delegate?.updateObject(at: event.indexPath)
                            } else {
                                self?.delegate?.moveObject(from: event.indexPath, to: event.newIndexPath)
                            }
                        case .update:
                            self?.delegate?.updateObject(at: event.indexPath)
                        @unknown default:
                            self?.delegate?.didReloadContent()
                        }
                        
                    }
                    .store(in: &cancellables)
                
                classicFRCDelegate?.didChangeSectionChangePublisher
                    .sink {[weak self] event in
                        switch event.type {
                        case .insert:
                            self?.delegate?.insert(section: event.sectionIndex)
                        case .delete:
                            self?.delegate?.delete(section: event.sectionIndex)
                        case .move: break
                        case .update:
                            self?.delegate?.update(section: event.sectionIndex)
                        @unknown default:
                            self?.delegate?.didReloadContent()
                        }
                    }
                    .store(in: &cancellables)
            }
        }
    }
}
