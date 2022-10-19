//
//  NSPredicate+ext.swift
//  EZADatabase
//
//  Created by Eugene Software on 11/15/21.
//

import Foundation

public extension NSPredicate {
    
    enum CompoundType {
        case and
        case or
    }
    
    convenience init(key: String, value: Any) {
        
        if let date = value as? Date {
            self.init(format: "\(key) == %@", date as CVarArg)
        } else if let string = value as? String {
            self.init(format: "\(key) == %@", string)
        } else {
            self.init(format: "\(key) == \(value)")
        }
    }
    
    convenience init(id: Any) {
        self.init(key: "id", value: id)
    }
    
    static func dateRangePredicate(from: Date, to: Date) -> NSPredicate {
        
        let fromPredicate = NSPredicate(format: "date >= %@", from as CVarArg)
        let toPredicate = NSPredicate(format: "date < %@", to as CVarArg)
        let datePredicate = fromPredicate.appending(predicate: toPredicate, type: .and)
        
        return datePredicate
    }
    
    func appending(predicate: NSPredicate?, type: CompoundType) -> NSPredicate {
        
        guard let toAppend = predicate else { return self }
        
        switch type {
        case .and: return NSCompoundPredicate(andPredicateWithSubpredicates: [self, toAppend])
        case .or: return NSCompoundPredicate(orPredicateWithSubpredicates: [self, toAppend])
        }
    }
}
