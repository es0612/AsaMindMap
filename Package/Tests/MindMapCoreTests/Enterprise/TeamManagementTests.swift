import Testing
@testable import MindMapCore

@Suite("Team Management Tests")
struct TeamManagementTests {
    
    @Test("チーム作成テスト")
    func testTeamCreation() async throws {
        // Given
        let teamManager = TeamManager()
        let teamName = "Engineering Team"
        let adminUserID = "admin@company.com"
        
        // When
        let team = try await teamManager.createTeam(
            name: teamName,
            adminUserID: adminUserID
        )
        
        // Then
        #expect(team.name == teamName)
        #expect(team.adminUserID == adminUserID)
        #expect(team.members.isEmpty)
        #expect(team.permissions.isEmpty)
        #expect(team.id != nil)
    }
    
    @Test("チームメンバーの追加テスト")
    func testAddTeamMember() async throws {
        // Given
        let teamManager = TeamManager()
        let team = try await teamManager.createTeam(
            name: "Test Team",
            adminUserID: "admin@company.com"
        )
        let newMemberID = "member@company.com"
        
        // When
        let updatedTeam = try await teamManager.addMember(
            to: team.id,
            userID: newMemberID,
            role: .member
        )
        
        // Then
        #expect(updatedTeam.members.count == 1)
        #expect(updatedTeam.members.first?.userID == newMemberID)
        #expect(updatedTeam.members.first?.role == .member)
    }
    
    @Test("権限の設定テスト")
    func testPermissionAssignment() async throws {
        // Given
        let permissionManager = PermissionManager()
        let userID = "user@company.com"
        let resource = MindMapResource(id: UUID(), type: .mindMap)
        
        // When
        try await permissionManager.grantPermission(
            to: userID,
            for: resource,
            permission: .readWrite
        )
        
        // Then
        let permissions = try await permissionManager.getPermissions(for: userID)
        #expect(permissions.count == 1)
        #expect(permissions.first?.resource.id == resource.id)
        #expect(permissions.first?.permission == .readWrite)
    }
    
    @Test("権限の継承テスト")
    func testPermissionInheritance() async throws {
        // Given
        let permissionManager = PermissionManager()
        let parentResource = MindMapResource(id: UUID(), type: .folder)
        let childResource = MindMapResource(id: UUID(), type: .mindMap, parentID: parentResource.id)
        let userID = "user@company.com"
        
        // 親リソースに権限を設定
        try await permissionManager.grantPermission(
            to: userID,
            for: parentResource,
            permission: .admin
        )
        
        // When
        let effectivePermission = try await permissionManager.getEffectivePermission(
            for: userID,
            resource: childResource
        )
        
        // Then
        #expect(effectivePermission == .admin)
    }
    
    @Test("アクセス制御の検証テスト")
    func testAccessControl() async throws {
        // Given
        let accessController = AccessController()
        let userID = "user@company.com"
        let resource = MindMapResource(id: UUID(), type: .mindMap)
        let action = ResourceAction.read
        
        // When
        let hasAccess = try await accessController.checkAccess(
            userID: userID,
            resource: resource,
            action: action
        )
        
        // Then
        #expect(!hasAccess) // デフォルトでアクセス拒否
    }
    
    @Test("ロールベースアクセス制御テスト")
    func testRoleBasedAccessControl() async throws {
        // Given
        let roleManager = RoleManager()
        let userID = "user@company.com"
        let role = Role.editor
        
        // When
        try await roleManager.assignRole(role, to: userID)
        let userRoles = try await roleManager.getUserRoles(userID)
        
        // Then
        #expect(userRoles.contains(role))
        
        // アクセス権限確認
        let accessController = AccessController()
        let resource = MindMapResource(id: UUID(), type: .mindMap)
        let hasReadAccess = try await accessController.checkAccess(
            userID: userID,
            resource: resource,
            action: .read
        )
        let hasEditAccess = try await accessController.checkAccess(
            userID: userID,
            resource: resource,
            action: .edit
        )
        
        #expect(hasReadAccess)
        #expect(hasEditAccess)
    }
    
    @Test("チーム権限の階層テスト")
    func testTeamPermissionHierarchy() async throws {
        // Given
        let teamManager = TeamManager()
        let team = try await teamManager.createTeam(
            name: "Parent Team",
            adminUserID: "admin@company.com"
        )
        
        let subTeam = try await teamManager.createSubTeam(
            parentTeamID: team.id,
            name: "Sub Team",
            adminUserID: "subadmin@company.com"
        )
        
        // When
        let hierarchy = try await teamManager.getTeamHierarchy(rootTeamID: team.id)
        
        // Then
        #expect(hierarchy.rootTeam.id == team.id)
        #expect(hierarchy.subTeams.count == 1)
        #expect(hierarchy.subTeams.first?.id == subTeam.id)
    }
    
    @Test("権限の取り消しテスト")
    func testPermissionRevocation() async throws {
        // Given
        let permissionManager = PermissionManager()
        let userID = "user@company.com"
        let resource = MindMapResource(id: UUID(), type: .mindMap)
        
        // 権限を付与
        try await permissionManager.grantPermission(
            to: userID,
            for: resource,
            permission: .readWrite
        )
        
        // When
        try await permissionManager.revokePermission(
            from: userID,
            for: resource
        )
        
        // Then
        let permissions = try await permissionManager.getPermissions(for: userID)
        #expect(permissions.isEmpty)
    }
    
    @Test("一時的権限の設定テスト")
    func testTemporaryPermissions() async throws {
        // Given
        let permissionManager = PermissionManager()
        let userID = "user@company.com"
        let resource = MindMapResource(id: UUID(), type: .mindMap)
        let duration = TimeInterval(3600) // 1時間
        
        // When
        try await permissionManager.grantTemporaryPermission(
            to: userID,
            for: resource,
            permission: .readWrite,
            duration: duration
        )
        
        // Then
        let permissions = try await permissionManager.getPermissions(for: userID)
        #expect(permissions.count == 1)
        #expect(permissions.first?.isTemporary == true)
        #expect(permissions.first?.expirationDate != nil)
    }
}