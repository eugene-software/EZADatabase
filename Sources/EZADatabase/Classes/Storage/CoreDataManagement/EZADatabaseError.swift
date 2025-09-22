//
//  EZADatabaseError.swift
//  EZADatabase
//
//  Created by Eugene Software.
//

import Foundation

public enum EZADatabaseError: Error {
	case databaseNotInitialized
	case persistentContainerUnavailable
	case backgroundContextUnavailable
}

extension EZADatabaseError: LocalizedError {
	public var errorDescription: String? {
		switch self {
		case .databaseNotInitialized:
			return "Database not initialized. Call EZADatabase.openDatabase() first."
		case .persistentContainerUnavailable:
			return "Persistent container is unavailable. Ensure the store is loaded."
		case .backgroundContextUnavailable:
			return "Background context is unavailable. Ensure the store is loaded."
		}
	}
}


