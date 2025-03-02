import UIKit

final class LoadingIndicator: UIView {
    
    private let dotSize: CGFloat = 11
    private let spacing: CGFloat = 25
    private let dotCount = 3
    private var layers: [CALayer] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func startAnimating() {
        for (index, dot) in layers.enumerated() {
            let animation = createAnimation(delay: Double(index) * 0.1)
            dot.add(animation, forKey: "moveAnimation")
        }
    }

    func stopAnimating() {
        layers.forEach { $0.removeAllAnimations() }
    }

}

// MARK: - Private

private extension LoadingIndicator {
    
    private func setupLayers() {
        for i in 0..<dotCount {
            let dotLayer = CALayer()
            dotLayer.frame = CGRect(
                x: CGFloat(i) * (
                    dotSize + spacing
                ),
                y: bounds.midY - dotSize / 2,
                width: dotSize,
                height: dotSize
            )
            dotLayer.cornerRadius = dotSize / 2
            dotLayer.backgroundColor = UIColor.systemBlue.cgColor
            self.layer.addSublayer(dotLayer)
            layers.append(dotLayer)
        }
    }
    
    private func createAnimation(delay: CFTimeInterval) -> CAKeyframeAnimation {
        let animation = CAKeyframeAnimation(keyPath: "position.x")
        animation.values = [
            layers.first!.frame.origin.x,
            bounds.width - layers.first!.bounds.width
        ]
        animation.keyTimes = [0, 1]
        animation.duration = 1.0
        animation.beginTime = CACurrentMediaTime() + delay
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        return animation
    }
    
}
