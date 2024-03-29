//
//  ClassicFRCDelegate.swift
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
