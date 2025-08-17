import XCTest
import CoreData
@testable import DataLayer

final class CoreDataStackTests: XCTestCase {
    
    var coreDataStack: CoreDataStack!
    
    override func setUp() {
        super.setUp()
        // Use in-memory store for testing
        coreDataStack = CoreDataStack.shared
    }
    
    override func tearDown() {
        coreDataStack = nil
        super.tearDown()
    }
    
    func testPersistentContainerInitialization() {
        // Given & When
        let container = coreDataStack.persistentContainer
        
        // Then
        XCTAssertNotNil(container)
        XCTAssertEqual(container.name, "MindMapDataModel")
    }
    
    func testViewContextConfiguration() {
        // Given & When
        let viewContext = coreDataStack.viewContext
        
        // Then
        XCTAssertNotNil(viewContext)
        XCTAssertTrue(viewContext.automaticallyMergesChangesFromParent)
        XCTAssertNotNil(viewContext.mergePolicy)
    }
    
    func testBackgroundContextCreation() {
        // Given & When
        let backgroundContext = coreDataStack.newBackgroundContext()
        
        // Then
        XCTAssertNotNil(backgroundContext)
        XCTAssertNotNil(backgroundContext.mergePolicy)
        XCTAssertNotEqual(backgroundContext, coreDataStack.viewContext)
    }
    
    func testSaveContext() throws {
        // Given
        let context = coreDataStack.viewContext
        
        // When & Then
        XCTAssertNoThrow(try coreDataStack.saveContext(context))
    }
}