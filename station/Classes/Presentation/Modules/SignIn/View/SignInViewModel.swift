import UIKit

struct SignInViewModel {
    var titleLabelText: Observable<String?> = .init()
    var subTitleLabelText: Observable<String?> = .init()
    var errorLabelText: Observable<String?> = .init()
    var enterCodeManuallyButtonIsHidden: Observable<Bool?> = .init(false)
    var inputText: Observable<String?> = .init()
    var placeholder: Observable<String?> = .init()
    var textContentType: Observable<UITextContentType?> = .init(.emailAddress)
    var canPopViewController: Observable<Bool?> = .init(false)
}
