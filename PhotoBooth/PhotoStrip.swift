//
//  PhotoStrip.swift
//  PhotoBooth
//
//  Created by Ben D. Jones on 9/12/15.
//  Copyright © 2015 Ben D. Jones. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics

struct PhotoStrip {
  let photos: [UIImage]
  let brandImage: UIImage
  
  init(photos: [UIImage], logo: UIImage) {
    self.photos = photos.reversed().map { $0.fixOrientation() }
    
    brandImage = logo
  }
  
  func renderResult(completionHandler: @escaping ((UIImage) -> Void)) {
    DispatchQueue.global(qos: .userInteractive).async() {
      let maxWidth: CGFloat = self.photos.reduce(CGFloat(0)) { return max($0, $1.size.width) }
      let totalHeight: CGFloat = self.photos.reduce(CGFloat(10)) { return $0 + $1.size.height + 10 }
      
      UIGraphicsBeginImageContextWithOptions(CGSize(width: maxWidth, height: totalHeight), false, UIScreen.main.scale)
      let context = UIGraphicsGetCurrentContext()
      
      var currentOrigin = CGPoint(x: 0, y: 10)
      self.photos.forEach {
        let rect = CGRect(origin: currentOrigin, size: $0.size)
        context!.draw($0.cgImage!, in: rect)
        currentOrigin = CGPoint(x: 0, y: currentOrigin.y + $0.size.height + 10)
      }
      
      // NOTE: Draw the logo on the final image
      let brandOrigin = CGPoint(x: maxWidth - self.brandImage.size.width, y: 10)
      let brandRect = CGRect(origin: brandOrigin, size: self.brandImage.size)
      context?.draw(self.brandImage.cgImage!, in: brandRect)
      
      
      guard let upsidedownImage = UIGraphicsGetImageFromCurrentImageContext() else { return }
      let image = UIImage(cgImage: upsidedownImage.cgImage!, scale: UIScreen.main.scale, orientation: .downMirrored)
      
      UIGraphicsEndImageContext()
      
      DispatchQueue.main.async {
        completionHandler(image)
      }
    }
  }
}

extension UIImage {
  func fixOrientation() -> UIImage {
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    var transform: CGAffineTransform = CGAffineTransform.identity
    
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    switch imageOrientation {
      case .down, .downMirrored:
        transform = transform.translatedBy(x: size.width, y: size.height)
        transform = transform.rotated(by: .pi)
      case .left, .leftMirrored:
        transform = transform.translatedBy(x: size.width, y: 0)
        transform = transform.rotated(by: .pi / 2)
      case .right, .rightMirrored:
        transform = transform.translatedBy(x: 0, y: size.height)
        transform = transform.rotated(by: -.pi / 2)
      case .up:
        return self
      default:
        debugPrint("No op")
    }
    
    // Second pass
    switch imageOrientation {
      case .upMirrored, .downMirrored:
        transform = transform.translatedBy(x: size.width, y: 0)
        transform = transform.scaledBy(x: -1, y: 1)
      case .leftMirrored, .rightMirrored:
        transform = transform.translatedBy(x: size.height, y: 0)
        transform = transform.scaledBy(x: -1, y: 1)
      default:
        debugPrint("No op")
    }
    
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    let ctx = CGContext(
      data: nil,
      width: Int(size.width),
      height: Int(size.height),
      bitsPerComponent: self.cgImage?.bitsPerComponent ?? 4,
      bytesPerRow: 0,
      space: self.cgImage!.colorSpace!,
      bitmapInfo: self.cgImage!.bitmapInfo.rawValue
    )
    
    
    switch imageOrientation {
      case .left, .leftMirrored, .right, .rightMirrored:
        let rect = CGRect(x: 0, y: 0, width: size.height, height: size.width)
        ctx?.draw(self.cgImage!, in: rect)
      default:
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        ctx?.draw(self.cgImage!, in: rect)
    }
    
    
    // And now we just create a new UIImage from the drawing context
    let cgimg: CGImage = ctx!.makeImage()!
    let imgEnd:UIImage = UIImage(cgImage: cgimg)
    
    return imgEnd
  }
  
  class func resizeImage(image: UIImage, newHeight: CGFloat) -> UIImage {
    
    let scale = newHeight / image.size.height
    let newWidth = image.size.width * scale
    let newSize = CGSize(width: newWidth, height: newHeight)
    UIGraphicsBeginImageContext(newSize)
    image.draw(in: CGRect(origin: CGPoint(x: 0, y: 0), size: newSize))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage!
  }
}
