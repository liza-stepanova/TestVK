import UIKit

final class ReviewsView: UIView {

    private let activityIndicator = LoadingIndicator(frame: CGRect(x: 0, y: 0, width: 140, height: 20))
    let refreshControl = UIRefreshControl()
    let tableView = UITableView()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        tableView.frame = bounds.inset(by: safeAreaInsets)
        activityIndicator.center = center
    }
    
    func startLoading() {
        activityIndicator.startAnimating()
        tableView.isHidden = true
    }
    
    func stopLoading() {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        tableView.isHidden = false
    }
    
    func endRefreshing() {
        refreshControl.endRefreshing()
    }
    
    func showErrorLabel(_ message: String) {
        let label = createErrorLabel(message: message)
        addSubview(label)
        setupErrorLabelConstraints(label)
        tableView.isHidden = true
    }
    
}

// MARK: - Private

private extension ReviewsView {

    func setupView() {
        backgroundColor = .systemBackground
        setupTableView()
        setupActivityIndicator()
    }

    func setupTableView() {
        addSubview(tableView)
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.register(ReviewCell.self, forCellReuseIdentifier: ReviewCellConfig.reuseId)
        tableView.register(ReviewCountCell.self, forCellReuseIdentifier: ReviewCountCellConfig.reuseId)
        tableView.refreshControl = refreshControl
    }
    
    func setupActivityIndicator() {
        addSubview(activityIndicator)
    }
    
    func createErrorLabel(message: String) -> UILabel {
        let label = UILabel()
        label.text = message
        label.textColor = .systemGray
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    func setupErrorLabelConstraints(_ label: UILabel) {
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
    
}
