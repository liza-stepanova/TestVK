import UIKit

class PhotoContentView: UIView {
    
    private let imageView = UIImageView()
    
    var image: UIImage? {
        didSet {
            imageView.image = image
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        setupImageView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
    }
    
}

// MARK: - Private

private extension PhotoContentView {
    
    func setupImageView() {
        addSubview(imageView)
        imageView.contentMode = .scaleAspectFit
    }
    
}
