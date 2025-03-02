import UIKit

final class PhotoPageViewController: UIPageViewController {
    
    private var images: [UIImage] = []
    private let currentIndex: Int
    
    init(images: [UIImage], startIndex: Int = 0) {
        self.images = images
        self.currentIndex = startIndex
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = self
        let initialVC = createPhotoContentViewController(at: currentIndex)
        setViewControllers([initialVC], direction: .forward, animated: false)
    }
}

// MARK: - Private

private extension PhotoPageViewController {
    
    func createPhotoContentViewController(at index: Int) -> PhotoContentViewController {
        let viewController = PhotoContentViewController(image: images[index])
        return viewController
    }
    
}

// MARK: - UIPageViewControllerDataSource

extension PhotoPageViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard
          let photoContent = viewController as? PhotoContentViewController,
          let currentIndex = images.firstIndex(of: photoContent.image),
          currentIndex > 0
        else { return nil }
        return createPhotoContentViewController(at: currentIndex - 1)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard
          let photoContent = viewController as? PhotoContentViewController,
          let currentIndex = images.firstIndex(of: photoContent.image),
          currentIndex < images.count - 1
        else { return nil }
        return createPhotoContentViewController(at: currentIndex + 1)
    }
    
}
