//
//  ViewController.swift
//  HomeWork
//
//  Created by Robert on 1/2/17.
//  Copyright © 2017 Robert. All rights reserved.
//

import UIKit
import TesseractOCR
import MBProgressHUD
import GoogleMobileAds


class ViewController: UIViewController {

    var originalImage:UIImage!
    @IBOutlet weak var ivPhoto: UIImageView!
    @IBOutlet weak var bannerView: GADBannerView!
    var layersRect:[CALayer]! = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupAds()
    }
    
    func setupAds() {
        //Setup Admods
        self.bannerView.adUnitID = "ca-app-pub-1414338236854162/8626568335";
        self.bannerView.rootViewController = self;
        self.bannerView.load(GADRequest())
        
        //Setup Vungle
        VungleSDK.shared().delegate = self
    }

    func clear() {
        self.ivPhoto.layer.sublayers?.forEach({$0.removeFromSuperlayer()})
        self.layersRect = []
    }
    
    @IBAction func takePicture(_ sender: Any) {
        clear()
        let alertController = UIAlertController(title: "Take Image", message: "Please choose a source", preferredStyle: .actionSheet);
        
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alertController.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (action:UIAlertAction) in
                self.showPhotoPicker(type: .camera)
            }))
        }
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            alertController.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { (action:UIAlertAction) in
                self.showPhotoPicker(type: .photoLibrary)
            }))
        }
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alertController, animated: true, completion: nil);
    }
    
    func showPhotoPicker(type:UIImagePickerControllerSourceType) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = type
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func processPicture(_ sender: Any) {
        do {
            try VungleSDK.shared().playAd(self)
        } catch let error{
            print (error.localizedDescription)
        }
        //self.performSegue(withIdentifier: "segue_ads", sender: nil)
    }
    
    func processImages() {
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud.label.text = "Loading..."
        hud.mode = .indeterminate
        
        let group = DispatchGroup()
        var results:[String] = []
        
        group.enter()
        DispatchQueue.global().async {
            let imagesToProcess = self.getImages();
            
            for image in imagesToProcess {
                let tesseract = G8Tesseract(language: "eng")
                tesseract?.engineMode = .tesseractCubeCombined
                tesseract?.pageSegmentationMode = .auto
                tesseract?.image = image.g8_blackAndWhite()
                
                if let recognizedText = tesseract?.recognizedText {
                    results.append(recognizedText)
                }
            }
            
            group.leave()
        }
        
        group.notify(queue: DispatchQueue.main) {
            hud.hide(animated: true)
            self.getResponse(requestQuestions: results)
        }
    }
    
    func getResponse(requestQuestions:[String]) {
        
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud.label.text = "Loading..."
        hud.mode = .indeterminate
        
        var queries = "{\"queries\":["
        for (index,query) in requestQuestions.enumerated() {
            queries.append("\"\(query.replacingOccurrences(of: "\n", with: ""))\"")
            if index < requestQuestions.count && requestQuestions.count > 1 {
                queries.append(",")
            }
        }
        queries.append("]}")
        
        if let query = queries.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            let urlLiteral:String = "http://legendarycrown.com/hwk?key=VwNgus5ctVPTMXUBwv3fFeUG&request=\(query)"
            if let url = URL(string: urlLiteral) {
                let request = URLRequest(url: url)
                let sessionTask = URLSession.shared.dataTask(with: request, completionHandler: { (data:Data?, response:URLResponse?, error:Error?) in
                    DispatchQueue.main.async {
                        hud.hide(animated: true)
                        if error != nil {
                            let alertController = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert)
                            alertController.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                            self.present(alertController, animated: true, completion: nil)
                        } else {
                        
                            if let data = data, let jsonObject = try? JSONSerialization.jsonObject(with: data, options: .allowFragments), let responseObject = jsonObject as? [String:AnyObject], let answers = responseObject["answers"] as? [[String:String]] {
                                self.performSegue(withIdentifier: "segue_scanner_result", sender: answers)
                            } else {
                                let alertController = UIAlertController(title: "Error", message: "Ha ocurrido un error", preferredStyle: .alert)
                                alertController.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                                self.present(alertController, animated: true, completion: nil)
                            }
                        }
                    }
                    
                })
                sessionTask.resume()
            }
        }

    }
    
    //MARK: Move to extension
    func scaleImage(image: UIImage, maxDimension: CGFloat) -> UIImage? {
        
        var scaledSize = CGSize(width: maxDimension, height: maxDimension)
        var scaleFactor: CGFloat
        
        if image.size.width > image.size.height {
            scaleFactor = image.size.height / image.size.width
            scaledSize.width = maxDimension
            scaledSize.height = scaledSize.width * scaleFactor
        } else {
            scaleFactor = image.size.width / image.size.height
            scaledSize.height = maxDimension
            scaledSize.width = scaledSize.height * scaleFactor
        }
        
        UIGraphicsBeginImageContext(scaledSize)
        image.draw(in: CGRect(x:0, y:0, width:scaledSize.width, height:scaledSize.height))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
    
    var currentLayer:CALayer!
    
    @IBAction func dragImage(_ sender: UIPanGestureRecognizer) {
        
        let touchPoint = sender.location(in: sender.view)
        
        switch sender.state {
        case .began:
            print("Drag began")
            print("Touch x:\(touchPoint.x) y:\(touchPoint.y)")
            currentLayer = CALayer()
            currentLayer.anchorPoint = CGPoint(x: 0, y: 0)
            currentLayer.borderColor = UIColor.red.cgColor
            currentLayer.borderWidth = 0.7
            currentLayer.frame = CGRect(x: touchPoint.x, y: touchPoint.y, width: 0, height: 0)
            self.ivPhoto.layer.addSublayer(currentLayer)
        case .changed:
            
            var xOrigin = 0
            var yOrigin = 0
            if touchPoint.x < currentLayer.frame.origin.x {
                xOrigin = 1
            }
            
            if touchPoint.y < currentLayer.frame.origin.y {
                yOrigin = 1
            }
            
            currentLayer.anchorPoint = CGPoint(x:xOrigin,y:yOrigin)
            let finalWidth = currentLayer.frame.origin.x - touchPoint.x
            let finalHeight = currentLayer.frame.origin.y - touchPoint.y
            currentLayer.bounds = CGRect(x: 0, y: 0, width:finalWidth, height: finalHeight)
        case .ended:
            print("Final Size : \(currentLayer.frame.size.width),\(currentLayer.frame.size.height)")
            self.layersRect.append(currentLayer)
        default:
            break
        }
        
    }
    
    
    //Mark : Move to extension
    func getImages()->[UIImage] {
        var result:[UIImage] = []
        
        if let imagePicked = self.ivPhoto.image {
            
            let widthRatio:CGFloat = self.ivPhoto.bounds.size.width / imagePicked.size.width;
            let heightRatio:CGFloat = self.ivPhoto.bounds.size.height / imagePicked.size.height;
            
            for layer in self.layersRect {
                
                var cropRect:CGRect
                if (widthRatio < heightRatio) {
                    let offset = (self.ivPhoto.bounds.size.height - imagePicked.size.height * widthRatio) / 2
                    cropRect = CGRect(x: layer.frame.origin.x / widthRatio, y: (layer.frame.origin.y - offset)/widthRatio, width: layer.frame.size.width / widthRatio, height: layer.frame.size.height / widthRatio)
                } else {
                    let offset = (self.ivPhoto.bounds.size.width - imagePicked.size.width * heightRatio) / 2
                    cropRect = CGRect(x: layer.frame.origin.x / heightRatio, y: (layer.frame.origin.y - offset)/heightRatio, width: layer.frame.size.width / heightRatio, height: layer.frame.size.height / heightRatio)
                }
                
                if let imageCropped = imagePicked.crop(rect: cropRect) {
                    result.append(imageCropped)
                }
            }
        
        }
        
        return result
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "segue_scanner_result" {
            let resultViewController = segue.destination as! ResultViewController
            var result:[String] = []
            for answer in (sender as? [[String:String]])! {
                result.append(answer["0"]!)
            }
            resultViewController.results = result
        }
        
    }
    
}

extension ViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let image:UIImage? = info[UIImagePickerControllerOriginalImage] as? UIImage
        self.ivPhoto.image = image;
        self.originalImage = image;
        picker.dismiss(animated: true, completion: nil)
    }
    
}

extension ViewController : VungleSDKDelegate {
    
    func vungleSDKwillCloseAd(withViewInfo viewInfo: [AnyHashable : Any]!, willPresentProductSheet: Bool) {
        self.processImages()
    }
    
}

// MARK: Move to Utility
extension UIImage {
    func crop(rect: CGRect) -> UIImage? {
        var scaledRect = rect
        scaledRect.origin.x *= scale
        scaledRect.origin.y *= scale
        scaledRect.size.width *= scale
        scaledRect.size.height *= scale
        guard let imageRef: CGImage = cgImage?.cropping(to: scaledRect) else {
            return nil
        }
        return UIImage(cgImage: imageRef, scale: scale, orientation: imageOrientation)
    }
}

