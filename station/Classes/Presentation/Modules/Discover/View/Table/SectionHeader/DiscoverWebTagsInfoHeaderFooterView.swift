import UIKit

protocol DiscoverWebTagsInfoHeaderFooterViewDelegate: class {
    func discoverWebTagsInfo(headerView: DiscoverWebTagsInfoHeaderFooterView, didTapOnInfo button: UIButton)
}

class DiscoverWebTagsInfoHeaderFooterView: UITableViewHeaderFooterView, Localizable {
    weak var delegate: DiscoverWebTagsInfoHeaderFooterViewDelegate?
    
    @IBOutlet weak var webTagsLabel: UILabel!
    @IBOutlet weak var noValuesView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupLocalization()
    }
    
    func localize() {
        webTagsLabel.text = "DiscoverTable.SectionTitle.WebTags".localized().uppercased()
    }
    
    @IBAction func noValuesButtonTouchUpInside(_ sender: UIButton) {
        delegate?.discoverWebTagsInfo(headerView: self, didTapOnInfo: sender)
    }
}

