//
//  FetchedResultsControllerProviderDelegate+TableView.swift
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


//MARK: - FetchedResultsProviderDelegate + TableView

@MainActor public protocol TableViewFetchedResultsProviderDelegate: FetchedResultsProviderDelegate {
    
    var animationType: UITableView.RowAnimation { get }
    
    var operations: [ProviderOperation] { get set }
    var tableView: UITableView! { get set }
    func didFinishAnimation()
}

public extension TableViewFetchedResultsProviderDelegate {
    
    var animationType: UITableView.RowAnimation {
        return UITableView.RowAnimation.fade
    }
    
    func didFinishAnimation() {
        tableView.reloadData()
    }
    
    func didReloadContent() {
        tableView.reloadData()
    }
    
    func didUpdateList() {
        
        if tableView.window == nil || UIApplication.shared.applicationState != .active {
            tableView.reloadData()
            operations.removeAll()
            return
        }
        
        performBatchesOperations()
    }
    
    func moveObject(from indexPath: IndexPath?, to newIndexPath: IndexPath?) {
        
        guard let from = indexPath, let to = newIndexPath else { return }
        addToOperations(operation: ProviderOperation(operation: BlockOperation {[weak self] in
            MainActor.assumeIsolated {
                self?.tableView.moveRow(at: from, to: to)
            }
            
        }, type: .move))
    }
    
    func insertObject(at indexPath: IndexPath?) {
        
        let indexPaths = [indexPath].compactMap{ $0 }
        addToOperations(operation: ProviderOperation(operation: BlockOperation {[weak self] in
            MainActor.assumeIsolated {
                self?.tableView.insertRows(at: indexPaths, with: self?.animationType ?? .fade)
            }
        }, type: .insert))
    }
    
    func deleteObject(at indexPath: IndexPath?) {
        
        let indexPaths = [indexPath].compactMap{ $0 }
        addToOperations(operation: ProviderOperation(operation: BlockOperation {[weak self] in
            MainActor.assumeIsolated {
                self?.tableView.deleteRows(at: indexPaths, with: self?.animationType ?? .fade)
            }
        }, type: .delete))
    }
    
    func insert(section: Int) {
        addToOperations(operation: ProviderOperation(operation: BlockOperation {[weak self] in
            MainActor.assumeIsolated {
                self?.tableView.insertSections(IndexSet(integer: section), with: self?.animationType ?? .fade)
            }
        }, type: .insert))
    }
    
    func delete(section: Int) {
        addToOperations(operation: ProviderOperation(operation: BlockOperation {[weak self] in
            MainActor.assumeIsolated {
                self?.tableView.deleteSections(IndexSet(integer: section), with: self?.animationType ?? .fade)
            }
        }, type: .delete))
    }
    
    func update(section: Int) {
        addToOperations(operation: ProviderOperation(operation: BlockOperation {[weak self] in
            MainActor.assumeIsolated {
                self?.tableView.reloadSections(IndexSet(integer: section), with: self?.animationType ?? .fade)
            }
        }, type: .update))
    }
    
    private func addToOperations(operation: ProviderOperation) {
        operations.append(operation)
    }
    
    private func performBatchesOperations() {
        
        if operations.isEmpty {
            tableView.reloadData() // Need for case if table only had updates of cells, not inserts, deletes or moves.
            return
        }
        
        self.tableView.performBatchUpdates({[weak self] in
            self?.operations.forEach { $0.operation.start() }
        }, completion: {[weak self] (finished) -> Void in
            self?.operations.removeAll()
            DispatchQueue.main.async {
                self?.didFinishAnimation()
            }
        })
    }
}

public extension UITableView {
    
    func addLoadingIndicator() {
        
        if isLoading {
            return
        }
        
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.frame = activityIndicatorRect
        
        activityIndicator.startAnimating()
        tableFooterView = activityIndicator
    }
    
    func removeLoadingIndicator() {
        
        if isLoading {
            UIView.animate(withDuration: CATransaction.animationDuration(), animations: {
                self.tableFooterView = UIView()
            })
        }
    }
    
    var isLoading: Bool {
        return self.tableFooterView is UIActivityIndicatorView
    }
    
    private var activityIndicatorRect: CGRect {
        return CGRect(x: 0.0, y: 0.0, width: 20.0, height: 40.0)
    }
}
