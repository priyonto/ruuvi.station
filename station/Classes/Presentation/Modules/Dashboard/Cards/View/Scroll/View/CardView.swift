import UIKit
import Localize_Swift

protocol CardViewDelegate: class {
    func card(view: CardView, didTriggerSettings sender: Any)
    func card(view: CardView, didTriggerCharts sender: Any)
}

class CardView: UIView {

    weak var delegate: CardViewDelegate?

    @IBOutlet weak var chartsButtonWidth: NSLayoutConstraint!
    @IBOutlet weak var alertImageView: UIImageView!
    @IBOutlet weak var alertView: UIView!
    @IBOutlet weak var humidityWarningImageView: UIImageView!
    @IBOutlet weak var chartsButtonContainerView: UIView!
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var temperatureUnitLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var pressureLabel: UILabel!
    @IBOutlet weak var rssiCityLabel: UILabel!
    @IBOutlet weak var updatedLabel: UILabel!
    @IBOutlet weak var rssiCityImageView: UIImageView!

    var updatedAt: Date?
    var isConnected: Bool?
    var networkTagMacId: MACIdentifier? {
        didSet {
            guard let macId = networkTagMacId else {
                notificationToken?.invalidate()
                startTimer()
                return
            }
            startObservingNetworkSyncNotification(for: macId.any)
        }
    }
    var syncStatus: NetworkSyncStatus = .none {
        didSet {
            updateSyncLabel(with: syncStatus)
        }
    }

    private var notificationToken: NSObjectProtocol?
    private var isSyncing: Bool = false

    private var timer: Timer?

    deinit {
        notificationToken?.invalidate()
        timer?.invalidate()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        updateSyncLabel(with: syncStatus)
        UIView.animate(withDuration: 0.5, delay: 0, options: [.repeat, .autoreverse], animations: { [weak self] in
            self?.humidityWarningImageView.alpha = 0.0
        })
    }

    @IBAction func chartsButtonTouchUpInside(_ sender: Any) {
        delegate?.card(view: self, didTriggerCharts: sender)
    }

    @IBAction func settingsButtonTouchUpInside(_ sender: Any) {
        delegate?.card(view: self, didTriggerSettings: sender)
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] (_) in
            guard self?.isSyncing == false else {
                return
            }
            if let isConnected = self?.isConnected,
               isConnected,
               let date = self?.updatedAt?.ruuviAgo() {
                self?.updatedLabel.text = "Cards.Connected.title".localized() + " " + "|" + " " + date
            } else {
                self?.updatedLabel.text = self?.updatedAt?.ruuviAgo() ?? "N/A".localized()
            }
        })
    }

    private func startObservingNetworkSyncNotification(for macId: AnyMACIdentifier) {
        notificationToken = NotificationCenter
            .default
            .addObserver(forName: .NetworkSyncDidChangeStatus,
                         object: nil,
                         queue: nil,
                         using: { [weak self] notification in
            guard let mac = notification.userInfo?[NetworkSyncStatusKey.mac] as? AnyMACIdentifier,
                  let status = notification.userInfo?[NetworkSyncStatusKey.status] as? NetworkSyncStatus,
                  mac == macId else {
                return
            }
            self?.updateSyncLabel(with: status)
        })
    }

    private func updateSyncLabel(with status: NetworkSyncStatus) {
        timer?.invalidate()
        switch status {
        case .none:
            isSyncing = false
            startTimer()
        case .syncing:
            isSyncing = true
            updatedLabel.text = "TagCharts.Status.Serving".localized()
        case .complete:
            updatedLabel.text = "Synchronized".localized()
        case .onError:
            updatedLabel.text = "ErrorPresenterAlert.Error".localized()
        }
    }
}
