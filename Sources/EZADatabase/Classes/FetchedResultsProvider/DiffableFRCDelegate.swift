//
//  File.swift
//  
//
//  Created by Eugeniy Zaychenko on 11/13/23.
//

import Foundation
import Combine
import CoreData
import UIKit

class DiffableFRCDelegate: NSObject, NSFetchedResultsControllerDelegate {
    
    let snapshotChangePublisher: PassthroughSubject<NSDiffableDataSourceSnapshotReference, Never> = .init()
    
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        snapshotChangePublisher.send(snapshot)
    }
}
