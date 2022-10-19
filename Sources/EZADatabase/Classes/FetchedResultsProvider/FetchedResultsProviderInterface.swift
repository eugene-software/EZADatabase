//
//  FetchedResultsControllerProviderProtocol.swift
//   EZADatabase
//
//  Created by Eugene Software on 12/13/18.
//

import Foundation


public protocol FetchedResultsProviderInterface: AnyObject {
    
    ///Returns all fetched objects
    ///
    var allObjects: [Any]? { get }
    
    ///Returns a boolean value that indicated whether content exist or not
    ///
    var contentExist: Bool { get }
    
    /// Adds limit.
    /// - Parameters:
    ///   - limit: an objects count limit, if nil - unlimited
    ///
    func configure(limit: Int?)
    
    /// Adds predicate.
    /// - Parameters:
    ///   - predicate: predicate object for fetch request
    ///
    func add(predicate: NSPredicate?)
    
    /// Updates FRC with current predicate.
    /// - Parameters:
    ///   - predicate: predicate object for fetch request
    ///
    func update(with predicate: NSPredicate?)
    
    /// Returns an object by passed indexPath
    /// - Parameters:
    ///   - indexPath: indexPath object
    /// - Returns: an object for this indexPath if exist, otherwise nil
    ///
    func object(at indexPath: IndexPath) -> Any?
    
    /// Returns a number of items in section
    /// - Parameters:
    ///   - section: section number
    /// - Returns: number of items in section if exist, otherwise nil
    ///
    func numberOfItems(in section: Int) -> Int?
    
    /// Returns a title of section
    /// - Parameters:
    ///   - section: section number
    /// - Returns: a title of section if exist, otherwise nil
    ///
    func title(for section: Int) -> String?
    
    /// Returns a number of sections
    ///
    var numberOfSections: Int { get }
    
    /// Delegate callback
    ///
    var delegate: FetchedResultsProviderDelegate? { get set }
    
    func indexPathForObject(using predicate: NSPredicate) -> IndexPath?
}

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
