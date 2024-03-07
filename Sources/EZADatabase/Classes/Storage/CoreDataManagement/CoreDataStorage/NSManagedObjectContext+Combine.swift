//
//  NSManagedObjectContext+Combine.swift
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
