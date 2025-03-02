import UIKit

/// Конфигурация ячейки. Содержит данные для отображения в ячейке.
struct ReviewCellConfig {

    /// Идентификатор для переиспользования ячейки.
    static let reuseId = String(describing: ReviewCellConfig.self)
    private let ratingRender = RatingRenderer()
    /// Идентификатор конфигурации. Можно использовать для поиска конфигурации в массиве.
    let id = UUID()
    /// Аватар пользователя.
    var avatarImage: UIImage?
    /// Имя и фамилия пользователя.
    let firstNameText: NSAttributedString
    let lastNameText: NSAttributedString
    /// Рейтинг отзыва.
    let rating: Int
    /// Фотографии отзыва.
    var photos: [UIImage]?
    /// Текст отзыва.
    let reviewText: NSAttributedString
    /// Максимальное отображаемое количество строк текста. По умолчанию 3.
    var maxLines = 3
    /// Время создания отзыва.
    let created: NSAttributedString
    /// Замыкание, вызываемое при нажатии на кнопку "Показать полностью...".
    let onTapShowMore: (UUID) -> Void
    /// Замыкание, вызываемое при нажатии на фотографию
    var onPhotoTap: (Int, [UIImage]) -> Void

    /// Объект, хранящий посчитанные фреймы для ячейки отзыва.
    fileprivate let layout = ReviewCellLayout()

}

// MARK: - TableCellConfig

extension ReviewCellConfig: TableCellConfig {

    /// Метод обновления ячейки.
    /// Вызывается из `cellForRowAt:` у `dataSource` таблицы.
    func update(cell: UITableViewCell) {
        guard let cell = cell as? ReviewCell else { return }
        cell.avatarImage.image = avatarImage
        updateReviewImages(in: cell)
        cell.usernameLabel.attributedText = fullName
        cell.ratingImage.image = ratingRender.ratingImage(rating)
        cell.reviewTextLabel.attributedText = reviewText
        cell.reviewTextLabel.numberOfLines = maxLines
        cell.createdLabel.attributedText = created
        cell.config = self
        
        cell.photoTapHandler = { index, images in
            self.onPhotoTap(index, images)
        }
    }

    /// Метод, возвращаюший высоту ячейки с данным ограничением по размеру.
    /// Вызывается из `heightForRowAt:` делегата таблицы.
    func height(with size: CGSize) -> CGFloat {
        layout.height(config: self, maxWidth: size.width)
    }

}

// MARK: - Private

private extension ReviewCellConfig {

    /// Текст кнопки "Показать полностью...".
    static let showMoreText = "Показать полностью..."
        .attributed(font: .showMore, color: .showMore)
    
    /// Полное имя пользователя.
    var fullName: NSAttributedString {
        let separator = NSAttributedString(string: " ")
        let fullName = NSMutableAttributedString()
        fullName.append(firstNameText)
        fullName.append(separator)
        fullName.append(lastNameText)
        
        return fullName
    }
    
    func updateReviewImages(in cell: ReviewCell) {
        for imageView in cell.reviewImages {
            imageView.image = nil
        }
        
        if let photos = photos, !photos.isEmpty {
            for (index, image) in photos.enumerated() {
                cell.reviewImages[index].image = image
            }
        }
    }
    
}

// MARK: - Cell

final class ReviewCell: UITableViewCell {

    var photoTapHandler: ((Int, [UIImage]) -> Void)?
    fileprivate var config: Config?
    
    fileprivate let avatarImage = UIImageView()
    fileprivate let usernameLabel = UILabel()
    fileprivate var ratingImage = UIImageView()
    fileprivate var reviewImages = [UIImageView(), UIImageView(), UIImageView(), UIImageView(), UIImageView()]
    fileprivate let reviewTextLabel = UILabel()
    fileprivate let createdLabel = UILabel()
    fileprivate let showMoreButton = UIButton()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let layout = config?.layout else { return }
        avatarImage.frame = layout.avatarImageFrame
        avatarImage.layer.cornerRadius = ReviewCellLayout.avatarCornerRadius
        avatarImage.clipsToBounds = true
        
        usernameLabel.frame = layout.usernameLabelFrame
        ratingImage.frame = layout.ratingImageFrame
        if !reviewImages.isEmpty {
            for (index, item) in layout.reviewImagesFrames.enumerated() {
                reviewImages[index].frame = item
            }
        }
        reviewTextLabel.frame = layout.reviewTextLabelFrame
        createdLabel.frame = layout.createdLabelFrame
        showMoreButton.frame = layout.showMoreButtonFrame
    }
    
}

