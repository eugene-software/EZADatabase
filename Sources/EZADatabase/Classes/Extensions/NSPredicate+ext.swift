//
//  NSPredicate+ext.swift
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
