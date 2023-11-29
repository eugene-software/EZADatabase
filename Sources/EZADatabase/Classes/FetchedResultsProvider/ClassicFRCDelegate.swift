//
//  File.swift
//  
//
//  Created by Eugeniy Zaychenko on 11/13/23.
//

import Foundation
import CoreData
import Combine

class ClassicFRCDelegate: NSObject, NSFetchedResultsControllerDelegate {
    
    struct ChangeObjectEvent {
        let object: Any?
        let indexPath: IndexPath?
        let newIndexPath: IndexPath?
        let type: NSFetchedResultsChangeType
    }
    
    struct ChangeSectionEvent {
        let section: NSFetchedResultsSectionInfo
        let sectionIndex: Int
        let type: NSFetchedResultsChangeType
    }
    
    let willChangePublisher: PassthroughSubject<Void, Never> = .init()
    let didChangePublisher: PassthroughSubject<Void, Never> = .init()
    let didChangeObjectChangePublisher: PassthroughSubject<ChangeObjectEvent, Never> = .init()
    let didChangeSectionChangePublisher: PassthroughSubject<ChangeSectionEvent, Never> = .init()
    
    public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        willChangePublisher.send(())
    }
    
    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        didChangePublisher.send(())
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        didChangeObjectChangePublisher.send(
            .init(
                object: anObject,
                indexPath: indexPath,
                newIndexPath: newIndexPath,
                type: type
            )
        )
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        
        didChangeSectionChangePublisher.send(
            .init(
                section: sectionInfo,
                sectionIndex: sectionIndex,
                type: type
            )
        )
    }
}
