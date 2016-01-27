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
    //--------------------------------------
    // MARK: - Properties
    //--------------------------------------
    
    private var usernames = [String]()
    private var recipient: String?
    
    private var activityIndicator: UIActivityIndicatorView!
    
    private var isAlertPresented = false
    
    private let checkForMessagesFireTime: NSTimeInterval = 8
    private let presentedImageDeletionFireTime: NSTimeInterval = 8
    
    //--------------------------------------
    // MARK: - View Life Cycle
    //--------------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadObjects()
        
        _ = NSTimer.scheduledTimerWithTimeInterval(checkForMessagesFireTime, target: self, selector: Selector("checkForMessage"), userInfo: nil, repeats: true)
        
        self.activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .White)
        self.activityIndicator.hidesWhenStopped = true
        self.activityIndicator.center = self.view.center
    }
    
    //--------------------------------------
    // MARK: - Private
    //--------------------------------------
    
    private func loadObjects() {
        let query = PFUser.query()!
        query.whereKey("username", notEqualTo: PFUser.currentUser()!.username!)
        
        query.findObjectsInBackgroundWithBlock() { (objects, error) in
            self.usernames.removeAll(keepCapacity: true)
            
            if let error = error {
                print("Error: \(error.localizedDescription)")
                
                self.displayAlertWithTitle("Error", message: error.localizedDescription)
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
    
    private func displayAlertWithTitle(title: String, message: String) {
        if isAlertPresented {
            return
        }
        
        self.isAlertPresented = true
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .Cancel) { action in
            self.isAlertPresented = false
            })
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func checkForMessage() {
        guard PFUser.currentUser()?.username != nil else {
            return
        }
        
        let query = PFQuery(className: Image.parseClassName())
        query.whereKey(Image.FieldKey.recipientUsername.rawValue, equalTo: PFUser.currentUser()!.username!)
        
        query.findObjectsInBackgroundWithBlock() { (images, error) in
            if let error = error {
                self.displayAlertWithTitle("Error", message: error.localizedDescription)
            } else if let images = images as? [Image] where images.count > 0 {
                let anImage = images[0]
                let photoFile = anImage.photo
                
                photoFile.getDataInBackgroundWithBlock() { (data, error) in
                    if let error = error {
                        self.displayAlertWithTitle("Error", message: error.localizedDescription)
                    } else if let data = data where data.length > 0 && self.isAlertPresented == false {
                        if let imageToShow = UIImage(data: data) {
                            self.isAlertPresented = true
                            
                            let alert = UIAlertController(title: "You have a message", message: "Message from \(anImage.senderUsername)", preferredStyle: .Alert)
                            alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel) { action in
                                self.isAlertPresented = false
                                })
                            alert.addAction(UIAlertAction(title: "Show", style: .Default) { action in
                                // Present an image.
                                let imageView = UIImageView(frame: CGRectMake(0.0, 0.0, CGRectGetWidth(self.navigationController!.view.bounds), CGRectGetHeight(self.navigationController!.view.bounds)))
                                imageView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.45)
                                imageView.image = imageToShow
                                imageView.contentMode = UIViewContentMode.ScaleAspectFit
                                
                                self.navigationController!.view.addSubview(imageView)
                                
                                /// Removes image view from it's superview.
                                func removeImageView() {
                                    let outFrame = CGRectMake(CGRectGetWidth(self.view.bounds), imageView.frame.origin.y, CGRectGetWidth(imageView.bounds), CGRectGetHeight(imageView.bounds))
                                    
                                    UIView.animateWithDuration(0.75, animations: {
                                        imageView.frame = outFrame
                                        imageView.alpha = 0.0
                                        }, completion: { finished in
                                            if finished {
                                                imageView.removeFromSuperview()
                                                self.isAlertPresented = false
                                            }
                                    })
                                }
                                
                                // Remove an image.
                                let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(self.presentedImageDeletionFireTime * Double(NSEC_PER_SEC)))
                                dispatch_after(delayTime, dispatch_get_main_queue()) {
                                    anImage.deleteInBackgroundWithBlock() { (success, error) in
                                        if success {
                                            removeImageView()
                                        } else if let error = error {
                                            removeImageView()
                                            
                                            self.displayAlertWithTitle("Error", message: error.localizedDescription)
                                        } else {
                                            removeImageView()
                                        }
                                    }
                                }
                                })
                            
                            self.presentViewController(alert, animated: true, completion: nil)
                        } else {
                            self.isAlertPresented = false
                        }
                    }
                }
            }
        }
    }
    
    //--------------------------------------
    // MARK: - Table view data source
    //--------------------------------------
    
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
    
    //--------------------------------------
    // MARK: - Table view delegate
    //--------------------------------------
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        self.recipient = usernames[indexPath.row]
        
        // Present an action sheet.
        let actionSheet = UIAlertController(title: "From which to choose", message: nil, preferredStyle: .ActionSheet)
        actionSheet.addAction(UIAlertAction(title: "Library", style: .Default) { handler in
            self.photoFromLibrary()
            })
        actionSheet.addAction(UIAlertAction(title: "Shoot photo", style: .Default) { handler in
            self.shootPhoto()
            })
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        self.presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    //--------------------------------------
    // MARK: - Navigation
    //--------------------------------------
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    }
    
    //--------------------------------------
    // MARK: - Actions
    //--------------------------------------
    
    @IBAction func logOut(sender: AnyObject) {
        PFUser.logOutInBackgroundWithBlock() { error in
            if let error = error {
                print("Log out error: \(error.localizedDescription)")
                
                self.displayAlertWithTitle("Log out error", message: error.localizedDescription)
            } else {
                self.dismissViewControllerAnimated(true, completion: nil)
            }
        }
    }
}