// MARK: - Private

private extension ReviewCell {

    func setupCell() {
        setupAvatarImage()
        setupUsernameLabel()
        setupRatingImage()
        setupReviewImages()
        setupReviewTextLabel()
        setupCreatedLabel()
        setupShowMoreButton()
    }
    
    func setupUsernameLabel() {
        contentView.addSubview(usernameLabel)
        usernameLabel.lineBreakMode = .byWordWrapping
    }
    
    func setupRatingImage() {
        contentView.addSubview(ratingImage)
    }
    
    func setupReviewImages() {
        for (index, imageView) in reviewImages.enumerated() {
            imageView.isUserInteractionEnabled = true
            imageView.contentMode = .scaleAspectFill
            imageView.layer.cornerRadius = ReviewCellLayout.photoCornerRadius
            imageView.clipsToBounds = true
            imageView.tag = index
            contentView.addSubview(imageView)
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(photoTapped(_:)))
            imageView.addGestureRecognizer(tapGesture)
        }
    }
    
    func setupAvatarImage() {
        avatarImage.tag = -1
        avatarImage.isUserInteractionEnabled = true
        contentView.addSubview(avatarImage)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(photoTapped(_:)))
        avatarImage.addGestureRecognizer(tapGesture)
    }

    func setupReviewTextLabel() {
        contentView.addSubview(reviewTextLabel)
        reviewTextLabel.lineBreakMode = .byWordWrapping
    }

    func setupCreatedLabel() {
        contentView.addSubview(createdLabel)
    }

    func setupShowMoreButton() {
        contentView.addSubview(showMoreButton)
        showMoreButton.contentVerticalAlignment = .fill
        showMoreButton.setAttributedTitle(Config.showMoreText, for: .normal)
        showMoreButton.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            if let config = self.config {
                config.onTapShowMore(config.id)
            }
        }, for: .touchUpInside)
    }
    
    @objc private func photoTapped(_ sender: UITapGestureRecognizer) {
        guard let tappedView = sender.view as? UIImageView else { return }
        
        var index = tappedView.tag
        var images: [UIImage] = []
        if index == -1 {
            images = [avatarImage.image].compactMap { $0 }
            index = 0
        } else {
            images = reviewImages.compactMap { $0.image }
        }
        photoTapHandler?(index, images)
    }
    
}

// MARK: - Layout

/// Класс, в котором происходит расчёт фреймов для сабвью ячейки отзыва.
/// После расчётов возвращается актуальная высота ячейки.
private final class ReviewCellLayout {

    // MARK: - Размеры

    fileprivate static let avatarSize = CGSize(width: 36.0, height: 36.0)
    fileprivate static let avatarCornerRadius = 18.0
    fileprivate static let photoCornerRadius = 8.0

    private static let photoSize = CGSize(width: 55.0, height: 66.0)
    private static let showMoreButtonSize = Config.showMoreText.size()
    
    private static let ratingImageSize = CGSize(width: 84, height: 16)

    // MARK: - Фреймы

    private(set) var avatarImageFrame = CGRect.zero
    private(set) var usernameLabelFrame = CGRect.zero
    private(set) var ratingImageFrame = CGRect.zero
    private(set) var reviewImagesFrames: [CGRect] = Array(repeating: CGRect.zero, count: 5)
    private(set) var reviewTextLabelFrame = CGRect.zero
    private(set) var showMoreButtonFrame = CGRect.zero
    private(set) var createdLabelFrame = CGRect.zero

    // MARK: - Отступы

    /// Отступы от краёв ячейки до её содержимого.
    private let insets = UIEdgeInsets(top: 9.0, left: 12.0, bottom: 9.0, right: 12.0)

