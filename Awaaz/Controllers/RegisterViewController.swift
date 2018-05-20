//
//  RegisterViewController.swift
//  Awaaz
//
//  Created by Maihan Nijat on 2018-05-19.
//  Copyright © 2018 Sunzala Technology. All rights reserved.
//

import UIKit
import Alamofire

class RegisterViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    // IBOutlets
    @IBOutlet weak var firstName: UITextField!
    @IBOutlet weak var lastName: UITextField!
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var genderPicker: UIPickerView!
    @IBOutlet weak var profileImage: UIImageView!
    
    // Variables
    var indicator: UIActivityIndicatorView?
    var imageString: String?
    var imageData: Data?
    
    // List of values for gender picker
    let genderValues = ["Male", "Female"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Assign delegates to the picker
        self.genderPicker.delegate = self
        self.genderPicker.dataSource = self
        
        // Set text field delegates
        self.firstName.delegate = self
        self.lastName.delegate = self
        self.email.delegate = self
        self.password.delegate = self
    }
    
    // Populate values in the gender picker
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.genderValues.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.genderValues[row]
    }
    
    // Select image from photo library or take with a camera
    @IBAction func selectImage(_ sender: UIButton) {
        
        // Display alert to ask user for selecting the source of image
        let alert = UIAlertController(title: "Image Source", message: "Please select your image source to set your profile image.", preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "Camera", style: .default, handler: { _ in
            // Open Camera
            self.openCamera()
        })
        let galleryAction = UIAlertAction(title: "Photo Library", style: .default, handler: {_ in
            // Open Photo Library
            self.openLibrary()
        })
        
        alert.addAction(cameraAction)
        alert.addAction(galleryAction)
        
        // Prevent app from crashing on iPad due to .actionsheet
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            alert.popoverPresentationController?.sourceView = sender
            alert.popoverPresentationController?.sourceRect = sender.bounds
            alert.popoverPresentationController?.permittedArrowDirections = .up
        default:
            break
        }
        
        self.present(alert, animated: true)
    }
    
    // Image picker controller
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            if let data = UIImageJPEGRepresentation(image, 0.5) {
                self.imageData = data
                self.imageString = data.base64EncodedString()
            }
            self.profileImage.image = image
        } else {
            self.displayAlert(title: "Phone Selection Failed", message: "Unexpected error happened to a profile image!")
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    // Open Camera
    func openCamera() {
        if (UIImagePickerController .isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)) {
            
            let image = UIImagePickerController()
            image.delegate = self
            image.sourceType = .camera
            image.allowsEditing = false
            self.present(image, animated: true)
            
        } else {
            self.displayAlert(title: "Camera Unavailable", message: "Your camera is not available. Please try photo library instead!")
        }
    }
    
    // Open Photo Library
    func openLibrary() {
        let image = UIImagePickerController()
        image.delegate = self
        image.sourceType = .photoLibrary
        image.allowsEditing = false
        self.present(image, animated: true)
    }
    
    // Submit the information to the server for registration
    @IBAction func submit(_ sender: UIButton) {
        if self.firstName.text == "" {
            self.displayAlert(title: "First Name Required", message: "Please enter your first name to proceed!")
            return
        }
        
        if self.lastName.text == "" {
            self.displayAlert(title: "Last Name Required", message: "Please enter your last name to proceed!")
            return
        }
        
        if self.email.text == "" {
            self.displayAlert(title: "Email Required", message: "Please enter your email to proceed!")
            return
        }
        
        guard let password = password.text, password.count > 5 else {
            self.displayAlert(title: "Password Required", message: "Please enter your password and should be more than 5 characters!")
            return
        }
        let gender = self.genderValues[genderPicker.selectedRow(inComponent: 0)]
        
        // Assign register values in a dictionary
        var registerValues: Parameters = [
            "f_name": self.firstName.text!,
            "l_name": self.lastName.text!,
            "gender": gender,
            "email": self.email.text!,
            "password": password
        ]
        
        // Add image to the values
        if self.imageString != nil {
            registerValues["image"] = self.imageString!
        }
        
        // Display the indicator
        self.displayIndicator()
        
        // Call the HTTP Method and pass the register values
        self.httpMethod(imageData: self.imageData, parameters: registerValues)
    }
    
    // HTTP Post method to submit the user information for registration
    func httpMethod(imageData: Data?, parameters: [String : Any], onCompletion: ((User?) -> Void)? = nil, onError: ((Error?) -> Void)? = nil){
        
        let url = Constants.HOST_REGISTER
        
        let headers: HTTPHeaders = [
            "Content-type": "multipart/form-data",
            "Accept": "application/json"
        ]
        
        Alamofire.upload(multipartFormData: { (multipartFormData) in
            for (key, value) in parameters {
                multipartFormData.append("\(value)".data(using: String.Encoding.utf8)!, withName: key as String)
            }
            
            if let data = imageData {
                // Generate name of the image from random number and timestamp
                let name = "\(arc4random_uniform(1000))\(Int(Date().timeIntervalSince1970)).jpeg"
               
                // Append image data
                multipartFormData.append(data, withName: "image", fileName: name, mimeType: "image/jpeg")
            }
            
        }, usingThreshold: UInt64.init(), to: url, method: .post, headers: headers) { (result) in
            switch result {
            case .success(let upload, _, _):
                upload.responseJSON { response in
    
                    guard let data = response.data else { return }
                    
                    if let statusCode = response.response?.statusCode, (statusCode == 200) {
                        
                        let user = try? JSONDecoder().decode(User.self, from: data)
                        // Check for token and user id
                        // Save user id and token in the defaults
                        if user?.token != nil || user?.id != nil {
                            UserDefaults.standard.set(user!.token, forKey: "token")
                            UserDefaults.standard.set(user!.id, forKey: "userId")
                            // Launch the MainViewController
                            self.performSegue(withIdentifier: "home", sender: self)
                        }
                    } else {
                        let errorObject = try? JSONDecoder().decode(CustomError.self, from: data)
                        guard let errors = errorObject?.errors else {
                            print("fails")
                            return
                        }
                        
                        // Display if there is any error
                        self.displayAlert(title: "Invalid Input", message: CustomError.getErrors(errors: errors))
                    }
                    
                    if let err = response.error {
                        onError?(err)
                        return
                    }
                    onCompletion?(nil)
                }
                // Remove the indicator
                if self.indicator != nil {
                    self.removeIndicator(indicator: self.indicator!)
                }
            case .failure(let error):
                print("Error in upload: \(error.localizedDescription)")
                onError?(error)
                
                // Remove the indicator
                if self.indicator != nil {
                    self.removeIndicator(indicator: self.indicator!)
                }
            }
        }
    }
    
    // Display Alert UI Controller
    func displayAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(action)
        // Display the alert on the main thread
        DispatchQueue.main.async(execute: {
            self.present(alert, animated: true, completion: nil)
        })
    }
    
    // Display UI Indicator
    func displayIndicator() {
        indicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        // Display in the center
        indicator?.center = view.center
        // Display when animating
        indicator?.hidesWhenStopped = false
        // Start displaying
        indicator?.startAnimating()
        // Add it in the subview
        view.addSubview(indicator!)
    }
    
    // Remove and stop the activity indicator from the view
    func removeIndicator(indicator: UIActivityIndicatorView)
    {
        DispatchQueue.main.async
            {
                indicator.stopAnimating()
                indicator.removeFromSuperview()
        }
    }
    
    // Hide keyboard with the return key
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
}
