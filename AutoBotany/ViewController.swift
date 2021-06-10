//
//  ViewController.swift
//  AutoBotany
//
//  Created by Chris Hennemann on 12/16/20.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    let imagePicker = UIImagePickerController()
    
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
       
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Sets controller as delegate
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .camera //Sub out for camera
        
    }
    
    // MARK: - UIImagePickerControllerDelegate Methods
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info:[UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
//            imageView.contentMode = .scaleAspectFit
            guard let convertedCIImage = CIImage(image: pickedImage) else {
                fatalError("cannot convert to CIImage.")
            }
            
            detect(image: convertedCIImage)
        }
        
        dismiss(animated: true, completion:nil)
        
    }
    
    func detect (image: CIImage) {
        //VM Core Model
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Cannot Import Model.")
        }

        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let classification = request.results?.first as? VNClassificationObservation else {
                fatalError("Cannot classify image.")
            }

            self.navigationItem.title = classification.identifier.capitalized
            self.requestInfo(flowerName: classification.identifier)
        }

        let handler = VNImageRequestHandler(ciImage: image)

        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
    func requestInfo(flowerName: String) {
    
        // API should be handled in the struct
        let wikipediaURL = "https://en.wikipedia.org/w/api.php"
        
        //Parameters for Wikipedia
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize": "500"
        ]
            
    
        Alamofire.request(wikipediaURL, method: .get, parameters: parameters).responseJSON { (response) in
            // Change statement upon result
            if response.result.isSuccess {
                       //                print(response.request)
                       //
                       //                print("Success! Got the flower data")
                       let flowerJSON : JSON = JSON(response.result.value!)
                       
                       let pageid = flowerJSON["query"]["pageids"][0].stringValue //Format for writing JSON
                       
                       let flowerDescription = flowerJSON["query"]["pages"][pageid]["extract"].stringValue
                       let flowerImageURL = flowerJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                       
                       //                print("pageid \(pageid)")
                       //                print("flower Descript \(flowerDescription)")
                       //                print(flowerJSON)
                       //
                self.label.text = flowerDescription
                self.imageView.sd_setImage(with: URL(string: flowerImageURL))
                
            } else {
                print(response.result.error)
            }
        }
        
    }
    
}

