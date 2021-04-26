//
//  CameraController.swift
//  PhotoBooth
//
//  Created by Ben D. Jones on 9/12/15.
//  Copyright © 2015 Ben D. Jones. All rights reserved.
//

import Foundation
import UIKit

class CameraController: UIViewController {
  @IBOutlet var photoViews: [UIView]!
  
  @IBOutlet weak var countDownLabel: UILabel!
  
  private var displayLink: CADisplayLink?
  private var fastLink: CADisplayLink?
  
  weak var pickerController: UIImagePickerController?
  
  private var justSnapped = false
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    photoViews.forEach {
      $0.layer.cornerRadius = $0.bounds.size.width / 2
      $0.layer.masksToBounds = true
      $0.backgroundColor = UIColor.clear
      $0.layer.borderColor = UIColor.white.cgColor
      $0.layer.borderWidth = 1
    }
  }
  
  func startCaptureSeries() {
    fastLink?.invalidate()
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      self.countDownLabel.text = "Start"
      
      DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
        let displayLink = CADisplayLink(target: self, selector: #selector(self.displayLinkFired(sender:)))
        displayLink.preferredFramesPerSecond = 1
        
        let fastLink = CADisplayLink(target: self, selector: #selector(self.fastLinkFired(sender:)))
        fastLink.preferredFramesPerSecond = 10
        fastLink.add(to: RunLoop.main, forMode: RunLoop.Mode.default)
        self.fastLink = fastLink
        
        displayLink.add(to: RunLoop.main, forMode: RunLoop.Mode.default)
        self.displayLink = displayLink
      }
    }
  }
  
  @objc func fastLinkFired(sender: CADisplayLink) {
    if justSnapped {
      justSnapped = false
      view.backgroundColor = UIColor.clear
    }
  }
  
  var numPhotosTaken: Int = 0 {
    didSet {
      let effected = photoViews[photoViews.startIndex..<numPhotosTaken]
      
      effected.forEach {
        $0.backgroundColor = UIColor.white
      }
    }
  }
  
  private func flashView() {
    justSnapped = true
    
    let alphaAmount: CGFloat = 0.45
    view.backgroundColor = UIColor.white.withAlphaComponent(alphaAmount)
  }
  
  @objc func displayLinkFired(sender: CADisplayLink) {
    if countDownLabel?.text == "Start" {
      countDownLabel?.text = "1"
      
      return
    }
    
    guard let text = countDownLabel?.text else { return }
    guard let fastLink = fastLink else { return }
    
    if let value = Int(text), value < 3 {
      countDownLabel?.text = String(value + 1)
    } else {
      flashView()
      displayLink?.invalidate()
      self.pickerController?.takePicture()
      
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        self.fastLinkFired(sender: fastLink)
        
        self.countDownLabel?.text = "Nice!"
      }
    }
  }
}
