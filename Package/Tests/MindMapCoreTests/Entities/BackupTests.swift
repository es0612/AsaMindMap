import XCTest
@testable import MindMapCore

/// バックアップエンティティの単体テスト
/// Task 22: バックアップ・復元機能
final class BackupTests: XCTestCase {
    
    // MARK: - Backup Entity Tests
    
    func testBackupCreation() {
        // Given
        let mindMaps = [MindMap(title: "Test Map")]
        let backupType = BackupType.local
        
        // When
        let backup = Backup(
            mindMaps: mindMaps,
            type: backupType,
            version: "1.0"
        )
        
        // Then
        XCTAssertNotNil(backup.id)
        XCTAssertEqual(backup.mindMaps.count, 1)
        XCTAssertEqual(backup.type, .local)
        XCTAssertEqual(backup.version, "1.0")
        XCTAssertNotNil(backup.createdAt)
    }
    
    func testBackupMetadata() {
        // Given
        let mindMaps = [
            MindMap(title: "Map 1"),
            MindMap(title: "Map 2")
        ]
        
        // When
        let backup = Backup(
            mindMaps: mindMaps,
            type: .cloudKit,
            version: "1.0"
        )
        
        // Then
        XCTAssertEqual(backup.itemCount, 2)
        XCTAssertTrue(backup.estimatedSize > 0)
        XCTAssertEqual(backup.type, .cloudKit)
    }
    
    func testBackupValidation() {
        // Given
        let emptyMindMaps: [MindMap] = []
        
        // When & Then
        XCTAssertThrowsError(
            try Backup.validate(mindMaps: emptyMindMaps)
        ) { error in
            XCTAssertTrue(error is BackupError)
            XCTAssertEqual(error as? BackupError, .emptyBackup)
        }
    }
    
    // MARK: - BackupVersion Tests
    
    func testBackupVersionComparison() {
        // Given
        let version1 = BackupVersion("1.0")
        let version2 = BackupVersion("1.1")
        let version3 = BackupVersion("2.0")
        
        // When & Then
        XCTAssertTrue(version1 < version2)
        XCTAssertTrue(version2 < version3)
        XCTAssertFalse(version3 < version1)
        XCTAssertEqual(version1, BackupVersion("1.0"))
    }
    
    // MARK: - BackupManifest Tests
    
    func testBackupManifestCreation() {
        // Given
        let mindMaps = [MindMap(title: "Test")]
        let backup = Backup(
            mindMaps: mindMaps,
            type: .local,
            version: "1.0"
        )
        
        // When
        let manifest = BackupManifest(backup: backup)
        
        // Then
        XCTAssertEqual(manifest.backupId, backup.id)
        XCTAssertEqual(manifest.version, backup.version)
        XCTAssertEqual(manifest.itemCount, 1)
        XCTAssertNotNil(manifest.checksum)
    }
    
    func testBackupManifestIntegrity() {
        // Given
        let mindMaps = [MindMap(title: "Test")]
        let backup = Backup(
            mindMaps: mindMaps,
            type: .local,
            version: "1.0"
        )
        let manifest = BackupManifest(backup: backup)
        
        // When
        let isValid = manifest.verifyIntegrity(with: backup)
        
        // Then
        XCTAssertTrue(isValid)
    }
}