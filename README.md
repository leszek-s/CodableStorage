![Logo](./logo.png)

# CodableStorage

**CodableStorage** is an easy to use key-value storage for objects conforming to the Codable protocol, backed by Core Data. Both read and save operations are asynchronous and do not block the main thread.

## Installation

To integrate **CodableStorage** into your Xcode project you can use Swift Package Manager or CocoaPods. Alternatively you can just manually drag and drop this library to your project.

## Basic usage

Saving, reading and removing data looks like in the example below.

```swift
struct Person: Codable {
    let name: String
    let age: Int
}

// [...]

Task { @MainActor in
    let storage = CodableStorage.default
    do {
        // save
        try await storage.setCodable(Person(name: "Peter", age: 25), forKey: "person")
        // read
        let person = try await storage.codable(forKey: "person", type: Person.self)
        // remove
        try await storage.setCodable(nil, forKey: "person")
    } catch {
        print("Error: \(error)")
    }
}
```

You can also save arrays with Codable objects in a similar way.

```swift
Task { @MainActor in
    let storage = CodableStorage.default
    do {
        // save
        let array = [Person(name: "John", age: 35), Person(name: "Kate", age: 30)]
        try await storage.setCodable(array, forKey: "people")
        // read
        let people = try await storage.codable(forKey: "people", type: [Person].self)
        // remove
        try await storage.setCodable(nil, forKey: "people")
    } catch {
        print("Error: \(error)")
    }
}
```

You can also get all currently stored keys using `allKeys()` and clear the entire storage using `clear()`. It is possible to create more `CodableStorage` instances by passing custom URLs to the initializer and then use multiple storages saved in custom locations if needed. You can also use methods with completion handlers if you need to support older system versions and can't use `Task`.

## License

**CodableStorage** is available under the MIT license.
