//
//  ShadowImageView.swift
//  ShadowImageView
//
//  Created by olddonkey on 2017/4/29.
//  Copyright © 2017年 olddonkey. All rights reserved.
//

import UIKit
import CoreGraphics

@IBDesignable
class ShadowImageView: UIView {

    private var imageView = UIImageView()
    private var blurredImageView = UIImageView()


    /// Gaussian Blur radius, larger will make the back ground shadow lighter (warning: do not set it too large, 2 or 3 for most cases)
    @IBInspectable
    public var blurRadius: CGFloat = 3 {
        didSet {
            layoutShadow()
        }
    }

    /// The image view contains target image
    @IBInspectable
    public var image: UIImage {
        set {
            imageView.image = newValue
            layoutShadow()
        }
        get {
            return imageView.image ?? UIImage()
        }
    }

    /// Image's corner radius
    @IBInspectable
    public var imageCornerRaidus: CGFloat = 0 {
        didSet {
            imageView.layer.cornerRadius = imageCornerRaidus
            imageView.layer.masksToBounds = true
        }
    }

    /// shadow radius offset in percentage, if you want shadow radius larger, set a postive number for this, if you want it be smaller, then set a negative number
    @IBInspectable
    public var shadowRadiusOffSetPercentage: CGFloat = 0 {
        didSet {
            layoutShadow()
        }
    }

    /// Shadow offset value on x axis, postive -> right, negative -> left
    @IBInspectable
    public var shadowOffSetByX: CGFloat = 0 {
        didSet {
            layoutShadow()
        }
    }


    /// Shadow offset value on y axis, postive -> right, negative -> left
    @IBInspectable
    public var shadowOffSetByY: CGFloat = 0 {
        didSet {
            layoutShadow()
        }
    }

    @IBInspectable
    public var shadowAlpha: CGFloat = 1 {
        didSet {
            blurredImageView.alpha = shadowAlpha
        }
    }

    /// Generate the background color and set it to a image view.
    private func generateBlurBackground() {
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard self != nil else {
                return
            }

            let realImageSize = self!.getRealImageSize(self!.image)
            // Create a containerView to hold the image should apply gaussian blur.
            let containerView = UIView(frame: CGRect(origin: .zero, size: realImageSize.scaled(by: 1.4)))
            containerView.backgroundColor = .clear
            let blurImageView = UIImageView(frame: CGRect(origin: .zero, size: realImageSize))
            blurImageView.center = containerView.center
            blurImageView.image = self!.image
            blurImageView.layer.cornerRadius = self!.imageCornerRaidus
            blurImageView.layer.masksToBounds = true
            containerView.addSubview(blurImageView)

            // Get the UIImage from a UIView.
            let containerImage = UIImage(view: containerView)

            guard let resizedContainerImage = containerImage.resized(withPercentage: 0.2),
                let ciimage = CIImage(image: resizedContainerImage),
                let blurredImage = self!.applyBlur(ciimage: ciimage) else {
                    return
            }

            DispatchQueue.main.async { [weak self] in
                self?.blurredImageView.image = blurredImage
            }
        }
    }

    /// Apply Gaussian Blur to a ciimage, and return a UIImage
    ///
    /// - Parameter ciimage: the imput CIImage
    /// - Returns: output UIImage
    private func applyBlur(ciimage: CIImage) -> UIImage? {

        if let filter = CIFilter(name: "CIGaussianBlur") {
            filter.setValue(ciimage, forKey: kCIInputImageKey)
            filter.setValue(blurRadius, forKeyPath: kCIInputRadiusKey)
            let context = CIContext(options: nil)
            if let output = filter.outputImage, let cgimage = context.createCGImage(output, from: ciimage.extent) {
                return UIImage(cgImage: cgimage)
            }
        }
        return nil
    }

    /// Due to scaleAspectFit, need to calculate the real size of the image and set the corner radius
    ///
    /// - Parameter from: input image
    /// - Returns: the real size of the image
    func getRealImageSize(_ from: UIImage) -> CGSize {
        if contentMode == .scaleAspectFit {
            let scale = min(bounds.size.width / image.size.width, bounds.size.height / image.size.height)
            return image.size.scaled(by: scale)
        } else {
            return image.size
        }
    }

    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        backgroundColor = .clear
        if newSuperview != nil {
            layoutImageView()
        }
    }

    private func layoutShadow() {

        generateBlurBackground()

        let realImageSize = getRealImageSize(image)

        imageView.frame = CGRect(origin: .zero, size: realImageSize)
        imageView.center = CGPoint(x: bounds.width/2, y: bounds.height/2)

        let newSize = realImageSize.scaled(by: 1.4 * (1 + shadowRadiusOffSetPercentage/100))

        blurredImageView.frame = CGRect(origin: .zero, size: newSize)
        blurredImageView.center = CGPoint(x: bounds.width/2 + shadowOffSetByX, y: bounds.height/2 + shadowOffSetByY)
        blurredImageView.contentMode = contentMode
        blurredImageView.alpha = shadowAlpha

        addSubview(blurredImageView)
        sendSubview(toBack: blurredImageView)
    }

    private func layoutImageView() {
        imageView.image = image
        imageView.frame = bounds

        imageView.layer.cornerRadius = imageCornerRaidus
        imageView.layer.masksToBounds = true
        imageView.contentMode = contentMode
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowRadius = 13
        imageView.layer.shadowOffset = CGSize(width: 12, height: 12)
        addSubview(imageView)
    }

}

private extension CGSize {
    /// Generates a new size that is this size scaled by a cerntain percentage
    ///
    /// - Parameter percentage: the percentage to scale to
    /// - Returns: a new CGSize instance by scaling self by the given percentage
    func scaled(by percentage: CGFloat) -> CGSize {
        return CGSize(width: width * percentage, height: height * percentage)
    }
}

private extension UIImage {

    /// Resize the image to a centain percentage
    ///
    /// - Parameter percentage: Percentage value
    /// - Returns: UIImage(Optional)
    func resized(withPercentage percentage: CGFloat) -> UIImage? {
        let canvasSize = size.scaled(by: percentage)
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }


    /// Method to create a UIImage from UIView
    ///
    /// - Parameter view: the input view
    convenience init(view: UIView) {
        UIGraphicsBeginImageContext(view.frame.size)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        if let cgImage = image?.cgImage {
            self.init(cgImage: cgImage)
        } else {
            self.init()
        }
    }
}
