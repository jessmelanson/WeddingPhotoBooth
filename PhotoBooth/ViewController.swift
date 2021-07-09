//
//  ViewController.swift
//  PhotoBooth
//
//  Created by Ben D. Jones on 9/12/15.
//  Copyright © 2015 Ben D. Jones. All rights reserved.
//

import UIKit
import MessageUI

import CoreLocation
import Photos

private class RenderSaver {
  static var locationManager: CLLocationManager?
  
  static var render: UIImage? {
    didSet {
      guard let render = render else { return }
      
      locationManager?.requestLocation()
      
      DispatchQueue.main.async {
        PHPhotoLibrary.shared().performChanges({
          let request = PHAssetChangeRequest.creationRequestForAsset(from: render)
          request.creationDate = NSDate() as Date
          
          if let location = locationManager?.location {
            request.location = location
          }
        }, completionHandler: { success, error in
          if !success || error != nil {
            print("Bad things \(String(describing: error))")
          }
        })
      }
    }
  }
}

class ViewController: UIViewController {
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet var splashImageView: UIImageView!
    
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var instructionsLabel: UILabel!
  
  private var prompting = false
  private var photos = [UIImage]()
  
  private var imageController: UIImagePickerController?
  
  lazy var cameraController: CameraController? = {
    let vc = self.storyboard?.instantiateViewController(withIdentifier: "CameraController") as? CameraController
    
    vc?.view.frame = self.view.frame
    vc?.view.layoutIfNeeded()
    
    return vc
  }()
  
  var printController: UIPrintInteractionController?
  
  var photoStrip: PhotoStrip? {
    didSet {
      if let strip = photoStrip {
        self.imageView?.isHidden = false
        self.instructionsLabel.isHidden = true
        self.titleLabel.isHidden = true
        self.splashImageView.isHidden = true
        strip.renderResult {
          RenderSaver.locationManager = self.manager
          RenderSaver.render = $0
          
          let printActionController = UIPrintInteractionController.shared
          printActionController.delegate = self
          
          let printInfo = UIPrintInfo.printInfo()
          printInfo.outputType = .photo
          printInfo.jobName = "PhotoStrip"
          printInfo.duplex = .none
          printActionController.printInfo = printInfo
          printActionController.printingItem = $0
          self.printController = printActionController
          
          let animation = CABasicAnimation()
          animation.keyPath = "backgroundColor"
          animation.toValue = UIColor.black
          animation.fromValue = UIColor.white
          animation.duration = 0.4
          animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
          self.view.layer.add(animation, forKey: "BGColorAnimation")
          
          self.view.backgroundColor = UIColor.white
          self.imageView.image = UIImage.resizeImage(image: $0, newHeight: self.view.bounds.height)
          self.imageView?.setNeedsLayout()
          
          DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.promptForActions()
          }
        }
      } else {
        let animation = CABasicAnimation()
        animation.keyPath = "backgroundColor"
        animation.toValue = UIColor.white
        animation.fromValue = UIColor.black
        animation.duration = 0.4
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
        view.layer.add(animation, forKey: "BGColorAnimation")
        
        imageView?.image = nil
        instructionsLabel.isHidden = false
        titleLabel.isHidden = false
        splashImageView.isHidden = false
        photos.removeAll(keepingCapacity: true)
      }
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    splashImageView.image = UIImage(named: "photographer")!
  }
  
  lazy var manager: CLLocationManager = {
    let manager = CLLocationManager()
    manager.delegate = self
    
    if CLLocationManager.locationServicesEnabled() {
      manager.requestLocation()
    }
    
    return manager
  }()
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    PHPhotoLibrary.requestAuthorization { status in
      switch status {
        case .denied, .notDetermined, .restricted:
          self.showAlert(message: "Sorry we need photo access, we're trying to make a guest book ya know!")
        default:
          debugPrint("Ok ok it's all good!")
      }
    }
    
    if manager.authorizationStatus == .notDetermined {
      manager.requestWhenInUseAuthorization()
    }
    
    manager.requestLocation()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  override var prefersStatusBarHidden: Bool {
    return true
  }

  @IBAction func tapGestureTriggered(_ sender: UIControl) {
    if let _ = photoStrip {
      promptForActions()
    } else {
      startCaptureSeries()
    }
  }
  
