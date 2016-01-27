/**
* Copyright (c) 2015-present, Parse, LLC.
* All rights reserved.
*
* This source code is licensed under the BSD-style license found in the
* LICENSE file in the root directory of this source tree. An additional grant
* of patent rights can be found in the PATENTS file in the same directory.
*/

import UIKit
import Parse

class AuthorizationViewController: UIViewController {
    // MARK: - Properties
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    
    private let showUserTableSegueIdentifier = "ShowUserTable"
    private let defaultPassword = "password"

    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.errorLabel.hidden = true
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if let user = PFUser.currentUser() where user.username != nil {
            self.performSegueWithIdentifier(showUserTableSegueIdentifier, sender: self)
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        
        self.view.endEditing(true)
    }
    
    // MARK: - Private
    
    private func setErrorMessageToTheLabelWithAnimation(errorMessage error: String) {
        self.errorLabel.alpha = 0.0
        self.errorLabel.hidden = false
        self.errorLabel.text = error
        
        UIView.animateWithDuration(0.45, animations: {
            self.errorLabel.alpha = 1.0
            }, completion: nil)
    }

    // MARK: - Actions
    
    @IBAction func signUp(sender: AnyObject) {
        self.usernameTextField.resignFirstResponder()
        
        if let username = usernameTextField.text where username.characters.count > 0 {
            PFUser.logInWithUsernameInBackground(username, password: defaultPassword) { (user, error) in
                if error != nil {
                    let user = PFUser()
                    user.username = username
                    user.password = self.defaultPassword
                    
                    user.signUpInBackgroundWithBlock() { (success, error) in
                        if success {
                            print("Signed Up")
                            self.errorLabel.hidden = true
                            
                            self.performSegueWithIdentifier(self.showUserTableSegueIdentifier, sender: self)
                        } else {
                            self.setErrorMessageToTheLabelWithAnimation(errorMessage: error!.localizedDescription)
                        }
                    }
                } else {
                    print("Logged In")
                    self.errorLabel.hidden = true
                    
                    self.performSegueWithIdentifier(self.showUserTableSegueIdentifier, sender: self)
                }
            }
        } else {
            self.view.endEditing(true)
            
            setErrorMessageToTheLabelWithAnimation(errorMessage: "Enter your username")
        }
    }
}
