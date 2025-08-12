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

@MainActor public protocol CollectionViewFetchedResultsProviderDelegate: FetchedResultsProviderDelegate {
    
    var collectionView: UICollectionView! { get }
    var operations: [ProviderOperation] { get set }
    func didFinishAnimation()
}

public extension CollectionViewFetchedResultsProviderDelegate {

    func didFinishAnimation() {
         collectionView.reloadData()
    }

    func didReloadContent() {
        collectionView.reloadData()
    }

    func willUpdateList() {
        // Good: prevents auto scrolling during animated changes.
        collectionView.setContentOffset(collectionView.contentOffset, animated: false)
    }

    func didUpdateList() {
        guard collectionView.window != nil, UIApplication.shared.applicationState == .active else {
            collectionView.reloadData()
            operations.removeAll()
            return
        }
        performBatchesOperations()
    }

    // MARK: event -> buffered op

    func moveObject(from indexPath: IndexPath?, to newIndexPath: IndexPath?) {
        guard let from = indexPath, let to = newIndexPath else { return }
        addToOperations(operation: ProviderOperation(
            operation: BlockOperation { [weak self] in
                MainActor.assumeIsolated {
                    self?.collectionView.moveItem(at: from, to: to)
                }
            },
            type: .move,
            scope: .item
        ))
    }

    func insertObject(at indexPath: IndexPath?) {
        guard let ip = indexPath else { return }
        addToOperations(operation: ProviderOperation(
            operation: BlockOperation { [weak self] in
                MainActor.assumeIsolated {
                    self?.collectionView.insertItems(at: [ip])
                }
            },
            type: .insert,
            scope: .item
        ))
    }

    func deleteObject(at indexPath: IndexPath?) {
        guard let ip = indexPath else { return }
        addToOperations(operation: ProviderOperation(
            operation: BlockOperation { [weak self] in
                MainActor.assumeIsolated {
                    self?.collectionView.deleteItems(at: [ip])
                }
            },
            type: .delete,
            scope: .item
        ))
    }

    func updateObject(at indexPath: IndexPath?) {
        guard let ip = indexPath else { return }
        addToOperations(operation: ProviderOperation(
            operation: BlockOperation { [weak self] in
                MainActor.assumeIsolated {
                    self?.collectionView.reloadItems(at: [ip])
                }
            },
            type: .update,
            scope: .item
        ))
    }

    func insert(section: Int) {
        addToOperations(operation: ProviderOperation(
            operation: BlockOperation { [weak self] in
                MainActor.assumeIsolated {
                    self?.collectionView.insertSections(IndexSet(integer: section))
                }
            },
            type: .insert,
            scope: .section
        ))
    }

    func delete(section: Int) {
        addToOperations(operation: ProviderOperation(
            operation: BlockOperation { [weak self] in
                MainActor.assumeIsolated {
                    self?.collectionView.deleteSections(IndexSet(integer: section))
                }
            },
            type: .delete,
            scope: .section
        ))
    }

    func update(section: Int) {
        addToOperations(operation: ProviderOperation(
            operation: BlockOperation { [weak self] in
                MainActor.assumeIsolated {
                    self?.collectionView.reloadSections(IndexSet(integer: section))
                }
            },
            type: .update,
            scope: .section
        ))
    }

    private func addToOperations(operation: ProviderOperation) {
        operations.append(operation)
    }

    private func performBatchesOperations() {
        guard !operations.isEmpty else { return }

        // Enforce the only safe ordering for UICollectionView updates:
        let order: [(ProviderOperation.Scope, ProviderOperation.OperationType)] = [
            (.section, .delete), (.section, .insert), (.section, .update),
            (.item, .delete), (.item, .insert), (.item, .move), (.item, .update)
        ]

        let sorted = operations.sorted { lhs, rhs in
            let il = order.firstIndex { $0.0 == lhs.scope && $0.1 == lhs.type } ?? .max
            let ir = order.firstIndex { $0.0 == rhs.scope && $0.1 == rhs.type } ?? .max
            return il < ir
        }

        collectionView.performBatchUpdates({ [weak self] in
            sorted.forEach { $0.operation.start() }
        }, completion: { [weak self] _ in
            self?.operations.removeAll()
            // Keep as hook; default is no-op above.
            self?.didFinishAnimation()
        })
    }
}
