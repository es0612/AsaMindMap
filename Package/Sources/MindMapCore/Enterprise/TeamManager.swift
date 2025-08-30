import Foundation
import Combine

// MARK: - Team Manager

public final class TeamManager {
    private var teams: [UUID: Team] = [:]
    private let teamQueue = DispatchQueue(label: "enterprise.team.queue", attributes: .concurrent)
    
    public init() {}
    
    public func createTeam(name: String, adminUserID: String) async throws -> Team {
        return try await withCheckedThrowingContinuation { continuation in
            teamQueue.async(flags: .barrier) {
                let team = Team(name: name, adminUserID: adminUserID)
                self.teams[team.id] = team
                continuation.resume(returning: team)
            }
        }
    }
    
    public func createSubTeam(parentTeamID: UUID, name: String, adminUserID: String) async throws -> Team {
        return try await withCheckedThrowingContinuation { continuation in
            teamQueue.async(flags: .barrier) {
                guard self.teams[parentTeamID] != nil else {
                    continuation.resume(throwing: NSError(
                        domain: "TeamManager",
                        code: 404,
                        userInfo: [NSLocalizedDescriptionKey: "Parent team not found"]
                    ))
                    return
                }
                
                let subTeam = Team(name: name, adminUserID: adminUserID)
                self.teams[subTeam.id] = subTeam
                continuation.resume(returning: subTeam)
            }
        }
    }
    
    public func addMember(to teamID: UUID, userID: String, role: TeamRole) async throws -> Team {
        return try await withCheckedThrowingContinuation { continuation in
            teamQueue.async(flags: .barrier) {
                guard var team = self.teams[teamID] else {
                    continuation.resume(throwing: NSError(
                        domain: "TeamManager",
                        code: 404,
                        userInfo: [NSLocalizedDescriptionKey: "Team not found"]
                    ))
                    return
                }
                
                let member = TeamMember(userID: userID, role: role)
                team.members.append(member)
                team.updatedAt = Date()
                self.teams[teamID] = team
                
                continuation.resume(returning: team)
            }
        }
    }
    
    public func removeMember(from teamID: UUID, userID: String) async throws -> Team {
        return try await withCheckedThrowingContinuation { continuation in
            teamQueue.async(flags: .barrier) {
                guard var team = self.teams[teamID] else {
                    continuation.resume(throwing: NSError(
                        domain: "TeamManager",
                        code: 404,
                        userInfo: [NSLocalizedDescriptionKey: "Team not found"]
                    ))
                    return
                }
                
                team.members.removeAll { $0.userID == userID }
                team.updatedAt = Date()
                self.teams[teamID] = team
                
                continuation.resume(returning: team)
            }
        }
    }
    
    public func getTeam(_ teamID: UUID) async throws -> Team {
        return try await withCheckedThrowingContinuation { continuation in
            teamQueue.async {
                if let team = self.teams[teamID] {
                    continuation.resume(returning: team)
                } else {
                    continuation.resume(throwing: NSError(
                        domain: "TeamManager",
                        code: 404,
                        userInfo: [NSLocalizedDescriptionKey: "Team not found"]
                    ))
                }
            }
        }
    }
    
    public func getTeamHierarchy(rootTeamID: UUID) async throws -> TeamHierarchy {
        return try await withCheckedThrowingContinuation { continuation in
            teamQueue.async {
                guard let rootTeam = self.teams[rootTeamID] else {
                    continuation.resume(throwing: NSError(
                        domain: "TeamManager",
                        code: 404,
                        userInfo: [NSLocalizedDescriptionKey: "Root team not found"]
                    ))
                    return
                }
                
                // For simplicity, just return all other teams as sub-teams
                let subTeams = Array(self.teams.values.filter { $0.id != rootTeamID })
                let hierarchy = TeamHierarchy(rootTeam: rootTeam, subTeams: subTeams)
                
                continuation.resume(returning: hierarchy)
            }
        }
    }
    
    public func getUserTeams(userID: String) async throws -> [Team] {
        return try await withCheckedThrowingContinuation { continuation in
            teamQueue.async {
                let userTeams = self.teams.values.filter { team in
                    team.adminUserID == userID || team.members.contains { $0.userID == userID }
                }
                continuation.resume(returning: Array(userTeams))
            }
        }
    }
}

// MARK: - Permission Manager

public final class PermissionManager {
    private var permissions: [String: [ResourcePermission]] = [:]
    private let permissionQueue = DispatchQueue(label: "enterprise.permission.queue", attributes: .concurrent)
    
    public init() {}
    
