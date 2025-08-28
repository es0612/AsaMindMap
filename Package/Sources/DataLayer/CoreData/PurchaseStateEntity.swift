import Foundation
import CoreData

@objc(PurchaseStateEntity)
public class PurchaseStateEntity: NSManagedObject {
    
    // New purchase state fields
    @NSManaged public var id: String?
    @NSManaged public var productId: String?
    @NSManaged public var transactionId: String?
    @NSManaged public var originalTransactionId: String?
    @NSManaged public var purchaseDate: Date?
    @NSManaged public var isActive: Bool
    @NSManaged public var expirationDate: Date?
    @NSManaged public var isRestored: Bool
    @NSManaged public var validationStatus: String
    @NSManaged public var lastValidated: Date?
    
    // Legacy fields (kept for migration compatibility)
    @NSManaged public var lastUpdated: Date
    @NSManaged public var hasActiveSubscription: Bool
    @NSManaged public var subscriptionProductId: String?
    @NSManaged public var subscriptionIsActive: Bool
    @NSManaged public var subscriptionExpirationDate: Date?
    @NSManaged public var subscriptionAutoRenewing: Bool
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        self.id = UUID().uuidString
        self.lastUpdated = Date()
        self.lastValidated = Date()
        self.isActive = false
        self.isRestored = false
        self.hasActiveSubscription = false
        self.subscriptionIsActive = false
        self.subscriptionAutoRenewing = false
        self.validationStatus = "unknown"
    }
}

extension PurchaseStateEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<PurchaseStateEntity> {
        return NSFetchRequest<PurchaseStateEntity>(entityName: "PurchaseStateEntity")
    }
    
}