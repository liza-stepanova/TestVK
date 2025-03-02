import UIKit

final class ReviewsViewController: UIViewController {

    private lazy var reviewsView = makeReviewsView()
    
    private let viewModel: ReviewsViewModel

    init(viewModel: ReviewsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = reviewsView
        title = "Отзывы"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        reviewsView.startLoading()
        setupViewModel()
        setupRefreshControl()
        viewModel.getReviews()
    }

}

// MARK: - Private

private extension ReviewsViewController {

    func makeReviewsView() -> ReviewsView {
        let reviewsView = ReviewsView()
        reviewsView.tableView.delegate = viewModel
        reviewsView.tableView.dataSource = viewModel
        return reviewsView
    }
    
    func setupViewModel() {
        viewModel.onStateChange = { [weak self] state in
            guard let self else { return }
            self.reviewsView.stopLoading()
            self.reviewsView.endRefreshing()
            if state.hasError {
                self.reviewsView.showErrorLabel("Что-то пошло не так")
            } else {
                self.reviewsView.tableView.reloadData()
            }
        }
        viewModel.onPhotoTap = { [weak self] index, images in
            let galleryVC = PhotoPageViewController(images: images, startIndex: index)
            self?.navigationController?.pushViewController(galleryVC, animated: true)
        }
    }
    
    func setupRefreshControl() {
        reviewsView.refreshControl.addTarget(self, action: #selector(refreshReviews), for: .valueChanged)
    }
    
    @objc func refreshReviews() {
        viewModel.refreshReviews()
    }
    
}
