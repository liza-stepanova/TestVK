import UIKit

/// Класс, описывающий бизнес-логику экрана отзывов.
final class ReviewsViewModel: NSObject {
    
    /// Замыкание, вызываемое при изменении `state`.
    var onStateChange: ((State) -> Void)?
    /// Замыкание, вызываемое при нажатии на фото
    var onPhotoTap: ((Int, [UIImage]) -> Void)?
    
    private var state: State
    private let reviewsProvider: ReviewsProvider
    private let ratingRenderer: RatingRenderer
    private let decoder: JSONDecoder
    private let imageCache = NSCache<NSString, UIImage>()
    
    init(
        state: State = State(),
        reviewsProvider: ReviewsProvider = ReviewsProvider(),
        ratingRenderer: RatingRenderer = RatingRenderer(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.state = state
        self.reviewsProvider = reviewsProvider
        self.ratingRenderer = ratingRenderer
        self.decoder = decoder
        imageCache.countLimit = 100
    }
    
}

// MARK: - Internal

extension ReviewsViewModel {
    
    typealias State = ReviewsViewModelState
    
    /// Метод получения отзывов.
    func getReviews() {
        guard state.shouldLoad else { return }
        state.shouldLoad = false
        DispatchQueue.global(qos: .background).async {
            self.reviewsProvider.getReviews(offset: self.state.offset) { [weak self] result in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.gotReviews(result)
                }
            }
        }
    }
    
    func refreshReviews() {
        state.items.removeAll()
        state.offset = 0
        state.shouldLoad = true
        state.hasError = false
        onStateChange?(state)
        getReviews()
    }
    
}

// MARK: - Private

private extension ReviewsViewModel {
    
