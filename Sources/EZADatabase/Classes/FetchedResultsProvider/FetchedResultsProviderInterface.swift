//
//  FetchedResultsControllerProviderProtocol.swift
//   EZADatabase
//
//  Created by Eugene Software on 12/13/18.
//

import Foundation
import Combine
import UIKit


public protocol FetchedResultsProviderDelegate: AnyObject {
    
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


public extension NSDiffableDataSourceSnapshot where SectionIdentifierType == String {
    
    func mapObjects<T>(_ completion: (ItemIdentifierType) -> T?) -> NSDiffableDataSourceSnapshot<String, T> {
        
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