    public func grantPermission(
        to userID: String,
        for resource: MindMapResource,
        permission: Permission
    ) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            permissionQueue.async(flags: .barrier) {
                let resourcePermission = ResourcePermission(
                    userID: userID,
                    resource: resource,
                    permission: permission
                )
                
                if self.permissions[userID] == nil {
                    self.permissions[userID] = []
                }
                
                // Remove existing permission for same resource
                self.permissions[userID]?.removeAll { $0.resource.id == resource.id }
                
                // Add new permission
                self.permissions[userID]?.append(resourcePermission)
                
                continuation.resume()
            }
        }
    }
    
    public func grantTemporaryPermission(
        to userID: String,
        for resource: MindMapResource,
        permission: Permission,
        duration: TimeInterval
    ) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            permissionQueue.async(flags: .barrier) {
                let expirationDate = Date().addingTimeInterval(duration)
                let resourcePermission = ResourcePermission(
                    userID: userID,
                    resource: resource,
                    permission: permission,
                    isTemporary: true,
                    expirationDate: expirationDate
                )
                
                if self.permissions[userID] == nil {
                    self.permissions[userID] = []
                }
                
                // Remove existing permission for same resource
                self.permissions[userID]?.removeAll { $0.resource.id == resource.id }
                
                // Add new temporary permission
                self.permissions[userID]?.append(resourcePermission)
                
                continuation.resume()
            }
        }
    }
    
    public func revokePermission(from userID: String, for resource: MindMapResource) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            permissionQueue.async(flags: .barrier) {
                self.permissions[userID]?.removeAll { $0.resource.id == resource.id }
                continuation.resume()
            }
        }
    }
    
    public func getPermissions(for userID: String) async throws -> [ResourcePermission] {
        return try await withCheckedThrowingContinuation { continuation in
            permissionQueue.async {
                let userPermissions = self.permissions[userID] ?? []
                
                // Filter out expired temporary permissions
                let validPermissions = userPermissions.filter { permission in
                    if permission.isTemporary,
                       let expirationDate = permission.expirationDate,
                       Date() > expirationDate {
                        return false
                    }
                    return true
                }
                
                continuation.resume(returning: validPermissions)
            }
        }
    }
    
    public func getEffectivePermission(for userID: String, resource: MindMapResource) async throws -> Permission? {
        return try await withCheckedThrowingContinuation { continuation in
            permissionQueue.async {
                let userPermissions = self.permissions[userID] ?? []
                
                // Check direct permission first
                if let directPermission = userPermissions.first(where: { $0.resource.id == resource.id }) {
                    // Check if temporary permission is still valid
                    if directPermission.isTemporary,
                       let expirationDate = directPermission.expirationDate,
                       Date() > expirationDate {
                        continuation.resume(returning: nil)
                        return
                    }
                    continuation.resume(returning: directPermission.permission)
                    return
                }
                
                // Check inherited permission from parent resources
                if let parentID = resource.parentID {
                    let parentResource = MindMapResource(id: parentID, type: .folder)
                    if let parentPermission = userPermissions.first(where: { $0.resource.id == parentID }) {
                        continuation.resume(returning: parentPermission.permission)
                        return
                    }
                }
                
                continuation.resume(returning: nil)
            }
        }
    }
}

// MARK: - Access Controller

public final class AccessController {
    private let permissionManager: PermissionManager
    private let roleManager: RoleManager
    
    public init(permissionManager: PermissionManager = PermissionManager(),
               roleManager: RoleManager = RoleManager()) {
        self.permissionManager = permissionManager
        self.roleManager = roleManager
    }
    
    public func checkAccess(
        userID: String,
        resource: MindMapResource,
        action: ResourceAction
    ) async throws -> Bool {
        let requiredPermission = action.requiredPermission
        
        // Check direct resource permissions
        if let effectivePermission = try await permissionManager.getEffectivePermission(
            for: userID,
            resource: resource
        ) {
            return effectivePermission.level >= requiredPermission.level
        }
        
        // Check role-based permissions
        let userRoles = try await roleManager.getUserRoles(userID)
        for role in userRoles {
            if role.permissions.contains(where: { $0.level >= requiredPermission.level }) {
                return true
            }
        }
        
        return false
    }
    
    public func hasPermission(userID: String, permission: Permission, for resource: MindMapResource) async throws -> Bool {
        if let effectivePermission = try await permissionManager.getEffectivePermission(
            for: userID,
            resource: resource
        ) {
            return effectivePermission.level >= permission.level
        }
        return false
    }
}

// MARK: - Role Manager

public final class RoleManager {
    private var userRoles: [String: Set<Role>] = [:]
    private let roleQueue = DispatchQueue(label: "enterprise.role.queue", attributes: .concurrent)
    
    public init() {}
    
    public func assignRole(_ role: Role, to userID: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            roleQueue.async(flags: .barrier) {
                if self.userRoles[userID] == nil {
                    self.userRoles[userID] = Set<Role>()
                }
                self.userRoles[userID]?.insert(role)
                continuation.resume()
            }
        }
    }
    
    public func removeRole(_ role: Role, from userID: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            roleQueue.async(flags: .barrier) {
                self.userRoles[userID]?.remove(role)
                continuation.resume()
            }
        }
    }
    
    public func getUserRoles(_ userID: String) async throws -> [Role] {
        return try await withCheckedThrowingContinuation { continuation in
            roleQueue.async {
                let roles = Array(self.userRoles[userID] ?? Set<Role>())
                continuation.resume(returning: roles)
            }
        }
    }
    
    public func hasRole(_ role: Role, userID: String) async throws -> Bool {
        let userRoles = try await getUserRoles(userID)
        return userRoles.contains(role)
    }
    
    public func getUsersWithRole(_ role: Role) async throws -> [String] {
        return try await withCheckedThrowingContinuation { continuation in
            roleQueue.async {
                let users = self.userRoles.compactMap { (userID, roles) in
                    roles.contains(role) ? userID : nil
                }
                continuation.resume(returning: users)
            }
        }
    }
}