    /// Метод обработки получения отзывов.
    func gotReviews(_ result: ReviewsProvider.GetReviewsResult) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            do {
                let data = try result.get()
                let reviews = try decoder.decode(Reviews.self, from: data)
                
                var updatedItems = self.state.items
                updatedItems += reviews.items.map(makeReviewItem)
                updatedItems.removeAll { $0 is ReviewCountItem }
                updatedItems.append(makeReviewCountItem(reviews.count))
                
                let newOffset = self.state.offset + self.state.limit
                let shouldLoadMore = newOffset < reviews.count
                
                DispatchQueue.main.async {
                    self.state.items = updatedItems
                    self.state.shouldLoad = shouldLoadMore
                    self.state.offset = newOffset
                    self.onStateChange?(self.state)
                }
                
                reviews.items.enumerated().forEach { index, review in
                    self.loadPhotos(for: review, at: index)
                    self.loadAvatar(for: review, at: index)
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.state.shouldLoad = true
                    self.state.hasError = true
                    self.onStateChange?(self.state)
                }
            }
        }
    }
    
    /// Загружает фотографии отзыва.
    func loadPhotos(for review: Review, at index: Int) {
        guard
          let photoUrls = review.photoUrls,
          !photoUrls.isEmpty
        else { return }
        
        let group = DispatchGroup()
        var photos: [UIImage?] = Array(repeating: nil, count: photoUrls.count)
        
        for (index, url) in photoUrls.enumerated() {
            group.enter()
            let cacheKey = url as NSString
            if let cachedImage = imageCache.object(forKey: cacheKey) {
                photos[index] = cachedImage
                group.leave()
            } else {
                self.reviewsProvider.getPhoto(link: url) { [weak self] result in
                    guard let self else { return }
                    if case .success(let data) = result, let image = UIImage(data: data) {
                        self.imageCache.setObject(image, forKey: cacheKey)
                        photos[index] = image
                    } else {
                        photos[index] = UIImage(named: "placeholder")
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let self else { return }
            if let item = self.state.items[index] as? ReviewItem {
                var updatedItem = item
                updatedItem.photos = photos.compactMap { $0 }
                self.state.items[index] = updatedItem
                self.onStateChange?(self.state)
            }
        }
    }
    
    /// Загружает аватар пользователя.
    func loadAvatar(for review: Review, at index: Int) {
        guard let avatarUrl = review.avatarUrl else { return }
        let cacheKey = avatarUrl as NSString
        let group = DispatchGroup()
        var avatarImage = UIImage()
        
        group.enter()
        if let cachedImage = imageCache.object(forKey: cacheKey) {
            avatarImage = cachedImage
            group.leave()
        } else {
            self.reviewsProvider.getPhoto(link: avatarUrl) { [weak self] result in
                defer { group.leave() }
                guard let self else { return }
                if case .success(let data) = result, let image = UIImage(data: data) {
                    self.imageCache.setObject(image, forKey: cacheKey)
                    avatarImage = image
                } 
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let self else { return }
            if let item = self.state.items[index] as? ReviewItem {
                var updatedItem = item
                updatedItem.avatarImage = avatarImage
                self.state.items[index] = updatedItem
                self.onStateChange?(self.state)
            }
        }
    }
    
    /// Метод, вызываемый при нажатии на кнопку "Показать полностью...".
    /// Снимает ограничение на количество строк текста отзыва (раскрывает текст).
    func showMoreReview(with id: UUID) {
        guard
          let index = state.items.firstIndex(where: { ($0 as? ReviewItem)?.id == id }),
          var item = state.items[index] as? ReviewItem
        else { return }
        item.maxLines = .zero
        state.items[index] = item
        onStateChange?(state)
    }
    
}

// MARK: - Items

private extension ReviewsViewModel {
    
    typealias ReviewItem = ReviewCellConfig
    typealias ReviewCountItem = ReviewCountCellConfig
    
    func makeReviewItem(_ review: Review) -> ReviewItem {
        let avatarImage = UIImage(named: "avatar")
        let firstNameText = review.firstName.attributed(font: .username)
        let lastNameText = review.lastName.attributed(font: .username)
        let rating = review.rating
        let reviewText = review.text.attributed(font: .text)
        let created = review.created.attributed(font: .created, color: .created)
        let item = ReviewItem(
            avatarImage: avatarImage,
            firstNameText: firstNameText,
            lastNameText: lastNameText,
            rating: rating,
            reviewText: reviewText,
            created: created,
            onTapShowMore: { [weak self] id in
                self?.showMoreReview(with: id)
            },
            onPhotoTap: { [weak self] images, index in
                self?.onPhotoTap?(images, index)
            }
        )
        return item
    }
    
    func makeReviewCountItem(_ count: Int) -> ReviewCountItem {
        let countText = String(count)
        let reviewText = localizedReviewWord(for: count)
        let reviewCountText = countText + " " + reviewText
        let text = reviewCountText.attributed(font: .reviewCount, color: .reviewCount)
        
        return ReviewCountItem(reviewCountText: text)
    }
    
    func localizedReviewWord(for count: Int) -> String {
        let lastNumber = count % 10
        switch lastNumber {
        case 1:
            return "отзыв"
        case 2...4:
            return "отзыва"
        default:
            return "отзывов"
        }
    }
    
}

// MARK: - UITableViewDataSource

extension ReviewsViewModel: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        state.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let config = state.items[indexPath.row]
        
        if let reviewConfig = config as? ReviewItem {
            let cell = tableView.dequeueReusableCell(withIdentifier: config.reuseId, for: indexPath)
            reviewConfig.update(cell: cell)
            return cell
        } else if let reviewCountConfig = config as? ReviewCountItem {
            let cell = tableView.dequeueReusableCell(withIdentifier: config.reuseId, for: indexPath)
            reviewCountConfig.update(cell: cell)
            return cell
        }
        
        return UITableViewCell()
    }
    
}

// MARK: - UITableViewDelegate

extension ReviewsViewModel: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        state.items[indexPath.row].height(with: tableView.bounds.size)
    }
    
    /// Метод дозапрашивает отзывы, если до конца списка отзывов осталось два с половиной экрана по высоте.
    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        guard state.shouldLoad else { return }
        if shouldLoadNextPage(scrollView: scrollView, targetOffsetY: targetContentOffset.pointee.y) {
            getReviews()
        }
    }
    
    private func shouldLoadNextPage(
        scrollView: UIScrollView,
        targetOffsetY: CGFloat,
        screensToLoadNextPage: Double = 2.5
    ) -> Bool {
        let viewHeight = scrollView.bounds.height
        let contentHeight = scrollView.contentSize.height
        let triggerDistance = viewHeight * screensToLoadNextPage
        let remainingDistance = contentHeight - viewHeight - targetOffsetY
        return remainingDistance <= triggerDistance
    }
    
}
