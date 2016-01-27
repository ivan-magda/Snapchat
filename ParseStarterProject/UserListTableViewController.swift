//
//  UserListTableViewController.swift
//  ParseStarterProject-Swift
//
//  Created by Иван Магда on 27.01.16.
//  Copyright © 2016 Parse. All rights reserved.
//

import UIKit
import Parse

class UserListTableViewController: UITableViewController {
    // MARK: - Properties
    
    private var usernames = [String]()
    
    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadObjects()
    }
    
    private func loadObjects() {
        let query = PFUser.query()!
        query.whereKey("username", notEqualTo: PFUser.currentUser()!.username!)
        
        query.findObjectsInBackgroundWithBlock() { (objects, error) in
            self.usernames.removeAll(keepCapacity: true)
            
            if let error = error {
                print("Error: \(error.localizedDescription)")
            } else if let users = objects as? [PFUser] {
                for user in users {
                    self.usernames.append(user.username!)
                }
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.tableView.reloadData()
                }
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usernames.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell")!
        cell.textLabel?.text = usernames[indexPath.row]

        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    }
    
    // MARK: - Actions
    
    @IBAction func logOut(sender: AnyObject) {
        PFUser.logOutInBackgroundWithBlock() { error in
            if let error = error {
                print("Log out error: \(error.localizedDescription)")
            } else {
                self.dismissViewControllerAnimated(true, completion: nil)
            }
        }
    }
}
