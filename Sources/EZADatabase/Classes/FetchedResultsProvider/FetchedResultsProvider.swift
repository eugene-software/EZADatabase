//
//  FetchedResultsControllerProvider.swift
//   EZADatabase
//
//  Created by Eugene Software on 1/4/18.
//

import Foundation
import CoreData

class FetchedResultsProvider<U: CoreDataCompatible>: NSObject, NSFetchedResultsControllerDelegate {
    
    private var kDefaultFetchLimit: Int = 20
    
    weak var delegate: FetchedResultsProviderDelegate?
    
    private var fetchedResultsController: NSFetchedResultsController<U.ManagedType>?
    private var mainPredicate: NSPredicate
    private var optionalPredicates: [NSPredicate]?
    private var fetchLimit: Int?
    private var sortDescriptors: [NSSortDescriptor]
    private var sectionName: String?
    private let context: NSManagedObjectContext
    
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
        
        reloadFetchController()
    }
    
    
    //  MARK: - NSFetchedResultsControllerDelegate
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.willUpdateList()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.didUpdateList()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {

        switch type {
        case .insert:
            delegate?.insertObject(at: newIndexPath)
        case .delete:
            delegate?.deleteObject(at: indexPath)
        case .move:
            if indexPath == newIndexPath {
                delegate?.updateObject(at: indexPath)
            } else {
                delegate?.moveObject(from: indexPath, to: newIndexPath)
            }
        case .update:
            delegate?.updateObject(at: indexPath)
        @unknown default:
            delegate?.didReloadContent()
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            delegate?.insert(section: sectionIndex)
        case .delete:
            delegate?.delete(section: sectionIndex)
        case .move: break
        case .update:
            delegate?.update(section: sectionIndex)
        @unknown default:
            delegate?.didReloadContent()
        }
    }
}


//MARK: - FetchedResultsControllerProviderProtocol

extension FetchedResultsProvider: FetchedResultsProviderInterface {
    
    func indexPathForObject(using predicate: NSPredicate) -> IndexPath? {
        
        if let object = fetchedResultsController?.fetchedObjects?.filter({ predicate.evaluate(with: $0) }).first {
            return fetchedResultsController?.indexPath(forObject: object)
        }
        return nil
    }
    
    var allObjects: [Any]? {
        return fetchedResultsController?.fetchedObjects?.map { $0.getObject() }
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
    
    func object(at indexPath: IndexPath) -> Any? {
        
        guard indexPath.section < numberOfSections else { return nil }
        guard indexPath.item < (numberOfItems(in: indexPath.section) ?? 0) else { return nil }
        
        guard let managedObject = fetchedResultsController?.object(at: indexPath) else {
            return nil
        }

        return managedObject.getObject()
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
            fetchedResultsController?.delegate = self
            
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
}
