import StoreKit
import Combine
import Foundation

@MainActor
final class StoreManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var isPurchasing = false
    @Published var purchaseError: String?

    private let credit: (Int) async throws -> Void
    private var creditedTransactionIDs = Set<UInt64>()
    private var transactionListener: _Concurrency.Task<Void, Never>?

    init(credit: @escaping (Int) async throws -> Void) {
        self.credit = credit
        transactionListener = _Concurrency.Task.detached { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(result)
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

    /// Credits purchases that were paid for but never delivered, e.g. because
    /// the app quit mid-purchase or the leaderboard save failed.
    func recoverUnfinished() async {
        for await result in Transaction.unfinished {
            await handle(result)
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
                await handle(verification)
            case .pending, .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    /// Finishing a consumable tells StoreKit the content was delivered, so the
    /// transaction is only finished after the credit succeeds. On failure it is
    /// left unfinished and StoreKit redelivers it (see `recoverUnfinished`).
    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let tx) = result else {
            purchaseError = "Purchase could not be verified"
            return
        }
        guard !creditedTransactionIDs.contains(tx.id) else { return }
        creditedTransactionIDs.insert(tx.id)

        let amount = MonTier.all.first(where: { $0.id == tx.productID })?.monAmount ?? 1
        do {
            try await credit(amount)
            await tx.finish()
        } catch {
            creditedTransactionIDs.remove(tx.id)
            purchaseError = error.localizedDescription
        }
    }
}
