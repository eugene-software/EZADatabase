//
//  FetchedResultsControllerProviderDelegate+CollectionView.swift
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


import UIKit

//MARK: - FetchedResultsProviderDelegate + CollectionView

@MainActor public struct ProviderOperation {
    
    enum OperationType {
        case insert, delete, update, move
    }
    let operation: BlockOperation
    let type: OperationType
}

@MainActor public protocol CollectionViewFetchedResultsProviderDelegate: FetchedResultsProviderDelegate {
    
    var collectionView: UICollectionView! { get }
    var operations: [ProviderOperation] { get set }
    var shouldAlwaysReloadData: Bool { get }
    func didFinishAnimation()
}

public extension CollectionViewFetchedResultsProviderDelegate {
    
    var shouldAlwaysReloadData: Bool { return false }
    
    func didFinishAnimation() {
        collectionView.reloadData()
    }
    
    func didReloadContent() {
        collectionView.reloadData()
    }
    
    func willUpdateList() {
        collectionView.setContentOffset(collectionView.contentOffset, animated: false)
    }
    
    func didUpdateList() {
        
        if shouldAlwaysReloadData || collectionView.window == nil || UIApplication.shared.applicationState != .active {
            collectionView.reloadData()
            operations.removeAll()
            return
        }
        
        performBatchesOperations()
    }
    
    func moveObject(from indexPath: IndexPath?, to newIndexPath: IndexPath?) {
        
        guard let from = indexPath, let to = newIndexPath else { return }
        addToOperations(operation: ProviderOperation(operation: BlockOperation {[weak self] in
            MainActor.assumeIsolated {
                self?.collectionView.deleteItems(at: [from])
                self?.collectionView.insertItems(at: [to])
            }
            
        }, type: .move))
    }
    
    func insertObject(at indexPath: IndexPath?) {
        
        let indexPaths = [indexPath].compactMap{ $0 }
        addToOperations(operation: ProviderOperation(operation: BlockOperation {[weak self] in
            MainActor.assumeIsolated {
                self?.collectionView.insertItems(at: indexPaths)
            }
        }, type: .insert))
    }
    
    func deleteObject(at indexPath: IndexPath?) {
        
        let indexPaths = [indexPath].compactMap{ $0 }
        addToOperations(operation: ProviderOperation(operation: BlockOperation {[weak self] in
            MainActor.assumeIsolated {
                self?.collectionView.deleteItems(at: indexPaths)
            }
        }, type: .delete))
    }
    
    func updateObject(at indexPath: IndexPath?) {
        
        let indexPaths = [indexPath].compactMap{ $0 }
        if indexPaths.isEmpty { return }
        addToOperations(operation: ProviderOperation(operation: BlockOperation {[weak self] in
            MainActor.assumeIsolated {
                self?.collectionView.reloadItems(at: indexPaths)
            }
        }, type: .update))
    }
    
    func insert(section: Int) {
        addToOperations(operation: ProviderOperation(operation: BlockOperation {[weak self] in
            MainActor.assumeIsolated {
                self?.collectionView.insertSections(IndexSet(integer: section))
            }
        }, type: .insert))
    }
    
    func delete(section: Int) {
        addToOperations(operation: ProviderOperation(operation: BlockOperation {[weak self] in
            MainActor.assumeIsolated {
                self?.collectionView.deleteSections(IndexSet(integer: section))
            }
        }, type: .delete))
    }
    
    func update(section: Int) {
        addToOperations(operation: ProviderOperation(operation: BlockOperation {[weak self] in
            MainActor.assumeIsolated {
                self?.collectionView.reloadSections(IndexSet(integer: section))
            }
        }, type: .update))
    }
    
    private func addToOperations(operation: ProviderOperation) {
        operations.append(operation)
    }
    
    private func performBatchesOperations() {
        
        if operations.isEmpty { return }
        
        self.collectionView.performBatchUpdates({[weak self] in
            self?.operations.forEach { $0.operation.start() }
        }, completion: {[weak self] (finished) -> Void in
            self?.operations.removeAll()
            DispatchQueue.main.async {
                self?.didFinishAnimation()
            }
        })
    }
}
