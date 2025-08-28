import SwiftUI
import Combine
import MindMapCore

@MainActor
public class PremiumAccessManager: ObservableObject {
    
    @Published public var hasPremium: Bool = false
    @Published public var activeSubscription: MindMapCore.Subscription?
    @Published public var shouldShowPaywall: Bool = false
    
    private let validateAccessUseCase: ValidatePremiumAccessUseCaseProtocol
    private let subscriptionStatusPublisher: AnyPublisher<SubscriptionStatus, Never>
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(
        validateAccessUseCase: ValidatePremiumAccessUseCaseProtocol,
        subscriptionStatusPublisher: AnyPublisher<SubscriptionStatus, Never>
    ) {
        self.validateAccessUseCase = validateAccessUseCase
        self.subscriptionStatusPublisher = subscriptionStatusPublisher
        
        setupSubscriptionStatusObserver()
    }
    
    private func setupSubscriptionStatusObserver() {
        subscriptionStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                Task {
                    await self?.handleSubscriptionStatusChange(status)
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleSubscriptionStatusChange(_ status: SubscriptionStatus) async {
        await refreshPremiumStatus()
    }
    
    public func refreshPremiumStatus() async {
        do {
            // Check any premium feature to get overall status
            let request = ValidatePremiumAccessRequest(feature: .advancedFormatting)
            let response = try await validateAccessUseCase.execute(request)
            
            hasPremium = response.hasAccess
            activeSubscription = response.subscription
        } catch {
            print("Failed to refresh premium status: \(error)")
            hasPremium = false
            activeSubscription = nil
        }
    }
    
    public func checkFeatureAccess(_ feature: PremiumFeature) async -> Bool {
        do {
            let request = ValidatePremiumAccessRequest(feature: feature)
            let response = try await validateAccessUseCase.execute(request)
            return response.hasAccess
        } catch {
            print("Failed to check feature access for \(feature): \(error)")
            return false
        }
    }
    
    public func requirePremiumAccess(for feature: PremiumFeature) async -> Bool {
        let hasAccess = await checkFeatureAccess(feature)
        
        if !hasAccess {
            shouldShowPaywall = true
        }
        
        return hasAccess
    }
    
    public func dismissPaywall() {
        shouldShowPaywall = false
    }
}

// MARK: - Premium Access Modifier

public struct PremiumAccessModifier: ViewModifier {
    let feature: PremiumFeature
    let fallbackContent: AnyView?
    
    @StateObject private var accessManager: PremiumAccessManager
    @State private var hasAccess: Bool = false
    @State private var isChecking: Bool = true
    
    init(
        feature: PremiumFeature,
        accessManager: PremiumAccessManager,
        fallbackContent: AnyView? = nil
    ) {
        self.feature = feature
        self.fallbackContent = fallbackContent
        self._accessManager = StateObject(wrappedValue: accessManager)
    }
    
    public func body(content: Content) -> some View {
        Group {
            if isChecking {
                ProgressView()
                    .scaleEffect(0.8)
            } else if hasAccess {
                content
            } else {
                fallbackContent ?? AnyView(
                    Button("プレミアム機能") {
                        accessManager.shouldShowPaywall = true
                    }
                    .foregroundColor(.blue)
                )
            }
        }
        .task {
            await checkAccess()
        }
    }
    
    private func checkAccess() async {
        hasAccess = await accessManager.checkFeatureAccess(feature)
        isChecking = false
    }
}

public extension View {
    func requiresPremium(
        _ feature: PremiumFeature,
        accessManager: PremiumAccessManager,
        fallback: AnyView? = nil
    ) -> some View {
        modifier(PremiumAccessModifier(
            feature: feature,
            accessManager: accessManager,
            fallbackContent: fallback
        ))
    }
}

// MARK: - Premium Gate View

public struct PremiumGateView: View {
    let feature: PremiumFeature
    let title: String
    let description: String
    let onUpgrade: () -> Void
    
    public init(
        feature: PremiumFeature,
        title: String,
        description: String,
        onUpgrade: @escaping () -> Void
    ) {
        self.feature = feature
        self.title = title
        self.description = description
        self.onUpgrade = onUpgrade
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "crown.fill")
                .font(.system(size: 50))
                .foregroundColor(.yellow)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("プレミアムにアップグレード") {
                onUpgrade()
            }
            .buttonStyle(.borderedProminent)
            .font(.headline)
        }
        .padding(32)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(16)
        .padding()
    }
}