    /// Горизонтальный отступ от аватара до имени пользователя.
    private let avatarToUsernameSpacing = 10.0
    /// Вертикальный отступ от имени пользователя до вью рейтинга.
    private let usernameToRatingSpacing = 6.0
    /// Вертикальный отступ от вью рейтинга до текста (если нет фото).
    private let ratingToTextSpacing = 6.0
    /// Вертикальный отступ от вью рейтинга до фото.
    private let ratingToPhotosSpacing = 10.0
    /// Горизонтальные отступы между фото.
    private let photosSpacing = 8.0
    /// Вертикальный отступ от фото (если они есть) до текста отзыва.
    private let photosToTextSpacing = 10.0
    /// Вертикальный отступ от текста отзыва до времени создания отзыва или кнопки "Показать полностью..." (если она есть).
    private let reviewTextToCreatedSpacing = 6.0
    /// Вертикальный отступ от кнопки "Показать полностью..." до времени создания отзыва.
    private let showMoreToCreatedSpacing = 6.0

    // MARK: - Расчёт фреймов и высоты ячейки

    /// Возвращает высоту ячейку с данной конфигурацией `config` и ограничением по ширине `maxWidth`.
    func height(config: Config, maxWidth: CGFloat) -> CGFloat {
        let leftInsetWithAvatar = insets.left + avatarToUsernameSpacing + ReviewCellLayout.avatarSize.width
        let width = maxWidth - leftInsetWithAvatar - insets.right
        
        var maxY = insets.top
        var showShowMoreButton = false
        
        avatarImageFrame = CGRect(
            origin: CGPoint(x: insets.left, y: maxY),
            size: ReviewCellLayout.avatarSize
        )
        
        usernameLabelFrame = CGRect(
            origin: CGPoint(x: leftInsetWithAvatar, y: maxY),
            size: config.fullName.boundingRect(width: width).size
        )
        maxY = usernameLabelFrame.maxY + usernameToRatingSpacing

        ratingImageFrame = CGRect(
            origin: CGPoint(x: leftInsetWithAvatar, y: maxY),
            size: ReviewCellLayout.ratingImageSize
        )
        maxY = ratingImageFrame.maxY + ratingToTextSpacing
        
        if let photos = config.photos, !photos.isEmpty {
            maxY = ratingImageFrame.maxY + ratingToPhotosSpacing
            
            reviewImagesFrames = self.calculateImagesFrames(
                config: config,
                leftInset: leftInsetWithAvatar,
                photosSpacing: photosSpacing,
                maxY: maxY
            )
            maxY = reviewImagesFrames[0].maxY + photosToTextSpacing
        }
        
        if !config.reviewText.isEmpty() {
            // Высота текста с текущим ограничением по количеству строк.
            let currentTextHeight = (config.reviewText.font()?.lineHeight ?? .zero) * CGFloat(config.maxLines)
            // Максимально возможная высота текста, если бы ограничения не было.
            let actualTextHeight = config.reviewText.boundingRect(width: width).size.height
            // Показываем кнопку "Показать полностью...", если максимально возможная высота текста больше текущей.
            showShowMoreButton = config.maxLines != .zero && actualTextHeight > currentTextHeight

            reviewTextLabelFrame = CGRect(
                origin: CGPoint(x: leftInsetWithAvatar, y: maxY),
                size: config.reviewText.boundingRect(width: width, height: currentTextHeight).size
            )
            maxY = reviewTextLabelFrame.maxY + reviewTextToCreatedSpacing
        }

        if showShowMoreButton {
            showMoreButtonFrame = CGRect(
                origin: CGPoint(x: leftInsetWithAvatar, y: maxY),
                size: Self.showMoreButtonSize
            )
            maxY = showMoreButtonFrame.maxY + showMoreToCreatedSpacing
        } else {
            showMoreButtonFrame = .zero
        }

        createdLabelFrame = CGRect(
            origin: CGPoint(x: leftInsetWithAvatar, y: maxY),
            size: config.created.boundingRect(width: width).size
        )

        return createdLabelFrame.maxY + insets.bottom
    }
    
    /// Возвращает фреймы для каждого элемента reviewImage
    private func calculateImagesFrames(config: Config, leftInset: CGFloat, photosSpacing: CGFloat, maxY: CGFloat) -> [CGRect] {
        guard let photos = config.photos else { return [] }
        var frames = [CGRect]()
        var x = leftInset
        
        for (index, _) in photos.enumerated() {
            if index > 0 {
                x += ReviewCellLayout.photoSize.width + photosSpacing
            }
            let frame = CGRect(
                origin: CGPoint(x: x, y: maxY),
                size: ReviewCellLayout.photoSize
            )
            frames.append(frame)
        }
        return frames
    }
    
}

// MARK: - Typealias

fileprivate typealias Config = ReviewCellConfig
fileprivate typealias Layout = ReviewCellLayout
