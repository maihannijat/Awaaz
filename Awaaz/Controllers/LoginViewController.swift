//
//  ViewController.swift
//  Awaaz
//
//  Created by Maihan Nijat on 2018-05-12.
//  Copyright © 2018 Sunzala Technology. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    // IBOutlets
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    // Variables
    var indicator: UIActivityIndicatorView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.emailField.delegate = self
        self.passwordField.delegate = self
    }
    
    // Login click event
    @IBAction func login(_ sender: UIButton) {
        
        // Check if email and password fields have data
        guard let email = emailField.text, !email.isEmpty else {
            self.displayAlert(title: "Email Required", message: "Please enter your email address!")
            return
        }
        guard let password = passwordField.text, password.count > 5 else {
            self.displayAlert(title: "Password Required", message: "Please enter your password and should be more than 5 characters!")
            return
        }
        
        self.displayIndicator()
        self.httpMethod(loginValues: ["email": email, "password": password])
    }
    
    // Login user
    func httpMethod(loginValues: [String:String]) {
        
        let hostLogin = URL(string: Constants.HOST_LOGIN)
        
        // Force unwrapped. Value exist all the time
        var request = URLRequest(url: hostLogin!)
        
        // Set header fields for the request
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Set body of the request
        request.httpBody = try? JSONEncoder().encode(loginValues)
        
        
        // Make HTTP Request
        let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            
            // Check for HTTP response
            guard let httpResponse = response as? HTTPURLResponse, (data != nil) else {
                self.displayAlert(title: "Login Failed", message: "The login is failed. Please try again!")
                // Remove indicator
                if self.indicator != nil {
                    self.removeIndicator(indicator: self.indicator!)
                }
                return
            }
            
            if httpResponse.statusCode != 200 {
                let error = String(data: data!, encoding: .utf8)
                self.displayAlert(title: "Login Failed", message: (error ?? "Invalid email address or password!"))
                // Remove indicator
                if self.indicator != nil {
                    self.removeIndicator(indicator: self.indicator!)
                }
                return
            }
            
            // Create user after succesfully login
            guard let user = try? JSONDecoder().decode(User.self, from: data!) else {
                self.displayAlert(title: "User Failed", message: "Unable to process use. Please try again!")
                // Remove indicator
                if self.indicator != nil {
                    self.removeIndicator(indicator: self.indicator!)
                }
                return
            }
            
            // Check for token and user id
            // Save user id and token in the defaults
            if user.token != nil || user.id != nil {
                UserDefaults.standard.set(user.token, forKey: "token")
                UserDefaults.standard.set(user.id, forKey: "userId")
                // Launch the MainViewController
                self.performSegue(withIdentifier: "home", sender: self)
            } else {
                self.displayAlert(title: "Information Missing", message: "The user information is missing. Please try again!")
                // Remove indicator
                if self.indicator != nil {
                    self.removeIndicator(indicator: self.indicator!)
                }
                return
            }
            
            
        }
        task.resume()
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
    
    // Hide keyboard with return key (Delegate Method)
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
}

