import Gridicons

struct ActionSheetButton {
    let title: String
    let image: UIImage
    let target: Any?
    let selector: Selector
}

class ActionSheetViewController: UIViewController {

    enum Constants {
        static let gripHeight: CGFloat = 5
        static let cornerRadius: CGFloat = 8
        static let buttonSpacing: CGFloat = 8
        static let additionalSafeAreaInsetsRegular: UIEdgeInsets = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
        static let minimumWidth: CGFloat = 300

        enum Header {
            static let spacing: CGFloat = 16
            static let insets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18)
        }

        enum Button {
            static let height: CGFloat = 54
            static let contentInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 35)
            static let titleInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
            static let imageTintColor: UIColor = .neutral(.shade30)
            static let font: UIFont = .preferredFont(forTextStyle: .callout)
            static let textColor: UIColor = .text
        }

        enum Stack {
            static let insets: UIEdgeInsets = UIEdgeInsets(top: 5, left: 0, bottom: 0, right: 0)
        }
    }

    let buttons: [ActionSheetButton]
    let headerTitle: String

    init(headerTitle: String, buttons: [ActionSheetButton]) {
        self.headerTitle = headerTitle
        self.buttons = buttons
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var gripButton: UIButton = {
        let button = GripButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        return button
    }()

    @objc func buttonPressed() {
        dismiss(animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.clipsToBounds = true
        view.layer.cornerRadius = Constants.cornerRadius
        view.backgroundColor = .basicBackground

        let headerLabelView = UIView()
        let headerLabel = UILabel()
        headerLabelView.addSubview(headerLabel)
        headerLabelView.pinSubviewToAllEdges(headerLabel, insets: Constants.Header.insets)

        headerLabel.font = WPStyleGuide.fontForTextStyle(.headline)
        headerLabel.text = headerTitle
        headerLabel.translatesAutoresizingMaskIntoConstraints = false

        let buttonViews = buttons.map({ (sheetButton) -> UIButton in
            return button(title: sheetButton.title, image: sheetButton.image, target: sheetButton.target, selector: sheetButton.selector)
        })

        NSLayoutConstraint.activate([
            gripButton.heightAnchor.constraint(equalToConstant: Constants.gripHeight)
        ])

        let buttonConstraints = buttonViews.map { button in
            return button.heightAnchor.constraint(equalToConstant: Constants.Button.height)
        }

        NSLayoutConstraint.activate(buttonConstraints)

        let stackView = UIStackView(arrangedSubviews: [
            gripButton,
            headerLabelView
        ] + buttonViews)

        stackView.setCustomSpacing(Constants.Header.spacing, after: gripButton)
        stackView.setCustomSpacing(Constants.Header.spacing, after: headerLabelView)

        buttonViews.forEach { button in
            stackView.setCustomSpacing(Constants.buttonSpacing, after: button)
        }

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical

        refreshForTraits()

        view.addSubview(stackView)
        view.pinSubviewToSafeArea(stackView, insets: Constants.Stack.insets)
    }

    func button(title: String, image: UIImage, target: Any?, selector: Selector) -> UIButton {
        let button = UIButton(type: .custom)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = Constants.Button.font
        button.setTitleColor(Constants.Button.textColor, for: .normal)
        button.setImage(image, for: .normal)
        button.imageView?.tintColor = Constants.Button.imageTintColor
        button.setBackgroundImage(UIImage(color: .divider), for: .highlighted)
        button.titleEdgeInsets = Constants.Button.titleInsets
        button.naturalContentHorizontalAlignment = .leading
        button.contentEdgeInsets = Constants.Button.contentInsets
        button.addTarget(target, action: selector, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.flipInsetsForRightToLeftLayoutDirection()
        return button
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        refreshForTraits()
    }

    private func refreshForTraits() {
        if presentingViewController?.traitCollection.horizontalSizeClass == .regular {
            gripButton.isHidden = true
            additionalSafeAreaInsets = Constants.additionalSafeAreaInsetsRegular
        } else {
            gripButton.isHidden = false
            additionalSafeAreaInsets = .zero
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        return preferredContentSize = CGSize(width: Constants.minimumWidth, height: view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height)
    }
}
