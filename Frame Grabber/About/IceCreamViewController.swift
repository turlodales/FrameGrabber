import UIKit
import StoreKit

// Messages + German
// Font sizes and dynamic
// Test: flag purchased = yes

// Commit everything
// Dont use error message in alert: Not localized
// Test "real" purchase flow
// Test iPhone SE
// COMPLETE

class IceCreamViewController: UIViewController {

    var hasPurchased: Bool {
        paymentsManager.hasPurchasedProduct(withId: inAppPurchaseId)
    }

    var fetchedProduct: SKProduct? {
        productsManager.fetchedProducts.first { $0.productIdentifier == inAppPurchaseId }
    }

    private let inAppPurchaseId = About.inAppPurchaseIdentifier
    private let productsManager = StoreProductsManager()
    private let paymentsManager = StorePaymentsManager.shared

    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var messageLabel: UILabel!
    @IBOutlet private var purchaseButton: ActivityButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureStoreManagers()
        configureViews()
        fetchProductsIfNeeded()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        transitionCoordinator?.animate(alongsideTransition: { [weak self] _ in
            self?.styleNavigationBar()
        }, completion: { [weak self] _ in
            self?.styleNavigationBar()
        })
    }

    // MARK: Actions

    private func fetchProductsIfNeeded() {
        if !hasPurchased,
            !productsManager.isFetchingProducts {

            productsManager.fetchProducts(with: [inAppPurchaseId])
        }

        updateViews()
    }

    @IBAction private func restore() {
        defer { updateViews() }

        guard paymentsManager.canMakePayments else {
            presentAlert(.restoreNotAllowed())
            return
        }

        paymentsManager.restore()
    }

    @IBAction private func purchase() {
        defer { updateViews() }

        guard !hasPurchased,
            !paymentsManager.hasPendingUnfinishedTransactions(withId: inAppPurchaseId) else {
                return
        }

        guard paymentsManager.canMakePayments else {
            presentAlert(.purchaseNotAllowed())
            return
        }

        guard let product = fetchedProduct else {
            presentAlert(.productNotFetched())
            fetchProductsIfNeeded()  // Retry.
            return
        }

        paymentsManager.purchase(product)
    }

    // MARK: Configuring

    private func configureViews() {
        purchaseButton.tintColor = .white
        purchaseButton.backgroundColor = Style.Color.iceCream
        purchaseButton.layer.cornerRadius = Style.Size.buttonCornerRadius
        purchaseButton.activityIndicator.color = .white

        titleLabel.font = UIFont.preferredFont(forTextStyle: .title1, size: 36, weight: .semibold)

        updateViews()
    }

    private func updateViews() {
        let hasPurchasedTitle = NSLocalizedString("icecream.purchased.title", value: "Thank You", comment: "Ice cream title label when purchased.")
        let hasPurchasedMessage = NSLocalizedString("icecream.purchased.message", value: "Thank you so much for supporting me and my app!", comment: "Ice cream message label when purchased.")
        let notHasPurchasedTitle = NSLocalizedString("icecream.notpurchased.title", value: "Send Me Ice Cream", comment: "Ice cream title label when not purchased")
        let notHasPurchasedMessage = NSLocalizedString("icecream.notpurchased.message", value: "If you like Frame Grabber or want to support future development, you can send me this delicious piece of raspberry ice cream in form of a tip.\n\nWhat's in it for you? The satisfaction of knowing you made my day. :)\n\nThank you for checking out my app!\n\nArthur", comment: "Ice cream message label when not purchased")

        switch state() {

        case .fetchingProducts, .purchasing, .restoring:
            purchaseButton.isShowingActivity = true
            navigationItem.rightBarButtonItem?.isEnabled = false
            titleLabel.text = notHasPurchasedTitle
            messageLabel.text = notHasPurchasedMessage

        case .productsNotFetched, .readyToPurchase:
            purchaseButton.isShowingActivity = false
            navigationItem.rightBarButtonItem?.isEnabled = true

            if let product = fetchedProduct {
                let price = formattedPrice(for: product)
                let format = NSLocalizedString("icecream.purchasebutton.price", value: "Send Ice Cream – %@", comment: "Ice cream purchase button label with price")
                purchaseButton.dormantTitle = String.localizedStringWithFormat(format, price)
            } else {
                purchaseButton.dormantTitle = NSLocalizedString("icecream.purchasebutton.withoutprice", value: "Send Ice Cream", comment: "Ice cream purchase button label without price")
            }

            titleLabel.text = notHasPurchasedTitle
            messageLabel.text = notHasPurchasedMessage

        case .purchased:
            purchaseButton.isHidden = true
            navigationItem.rightBarButtonItem = nil
            titleLabel.text = hasPurchasedTitle
            messageLabel.text = hasPurchasedMessage
        }
    }

    private func styleNavigationBar() {
        let bar = navigationController?.navigationBar
        bar?.tintColor = .white
        bar?.shadowImage = UIImage()
        bar?.setBackgroundImage(UIImage(), for: .default)
        bar?.backgroundColor = nil
    }

    private func configureStoreManagers() {
        productsManager.requestDidFail = { [weak self] _, _ in
            self?.updateViews()
        }

        productsManager.requestDidSucceed = { [weak self] _, _ in
            self?.updateViews()
        }

        paymentsManager.restoreDidFail = { [weak self] error in
            self?.handleRestoreDidFail(with: error)
        }

        paymentsManager.restoreDidComplete = { [weak self] in
            self?.handleRestoreDidComplete()
        }

        paymentsManager.transactionDidUpdate = { [weak self] transaction in
            self?.handleTransactionDidUpdate(transaction)
        }
    }

    // MARK: Handling Transactions

    private func handleTransactionDidUpdate(_ transaction: SKPaymentTransaction) {
        dprint(transaction.payment.productIdentifier, transaction.transactionState)

        let isCancelled = transaction.error?.isStoreKitCancelledError == true

        if transaction.transactionState == .failed,
            !isCancelled {

            presentAlert(.purchaseFailed(error: transaction.error))
        }

        updateViews()
    }

    private func handleRestoreDidFail(with error: Error) {
        if !error.isStoreKitCancelledError {
            presentAlert(.restoreFailed(error: error))
        }

        updateViews()
    }

    private func handleRestoreDidComplete() {
        if paymentsManager.restored.isEmpty {
            presentAlert(.nothingToRestore())
        }

        updateViews()
    }

    private func formattedPrice(for product: SKProduct) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceLocale
        let fallback = "\(product.price)"
        return formatter.string(from: product.price as NSNumber) ?? fallback
    }

    // MARK: Determining Current State

    private enum State {
        case fetchingProducts
        case productsNotFetched  // Not yet fetched or failed to fetch.
        case readyToPurchase
        case purchasing
        case restoring
        case purchased
    }

    private func state() -> State {
        if hasPurchased {
            return .purchased
        }

        if productsManager.isFetchingProducts {
            return .fetchingProducts
        }

        if fetchedProduct == nil {
            return .productsNotFetched
        }

        if paymentsManager.isRestoring {
            return .restoring
        }

        if paymentsManager.hasPendingUnfinishedTransactions(withId: inAppPurchaseId) {
            return .purchasing
        }

        return .readyToPurchase
    }
}
