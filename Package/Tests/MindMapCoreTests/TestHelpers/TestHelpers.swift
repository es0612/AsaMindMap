import Testing
import Foundation
@testable import MindMapCore

// MARK: - Test Helper Functions
func expectValidationError<T>(
    _ operation: () async throws -> T,
    expectedMessage: String? = nil
) async {
    do {
        _ = try await operation()
        #expect(Bool(false), "Expected MindMapError.validationError to be thrown")
    } catch let error as MindMapError {
        switch error {
        case .validationError(let message):
            if let expectedMessage = expectedMessage {
                #expect(message == expectedMessage, "Expected message '\(expectedMessage)' but got '\(message)'")
            }
        default:
            #expect(Bool(false), "Expected validationError but got \(error)")
        }
    } catch {
        #expect(Bool(false), "Expected MindMapError but got \(error)")
    }
}

func expectValidationError<T>(
    _ operation: () async throws -> T
) async {
    await expectValidationError(operation, expectedMessage: nil)
}