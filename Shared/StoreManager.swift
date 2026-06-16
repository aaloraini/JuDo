import StoreKit
import Combine
import Foundation

@MainActor
final class StoreManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var isPurchasing = false
    @Published var purchaseError: String?

    var onPurchaseComplete: ((Int) async -> Void)?

    private var transactionListener: _Concurrency.Task<Void, Error>?

    init() {
        transactionListener = _Concurrency.Task.detached {
            for await result in Transaction.updates {
                guard case .verified(let tx) = result else { continue }
                await tx.finish()
            }
        }
    }

    deinit { transactionListener?.cancel() }

    func loadProducts() async {
        let ids = Set(MonTier.all.map(\.id))
        guard let fetched = try? await Product.products(for: ids) else { return }
        products = fetched.sorted { a, b in
            (MonTier.all.first(where: { $0.id == a.id })?.monAmount ?? 0) <
            (MonTier.all.first(where: { $0.id == b.id })?.monAmount ?? 0)
        }
    }

    func purchase(_ product: Product) async {
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let tx) = verification else {
                    purchaseError = "Purchase could not be verified"
                    return
                }
                let amount = MonTier.all.first(where: { $0.id == product.id })?.monAmount ?? 1
                await onPurchaseComplete?(amount)
                await tx.finish()
            case .pending, .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }
}
