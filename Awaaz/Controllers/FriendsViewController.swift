//
//  FriendsViewController.swift
//  Awaaz
//
//  Created by Maihan Nijat on 2018-05-14.
//  Copyright © 2018 Sunzala Technology. All rights reserved.
//

import UIKit

class FriendsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    // IBOutlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    // Variables
    var request: URLRequest?
    var hostFriend: URL?
    var userId: Int?
    var token: String?
    var friends: [Friend]?
    var filteredFriends: [Friend]?
    var friend: Friend?
    var indicator: UIActivityIndicatorView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get user id and token from Defaults
        userId = UserDefaults.standard.integer(forKey: "userId")
        token = UserDefaults.standard.string(forKey: "token")
        
        // HTTP Request / URLSession
        request = URLRequest(url: URL(string: Constants.HOST_FRIEND)!)
        // Set header values for the request
        request?.setValue("application/json", forHTTPHeaderField: "Accept")
        request?.setValue("application/json", forHTTPHeaderField: "content-type")
        // Set authorization token for the method
        request?.setValue(("Bearer \(self.token!)"), forHTTPHeaderField: "Authorization")
        
        (token != nil) ? self.httpGetMethod() : print("Unauthorized Access Redirect to login page")
    }
    
    // HTTP Method to request friends list
    func httpGetMethod() {
        
        // Display indicator
        self.displayIndicator()
        
        // Create get task
        let task = URLSession.shared.dataTask(with: request!) { (data: Data?, response: URLResponse?, error: Error?) in
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    return
            }
            
            if data != nil {
                // Remove indicator
                if self.indicator != nil {
                    self.removeIndicator(indicator: self.indicator!)
                }
                
                // Convert data into Friend(s)
                self.friends = try? JSONDecoder().decode([Friend].self, from: data!)
                self.filteredFriends = self.friends
                
                // Reload table view data from the main thread
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }

        }
        task.resume()
    }
    
    // Remove the friend HTTP DELETE METHOD
    func deleteHttpMethod(friend: Friend) {
        // Set Method type
        self.request?.httpMethod = "DELETE"

        // Set id in the request
        self.request?.url = URL(string: "\(Constants.HOST_FRIEND)\(friend.id!)")
        
        let task = URLSession.shared.dataTask(with: request!) { (data: Data?, response: URLResponse?, error: Error?) in
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return
            }
            
            self.displayAlert(title: "Friend Removed", message: "The friend is removed from your list!")
            
            // Remove the friend from the array
            let index = self.friends!.index(where: { ($0.id == friend.id) })
            self.friends?.remove(at: index!)
            
            // Reload table view data from the main thread
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        task.resume()
    }
    
    
    // Number of rows in the section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (self.filteredFriends?.count) ?? 0
    }
    
    // Content in the cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! FriendCell
        // Set content in the cell
        if (self.filteredFriends?.count)! > 0 {
            self.friend = self.filteredFriends![indexPath.row]
            var fullName = ""
            
            if let firstName = friend?.f_name {
                fullName = firstName
            }
            if let lastName = friend?.l_name {
                fullName += " \(lastName)"
            }
            cell.fullName?.text = fullName
            if (friend?.status == "Active") {
                cell.action?.setTitle("Unfriend", for: .normal)
            } else {
                cell.action?.setTitle("Add Friend", for: .normal)
            }
            
            // Call the add/remove method
            cell.action?.addTarget(self, action: #selector(addRemoveFriend), for: UIControlEvents.touchUpInside)
            // pass the indexPath in the button tag
            cell.action?.tag = indexPath.row
        }
        return cell
    }
    
    // Begin search when text changed in the search bar
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            self.filteredFriends = self.friends
            return
        } else {
            // If the search text has space, then seperate and store in array
            let searchTerms = searchText.components(separatedBy: " ")
            
            // Loop through search terms
            for term in searchTerms {
                self.filteredFriends = self.friends?.filter({
                    ($0.f_name?.contains(term))!
                        ||
                        ($0.l_name?.contains(term))!
                        ||
                        ($0.email?.contains(term.lowercased()))!
                })
            }
        }
        self.tableView.reloadData()
    }
    
    // Clear search result when cancelled
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        self.filteredFriends = self.friends
        self.tableView.reloadData()
    }
    
    // Add or  remove friend
    @objc func addRemoveFriend(sender: UIButton) {
        
        guard let friend = self.filteredFriends?[sender.tag] else {
            self.displayAlert(title: "Unable to Remove", message: "Unable to remove the friend. Please try again!")
            return
        }
        self.deleteHttpMethod(friend: friend)
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

}
