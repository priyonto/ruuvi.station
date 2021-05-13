import UIKit

class SignInViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var textFieldHeaderLabel: UILabel!
    @IBOutlet weak var textTextField: UITextField!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!

    var output: SignInViewOutput!
    var viewModel: SignInViewModel! {
        didSet {
            bindViewModel()
        }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLocalization()
        addTapGesture()
        output.viewDidLoad()
    }

    @IBAction func didTapCloseButton(_ sender: Any) {
        output.viewDidClose()
    }

    @IBAction func didTapSubmit(_ sender: UIButton) {
        updateTextFieldText()
        output.viewDidTapSubmitButton()
    }

    @IBAction func viewDidTapEnterCodeManually(_ sender: UIButton) {
        output.viewDidTapEnterCodeManually()
    }
}

// MARK: - SignInViewInput
extension SignInViewController: SignInViewInput {
    func localize() {
        title = "SignIn.Title.text".localized()
        
    }
}

// MARK: - UITextFieldDelegate
extension SignInViewController: UITextFieldDelegate {

    func textFieldDidEndEditing(_ textField: UITextField) {
        updateTextFieldText()
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        viewModel.errorLabelText.value = nil
    }
}

// MARK: - Private
extension SignInViewController {

    func updateTextFieldText() {
        let email = textTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        textTextField.text = email
        viewModel.inputText.value = email
    }

    private func addTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapView))
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func didTapView(_ sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }

    private func bindViewModel() {
        guard isViewLoaded else {
            return
        }
        titleLabel.bind(viewModel.titleLabelText) { (label, value) in
            label.text = value
        }
        subTitleLabel.bind(viewModel.subTitleLabelText) { (label, value) in
            label.text = value
        }
        errorLabel.bind(viewModel.errorLabelText) { [weak self] (label, value) in
            if let errorText = value,
               self?.textTextField.text?.isEmpty == false {
                label.text = errorText
            } else {
                label.text = nil
            }
        }
        textFieldHeaderLabel.bind(viewModel.placeholder) { (label, placeholder) in
            label.text = placeholder
        }
        textTextField.bind(viewModel.textContentType) { (textField, textContentType) in
            if let textContentType = textContentType {
                textField.textContentType = textContentType
            }
        }
        textTextField.bind(viewModel.inputText) { (textField, text) in
            if textField.text != text {
                textField.text = text
            }
        }
        navigationItem.leftBarButtonItem?.bind(viewModel.canPopViewController,
                                               block: { (buttonItem, canPopViewController) in
            buttonItem.image = canPopViewController ?? false ? #imageLiteral(resourceName: "icon_back_arrow") : #imageLiteral(resourceName: "dismiss-modal-icon")
        })
    }
}