  private func promptForActions() {
    let alert = UIAlertController(title: "Photo Booth", message: "Awesome!", preferredStyle: .actionSheet)
    
    let printAction = UIAlertAction(title: "Print", style: .default) { _ in
      alert.dismiss(animated: false, completion: nil)
      self.printImageTapped()
    }
    
    let emailAction = UIAlertAction(title: "Email", style: .default) { _ in
      alert.dismiss(animated: false, completion: nil)
      self.showEmailDialog()
    }
    
    let textAction = UIAlertAction(title: "iMessage", style: .default) { _ in
      alert.dismiss(animated: false, completion: nil)
      self.showTextDialog()
    }
    
    let restartAction = UIAlertAction(title: "Start Over", style: .destructive) { _ in
      self.photoStrip = nil
      alert.dismiss(animated: true, completion: nil)
    }
    
    let cancelAction = UIAlertAction(title: "Nevermind", style: .cancel) { _ in
      alert.dismiss(animated: true, completion: nil)
    }
    
//    alert.addAction(printAction)
    alert.addAction(emailAction)
    alert.addAction(textAction)
    alert.addAction(restartAction)
    alert.addAction(cancelAction)
    
    if let popoverPresenter = alert.popoverPresentationController {
      alert.modalPresentationStyle = .popover
      
      popoverPresenter.sourceView = view
      popoverPresenter.sourceRect = CGRect(x: (view.frame.width / 3) * 2 - 100, y: 100, width: 300, height: 300)
      popoverPresenter.permittedArrowDirections = .left
    }
    
    if let pvc = presentedViewController {
      pvc.dismiss(animated: false) {
        self.present(alert, animated: true, completion: nil)
      }
    } else {
      present(alert, animated: true, completion: nil)
    }
  }
  
  private func startCaptureSeries() {
    if let _ = UIImagePickerController.availableCaptureModes(for: .front) {
      let imageController = UIImagePickerController()
      
      imageController.sourceType = .camera
      
      imageController.cameraCaptureMode = .photo
      imageController.cameraDevice = .front
      imageController.cameraFlashMode = .off
      
      imageController.delegate = self
      imageController.edgesForExtendedLayout = .all
      
      if let
          ccVC = cameraController,
         let imgControllerOverlayFrame = imageController.cameraOverlayView?.frame
      {
        ccVC.view.frame = imgControllerOverlayFrame
        imageController.cameraOverlayView = ccVC.view
        ccVC.resetPhotoViews()
        
        let screenSize = UIScreen.main.bounds.size
        let cameraAspectRatio: CGFloat = 4.0 / 3.0 //! Note: 4.0 and 4.0 works
        let imageWidth = floorf(Float(screenSize.width * cameraAspectRatio))
        
        let heightByImageWidth = Float(screenSize.height + 120) / imageWidth
        let scale = CGFloat(ceilf((heightByImageWidth * 10.0) / 10.0))
        
        imageController.cameraViewTransform = CGAffineTransform(scaleX: scale, y: scale)
      }
      
      imageController.modalPresentationStyle = .overCurrentContext
      imageController.transitioningDelegate = self
      imageController.showsCameraControls = false
      imageController.isNavigationBarHidden = true
      
      cameraController?.pickerController = imageController
      self.imageController = imageController
      
      prompting = true
      
      present(imageController, animated: true) {
        self.cameraController?.startCaptureSeries()
      }
    } else {
      showAlert(message: "Facetime camera not present!")
    }
  }
  
  private func showAlert(message: String) {
    let alert = UIAlertController(title: "Photo Booth", message: message, preferredStyle: .alert)
    let okAction = UIAlertAction(title: "Ok", style: .cancel) { _ in
      alert.dismiss(animated: true, completion: nil)
    }
    
    alert.addAction(okAction)
    
    present(alert, animated: true, completion: nil)
  }
  
  private func printImageTapped() {
    let handler: UIPrintInteractionController.CompletionHandler = { controller, completed, error in
      guard error == nil else {
        if let error = error {
          controller.dismiss(animated: true)
          
          self.showAlert(message: error.localizedDescription)
        }
        return
      }
      
      if completed {
        self.promptForActions()
      } else {
        controller.dismiss(animated: false)
        self.showAlert(message: "Printing failed!")
      }
    }
    
    if UIDevice.current.userInterfaceIdiom == .pad {
      printController?.present(from: self.view.frame, in: self.view, animated: true, completionHandler: handler)
    } else {
      printController?.present(animated: true, completionHandler: handler)
    }
  }
}

