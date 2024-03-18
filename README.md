# EZADatabase

[![Version](https://img.shields.io/cocoapods/v/EZADatabase.svg?style=flat)](https://cocoapods.org/pods/EZADatabase)
[![License](https://img.shields.io/cocoapods/l/EZADatabase.svg?style=flat)](https://cocoapods.org/pods/EZADatabase)
[![Platform](https://img.shields.io/cocoapods/p/EZADatabase.svg?style=flat)](https://cocoapods.org/pods/EZADatabase)

## Requirements

- iOS 13 and above

## Usage Example

Import dependenices:

```swift
import Combine
import EZADatabase
```

In AppDelegate run setup method:

```swift
func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    EZADatabase
            .openDatabase(in: application)
            .sink { _ in }
            .store(in: &cancellables)
    return true
}
```

Create CoreDataCompatible struct that reflects a CoreData model:

```swift

struct User: Codable, Hashable {
    
    var userId: String
    var userName: String
}

extension User: CoreDataCompatible {
    
    typealias ManagedType = CoreDataUser
    
    var primaryKey: Any {
        return userId
    }
    
    var primaryKeyName: String {
        return "userId"
    }
    
    init(managedObject: CoreDataUser) {
        
        userId = managedObject.userId
        userName = managedObject.userName
    }
}
```

Create NSManagedObject subclass that conforms to CoreDataExportable and reflects a CoreDataCompatible model:

```swift
@objc(CoreDataUser)
class CoreDataUser: NSManagedObject {

    @NSManaged var userId: String
    @NSManaged var userName: String
}

extension CoreDataUser : CoreDataExportable {
    
    typealias ExportType = User
    
    func configure(with object: User, in storage: EZADatabase.CoreDataStorageInterface) {
        
        userId = object.userId
        userName = object.userName
    }
    
    func getObject() -> Device {
        User(managedObject: self)
    }
}
```

- To store an object:

```swift

let user = User(userId: "someId", userName: "John")

EZAWriter.importRemoteList([user])
    .sink { completion in
        
    } receiveValue: { _ in
        
    }
    .store(in: &cancellables)
```

- To receive an object:

```swift

EZAReader.exportRemoteList(predicate: NSPredicate(key: "userId", value: "someId"))
    .sink { completion in
        
    } receiveValue: { user in
        print(user)
    }
    .store(in: &cancellables)
```

## Installation

### Cocoapods
EZADatabase is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'EZADatabase'
```

### Swift Package Manager
1. Right click in the Project Navigator
2. Select "Add Packages..."
3. Search for ```https://github.com/eugene-software/EZADatabase.git```

## Author

Eugene Software

## License

EZADatabase is available under the MIT license. See the LICENSE file for more info.
