import UIKit

class CustomizeInsightsCell: UITableViewCell, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var laterButton: UIButton!
    @IBOutlet weak var tryButton: UIButton!
    @IBOutlet weak var bottomSeparatorLine: UIView!

    private weak var insightsDelegate: SiteStatsInsightsDelegate?
    private typealias Style = WPStyleGuide.Stats

    // MARK: - Configure

    func configure(insightsDelegate: SiteStatsInsightsDelegate?) {
        self.insightsDelegate = insightsDelegate
        applyStyles()
    }

}

// MARK: - Private Extension

private extension CustomizeInsightsCell {

    // MARK: - Styles

    func applyStyles() {
        titleLabel.text = NSLocalizedString("Customize your insights", comment: "")
        contentLabel.text = NSLocalizedString("Create your own customized dashboard and choose what reports to see. Focus on the data you care most about.", comment: "")
        tryButton.setTitle(NSLocalizedString("Try it now", comment: ""), for: .normal)
        laterButton.setTitle(NSLocalizedString("Later", comment: ""), for: .normal)

        Style.configureCell(self)
        Style.configureLabelAsCustomizeTitle(titleLabel)
        Style.configureLabelAsSummary(contentLabel)
        Style.configureAsCustomizeLaterButton(laterButton)
        Style.configureAsCustomizeTryButton(tryButton)
        Style.configureViewAsSeparator(bottomSeparatorLine)
    }

    // MARK: - Button Handling

    @IBAction func didTapLaterButton(_ sender: UIButton) {
        insightsDelegate?.customizeLaterButtonTapped?()
    }

    @IBAction func didTapTryButton(_ sender: UIButton) {
        insightsDelegate?.customizeTryButtonTapped?()
    }

}