extension ViewController : UIPrintInteractionControllerDelegate {
  func printInteractionController(_ printInteractionController: UIPrintInteractionController, choosePaper paperList: [UIPrintPaper]) -> UIPrintPaper {
    let pageSize = CGSize(width: 288, height: 432)
    
    let bestPaper = UIPrintPaper.bestPaper(forPageSize: pageSize, withPapersFrom: paperList)
    
    print("iOS says best paper size is \(bestPaper.paperSize.width),\(bestPaper.paperSize.height)")
    
    return bestPaper
  }
}

extension ViewController : UIViewControllerTransitioningDelegate {
  func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    return FadeTransitionAnimator()
  }
  
  func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    return FadeTransitionAnimator()
  }
}

extension ViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    if let pickedImage = info[UIImagePickerController.InfoKey(rawValue: UIImagePickerController.InfoKey.originalImage.rawValue)] as? UIImage {
      photos.append(pickedImage)
      cameraController?.numPhotosTaken = photos.count
      
      if photos.count == 3 {
        self.makeBoothPhotos()
        
        picker.dismiss(animated: true, completion: nil)
        imageController = nil
      } else {
        cameraController?.startCaptureSeries()
      }
    }
  }
  
  private func makeBoothPhotos() {
    guard let brandImage = UIImage(named: "BrandImage") else { return }
    
    self.photoStrip = PhotoStrip(photos: self.photos, logo: brandImage)
  }
  
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    dismiss(animated: true, completion: nil)
  }
}

struct Formatters {
  static let prettyDateTimeFormatterLocal: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.timeZone = NSTimeZone.default
    
    let locale = NSLocale.current
    dateFormatter.dateStyle = .medium
    dateFormatter.timeStyle = .medium
    dateFormatter.locale = locale
    
    return dateFormatter
  }()
}

extension ViewController {
  func showEmailDialog() {
    if MFMailComposeViewController.canSendMail() {
      let composeVC = MFMailComposeViewController(nibName: nil, bundle: nil)
      composeVC.mailComposeDelegate = self
      composeVC.setSubject(getShareSubject())
      composeVC.setMessageBody("Thanks for coming! We love you!", isHTML: false)
      photoStrip?.renderResult {
        guard let resultData = $0.jpegData(compressionQuality: 0.84) else { return }
        composeVC.addAttachmentData(resultData, mimeType: "image/jpeg", fileName: "PhotoBooth.jpeg")
        self.present(composeVC, animated: true, completion: nil)
      }
    } else {
      showAlert(message: "Can't send email. Try something else.")
    }
  }
    
  func showTextDialog() {
    if MFMessageComposeViewController.canSendText() {
      let composeVC = MFMessageComposeViewController(nibName: nil, bundle: nil)
      composeVC.messageComposeDelegate = self
      composeVC.body = getShareSubject()
      photoStrip?.renderResult {
        guard let resultData = $0.jpegData(compressionQuality: 0.84) else { return }
        composeVC.addAttachmentData(resultData, typeIdentifier: "image/jpeg", filename: "PhotoBooth.jpeg")
        self.present(composeVC, animated: true, completion: nil)
      }
    } else {
      showAlert(message: "Can't send iMessage. Try something else.")
    }
  }

  private func getShareSubject() -> String {
    return "Photo booth @ Andrew & Jess's Wedding took a photo at \(Formatters.prettyDateTimeFormatterLocal.string(from: NSDate() as Date))"
  }
}

extension ViewController : MFMailComposeViewControllerDelegate {
  func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
    if let error = error {
      controller.dismiss(animated: true) {
        self.showAlert(message: error.localizedDescription)
      }
    } else {
      controller.dismiss(animated: true, completion: nil)
    }
  }
}

extension ViewController: MFMessageComposeViewControllerDelegate {
  func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
    controller.dismiss(animated: true, completion: nil)
  }
}

extension ViewController : CLLocationManagerDelegate {
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    print("Location manager failed with error: \(error)")
  }
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    print("updated location to locations \(locations)")
  }
}
