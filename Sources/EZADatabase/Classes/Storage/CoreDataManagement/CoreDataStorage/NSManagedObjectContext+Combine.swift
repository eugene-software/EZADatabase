//
//  File.swift
//
//
//  Created by Eugeniy Zaychenko on 2/13/24.
//

import Foundation
import CoreData
import Combine

extension NSManagedObjectContext {
    
    func publisher<T: NSManagedObject>(predicate: NSPredicate? = nil, sort: [NSSortDescriptor]? = nil) -> AnyPublisher<[T], Error> {
        let request = NSFetchRequest<T>(entityName: String(describing: T.self))
        request.predicate = predicate
        request.sortDescriptors = sort
        return FetchPublisher(request: request, context: self)
            .eraseToAnyPublisher()
    }
}

struct FetchPublisher<T: NSManagedObject>: Publisher {
    typealias Output = [T]
    typealias Failure = Error
    
    let request: NSFetchRequest<T>
    let context: NSManagedObjectContext
    
    func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = FetchSubscription(request: request, context: context, subscriber: subscriber)
        subscriber.receive(subscription: subscription)
    }
}

class FetchSubscription<T: NSManagedObject, S: Subscriber>: NSObject, Subscription, NSFetchedResultsControllerDelegate
where S.Input == [T], S.Failure == Error {
    private var request: NSFetchRequest<T>
    private var context: NSManagedObjectContext
    private var subscriber: S?
    private var cancellable: AnyCancellable?
    private var resultsController: NSFetchedResultsController<T>?
    
    init(request: NSFetchRequest<T>, context: NSManagedObjectContext, subscriber: S) {
        
        self.request = request
        self.context = context
        self.subscriber = subscriber
        super.init()
        setupObserver()
    }
    
    private func setupObserver() {
        resultsController = .init(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        resultsController?.delegate = self
        do {
            try resultsController?.performFetch()
            _ = self.subscriber?.receive(resultsController?.fetchedObjects ?? [])
        } catch {
            self.subscriber?.receive(completion: .failure(error))
        }
    }
    
    func request(_ demand: Subscribers.Demand) {
        // No implementation needed, we fetch data on changes automatically
    }
    
    func cancel() {
        subscriber = nil
        cancellable?.cancel()
    }
    
    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        _ = self.subscriber?.receive(resultsController?.fetchedObjects ?? [])
    }
}
