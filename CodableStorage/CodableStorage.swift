// Copyright (c) 2021 Leszek S
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import CoreData

/// Persistent storage for saving objects conforming to the Codable protocol.
public final class CodableStorage {
    private var managedObjectContext: NSManagedObjectContext?
    public private(set) var url: URL?
    
    public static let `default`: CodableStorage = CodableStorage()
    
    /// Initializes an instance of CodableStorage.
    /// - Parameter url: Optional url at which the database should be stored if we do not want use the default location.
    public init(url: URL? = nil) {
        let entity = NSEntityDescription()
        entity.name = "Data"
        
        let key = NSAttributeDescription()
        key.name = "key"
        key.attributeType = .stringAttributeType
        
        let value = NSAttributeDescription()
        value.name = "value"
        value.attributeType = .binaryDataAttributeType
        
        entity.properties = [key, value]
        entity.indexes = [NSFetchIndexDescription(name: "key", elements: [NSFetchIndexElementDescription(property: key, collationType: .binary)])]
        
        let managedObjectModel = NSManagedObjectModel()
        managedObjectModel.entities = [entity]
        
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        
        let defaultDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("CodableStorage")
        let defaultUrl = defaultDirectory?.appendingPathComponent("storage.db")
        
        guard let fileUrl = url ?? defaultUrl else {
            return
        }
        
        do {
            if fileUrl == defaultUrl, let defaultDirectory = defaultDirectory {
                try FileManager.default.createDirectory(at: defaultDirectory, withIntermediateDirectories: true, attributes: nil)
            }
            try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: fileUrl, options: nil)
        } catch {
            return
        }
        
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        
        self.managedObjectContext = managedObjectContext
        self.url = fileUrl
    }
    
    /// Retrieves codable with given type stored with given key.
    /// - Parameters:
    ///   - key: The key used to store codable.
    ///   - type: The codable type which should be used for decoding.
    ///   - completion: Completion block.
    public func codable<T: Codable>(forKey key: String, type: T.Type, completion: @escaping (T?, Error?) -> Void) {
        guard let managedObjectContext = managedObjectContext else {
            completion(nil, StorageError.initializationFailed)
            return
        }
        managedObjectContext.perform {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Data")
            fetchRequest.predicate = NSPredicate(format: "key == %@", key)
            var result: [NSManagedObject]?
            var err: Error?
            var codable: T?
            do {
                result = try managedObjectContext.fetch(fetchRequest) as? [NSManagedObject]
                if let data = result?.first?.value(forKey: "value") as? Data {
                    codable = try JSONDecoder().decode(type, from: data)
                }
            } catch {
                err = error
            }

            DispatchQueue.main.async {
                completion(codable, err)
            }
        }
    }
    
    /// Stores codable with given key.
    /// - Parameters:
    ///   - codable: The codable to store.
    ///   - key: The key used to store codable.
    ///   - completion: Completion block.
    public func setCodable(_ codable: Codable?, forKey key: String, completion: @escaping (Error?) -> Void) {
        guard let managedObjectContext = managedObjectContext else {
            completion(StorageError.initializationFailed)
            return
        }
        managedObjectContext.perform {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Data")
            fetchRequest.predicate = NSPredicate(format: "key == %@", key)
            var result: [NSManagedObject]?
            var err: Error?
            do {
                result = try managedObjectContext.fetch(fetchRequest) as? [NSManagedObject]
                if let codable = codable {
                    let data = try JSONEncoder().encode(codable)
                    result?.forEach({ managedObjectContext.delete($0) })
                    let object = NSEntityDescription.insertNewObject(forEntityName:"Data", into: managedObjectContext)
                    object.setValue(key, forKey: "key")
                    object.setValue(data, forKey: "value")
                } else {
                    result?.forEach({ managedObjectContext.delete($0) })
                }
                try managedObjectContext.save()
            } catch {
                managedObjectContext.rollback()
                err = error
            }
            DispatchQueue.main.async {
                completion(err)
            }
        }
    }
    
    /// Removes all stored data.
    /// - Parameter completion: Completion block.
    public func clear(completion: @escaping (Error?) -> Void) {
        guard let managedObjectContext = managedObjectContext else {
            completion(StorageError.initializationFailed)
            return
        }
        managedObjectContext.perform {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Data")
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            var err: Error?
            do {
                try managedObjectContext.execute(deleteRequest)
                try managedObjectContext.save()
            } catch {
                managedObjectContext.rollback()
                err = error
            }
            DispatchQueue.main.async {
                completion(err)
            }
        }
    }
    
    /// Retrieves codable with given type stored with given key.
    /// - Parameters:
    ///   - key: The key used to store codable.
    ///   - type: The codable type which should be used for decoding.
    /// - Returns: Codable with given type stored with given key.
    @available(iOS 13.0, *)
    public func codable<T: Codable>(forKey key: String, type: T.Type) async throws -> T? {
        return try await withCheckedThrowingContinuation { continuation in
            codable(forKey: key, type: type) { codable, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: codable)
                }
            }
        }
    }
    
    /// Stores codable with given key.
    /// - Parameters:
    ///   - codable: The codable to store.
    ///   - key: The key used to store codable.
    @available(iOS 13.0, *)
    public func setCodable(_ codable: Codable?, forKey key: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            setCodable(codable, forKey: key) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    /// Stores codable with given key.
    /// - Parameters:
    ///   - codable: The codable to store.
    ///   - key: The key used to store codable.
    @available(iOS 13.0, *)
    public func clear() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            clear() { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    /// Storage errors.
    enum StorageError: Error {
        case initializationFailed
    }
}
