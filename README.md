![Logo](./logo.png)

# CodableStorage

**CodableStorage** is an easy to use key-value storage for objects conforming to Codable protocol backed by CoreData. Both read and save operations are asynchronous and do not block the main thread.

## Installation

To integrate CodableStorage into your Xcode project you can use Swift Package Manager. Alternatively you can just manually drag and drop this library to your project.

## Basic usage

Saving, reading and removing data looks like in the example below.

```
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

You can of course also save arrays with Codable objects in a similar way.

```
Task { @MainActor in
    let storage = CodableStorage.default
    do {
        // save
        try await storage.setCodable([Person(name: "John", age: 35), Person(name: "Kate", age: 30)], forKey: "people")
        
        // read
        let people = try await storage.codable(forKey: "people", type: [Person].self)
        
        // remove
        try await storage.setCodable(nil, forKey: "people")
    } catch {
        print("Error: \(error)")
    }
}
```

It is also possible to use non async methods with completion blocks instead if you need to support iOS 12 and can't use Task.

## License

CodableStorage is available under the MIT license.
