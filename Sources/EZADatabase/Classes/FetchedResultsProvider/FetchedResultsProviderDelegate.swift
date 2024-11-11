//
//  FetchedResultsProviderDelegate.swift
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
import Combine
import UIKit


@MainActor public protocol FetchedResultsProviderDelegate: AnyObject, Sendable {
    
    func willUpdateList()
    func didUpdateList()
    
    func didReloadContent()
    
    func moveObject(from indexPath: IndexPath?, to newIndexPath: IndexPath?)
    func insertObject(at indexPath: IndexPath?)
    func deleteObject(at indexPath: IndexPath?)
    func updateObject(at indexPath: IndexPath?)
    
    func insert(section: Int)
    func delete(section: Int)
    func update(section: Int)
}

public extension FetchedResultsProviderDelegate {
    
    func willUpdateList() {}
    func didUpdateList() {}
    func didReloadContent() {}
    func moveObject(from indexPath: IndexPath?, to newIndexPath: IndexPath?) {}
    func insertObject(at indexPath: IndexPath?) {}
    func deleteObject(at indexPath: IndexPath?) {}
    func updateObject(at indexPath: IndexPath?) {}
    func insert(section: Int) {}
    func delete(section: Int) {}
    func update(section: Int) {}
}

@MainActor public struct ProviderOperation {
    
    enum OperationType {
        case insert, delete, update, move
    }
    let operation: BlockOperation
    let type: OperationType
}


public extension NSDiffableDataSourceSnapshot where SectionIdentifierType == String {
    
    func mapObjects<T: Sendable>(_ completion: (ItemIdentifierType) -> T?) -> NSDiffableDataSourceSnapshot<String, T> {
        
        var another: NSDiffableDataSourceSnapshot<String, T> = .init()
        another.appendSections(self.sectionIdentifiers)
        self.sectionIdentifiers.forEach {
            let items = self.itemIdentifiers(inSection: $0)
                .compactMap { item in
                    return completion(item)
                }
            another.appendItems(items, toSection: $0)
        }
        return another
    }
    
    func item(at indexPath: IndexPath) -> ItemIdentifierType {
        let section = self.sectionIdentifiers[indexPath.section]
        let item = self.itemIdentifiers(inSection: section)[indexPath.item]
        return item
    }
    
    func numberOfItems(in section: Int) -> Int {
        let section = self.sectionIdentifiers[section]
        return  self.itemIdentifiers(inSection: section).count
    }
}