//--------------------------------------
// MARK: - Picking Image Extensions -
//--------------------------------------

extension UserListTableViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    //--------------------------------------
    // MARK: Private Helper Methods
    //--------------------------------------
    
    private func noCamera() {
        let alert = UIAlertController(title: "No Camera", message: "Sorry, this device has no camera", preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "OK", style:.Default, handler: nil)
        alert.addAction(okAction)
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    /// Get a photo from the library.
    func photoFromLibrary() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = false
        imagePickerController.sourceType = .PhotoLibrary
        imagePickerController.modalPresentationStyle = .FullScreen
        
        self.presentViewController(imagePickerController, animated: true, completion: nil)
    }
    
    /// Take a picture, check if we have a camera first.
    func shootPhoto() {
        if UIImagePickerController.availableCaptureModesForCameraDevice(.Rear) != nil {
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.allowsEditing = false
            imagePickerController.sourceType = .Camera
            imagePickerController.cameraCaptureMode = .Photo
            imagePickerController.modalPresentationStyle = .FullScreen
            
            self.presentViewController(imagePickerController, animated: true, completion: nil)
        } else {
            noCamera()
        }
    }
    
    //---------------------------------------
    // MARK: UIImagePickerControllerDelegate
    //---------------------------------------
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage
        
        if let pickedImage = pickedImage {
            if let data = UIImageJPEGRepresentation(pickedImage, 0.5) {
                let imageToSend = Image()
                imageToSend.photo = PFFile(name: "photo.jpg", data: data)!
                imageToSend.senderUsername = PFUser.currentUser()!.username!
                imageToSend.recipientUsername = self.recipient!
                
                let publicACL = PFACL()
                publicACL.publicReadAccess = true
                publicACL.publicWriteAccess = true
                
                imageToSend.ACL = publicACL
                
                self.activityIndicator.startAnimating()
                self.view.addSubview(self.activityIndicator!)
                
                imageToSend.saveInBackgroundWithBlock() { (success, error) in
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.removeFromSuperview()
                    
                    if success {
                        self.displayAlertWithTitle("Success", message: "Your image has successfully send")
                    } else if let error = error {
                        self.displayAlertWithTitle("Error", message: error.localizedDescription)
                    }
                }
            }
        }
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
