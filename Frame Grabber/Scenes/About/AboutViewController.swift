import InAppPurchase
import MessageUI
import SafariServices
import Utility
import UIKit

class AboutViewController: UITableViewController, MFMailComposeViewControllerDelegate {

    enum Section: Int {
        case about
        case featured
        case version
    }

    let app = UIApplication.shared
    let bundle = Bundle.main
    let device = UIDevice.current

    @IBOutlet private var rateButton: UIButton!
    @IBOutlet private var purchaseButton: UIButton!
    @IBOutlet private var featuredTitleLabel: UILabel!
    @IBOutlet private var versionLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateExpandedPreferredContentSize()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let aboutSection = Section.about.rawValue
        let contactPath = IndexPath(row: 0, section: aboutSection)
        let privacyPolicyPath = IndexPath(row: 1, section: aboutSection)
        let showSourceCodePath = IndexPath(row: 2, section: aboutSection)

        switch indexPath {
        case contactPath: contact()
        case privacyPolicyPath: showPrivacyPolicy()
        case showSourceCodePath: showSourceCode()
        default: break
        }
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        tableView.cellForRow(at: indexPath)?.accessoryType != .some(.none)
    }

    private func configureViews() {
        rateButton.configureAsActionButton()
        rateButton.backgroundColor = .accent.withAlphaComponent(0.1)
        rateButton.setTitleColor(.accent, for: .normal)
        
        purchaseButton.configureAsActionButton()
        purchaseButton.configureWithDefaultShadow()
        purchaseButton.configureTrailingAlignedImage()
        
        featuredTitleLabel.font = .preferredFont(forTextStyle: .body, weight: .semibold, size: 22)
        versionLabel.font = .preferredFont(forTextStyle: .footnote, weight: .semibold)
        versionLabel.text = String.localizedStringWithFormat(Localized.aboutVersionFormat, bundle.shortFormattedVersion)

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(done))
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: Localized.aboutShareAppButtonTitle,
            image: UIImage(systemName: "square.and.arrow.up"),
            primaryAction: UIAction { [weak self] _ in self?.shareApp() },
            menu: nil
        )
    }
}

// MARK: - Actions

extension AboutViewController {

    @IBAction private func done() {
        dismiss(animated: true)
    }
    
    private func shareApp() {
        guard let url = About.storeURL?.absoluteString else { return }
        let shareText = "\(Localized.aboutShareAppText)\n\(url)"
        let shareController = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        present(shareController, animated: true)
    }

    @IBAction private func rate() {
        guard let url = About.storeReviewURL,
            app.canOpenURL(url) else { return }

        app.open(url)
    }
    
    private func contact() {
        guard MFMailComposeViewController.canSendMail() else {
            presentAlert(.mailNotAvailable(contactAddress: About.contactAddress))
            return
        }

        let contactMessage = """
        \n\n
        \(bundle.longFormattedVersion)
        \(device.systemName) \(device.systemVersion)
        \(device.type ?? device.model)
        """

        let mailController = MFMailComposeViewController()
        mailController.view.tintColor = .accent
        mailController.mailComposeDelegate = self
        mailController.setToRecipients([About.contactAddress])
        mailController.setSubject(Localized.aboutContactSubject)
        mailController.setMessageBody(contactMessage, isHTML: false)

        present(mailController, animated: true)
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        dismiss(animated: true)
    }

    private func showSourceCode() {
        guard let url = About.sourceCodeURL else { return }
        showURL(url)
    }

    private func showPrivacyPolicy() {
        guard let url = About.PrivacyPolicy.preferred else { return }
        showURL(url)
    }

    private func showURL(_ url: URL) {
        let safariController = SFSafariViewController(url: url)
        safariController.modalPresentationStyle = .automatic
        safariController.preferredControlTintColor = .accent
        present(safariController, animated: true)
    }
}
