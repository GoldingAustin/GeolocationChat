import UIKit
import Firebase

@objc(SignInViewController)
class SignInViewController: UIViewController, GIDSignInDelegate, GIDSignInUIDelegate {
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var signInButton: GIDSignInButton!
    let MyKeychainWrapper = KeychainWrapper()
    var ref: FIRDatabaseReference!
    var setName = SetUserNameAndColor()
    var save = UserDefaults.standard
    
    
    
    override func viewDidAppear(_ animated: Bool) {
    }
    
    @IBAction func didTapSignIn(_ sender: AnyObject) {
        let email = emailField.text!
        print(email)
        let password = passwordField.text
        self.save.setValue(email, forKey: "email")
        self.MyKeychainWrapper.mySetObject(password, forKey: kSecValueData)
        self.MyKeychainWrapper.writeToKeychain()
        self.save.set(true, forKey: "keyForEmail")
        self.save.set(true, forKey: "keyForPass")
        self.save.synchronize()
        FIRAuth.auth()?.signIn(withEmail: email, password: password!) { (user, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            self.configureDatabase(user!)
        }
    }
    func configureDatabase(_ user: FIRUser) -> Bool {
        ref = FIRDatabase.database().reference()
        let databaseRef = FIRDatabase.database().reference()
        AppState.sharedInstance.email = user.email!.components(separatedBy: "@").first as String!
        databaseRef.child("Users").observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
            print("here")
            if snapshot.hasChild(AppState.sharedInstance.email!){
                databaseRef.child("Users").child(AppState.sharedInstance.email!).observeSingleEvent(of: .value, with: { (snapshot) in
                    for result in (snapshot.children.allObjects as? [FIRDataSnapshot])! {
                        AppState.sharedInstance.displayName = result.key
                        print(AppState.sharedInstance.displayName)
                    }
                })
                self.save.set(true, forKey: "notNewUser")
                print("true rooms exist")
                self.signedIn(FIRAuth.auth()?.currentUser)
                
            }
            else{

                self.performSegue(withIdentifier: Constants.Segues.NewUser, sender: nil)
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NotificationKeys.SignedIn), object: nil, userInfo: nil)
                self.setDisplayName(user)
                print("false room doesn't exist")
            }
            
        })
        
        return true
    }
    
    
    @IBAction func signInButton(_ sender: AnyObject) {
        var configureError: NSError?
        GGLContext.sharedInstance().configureWithError(&configureError)
        
        if configureError != nil {

        }  else {
            GIDSignIn.sharedInstance().shouldFetchBasicProfile = true
            GIDSignIn.sharedInstance().clientID = FIRApp.defaultApp()?.options.clientID
            GIDSignIn.sharedInstance().delegate = self
            GIDSignIn.sharedInstance().uiDelegate = self
            
            
            GIDSignIn.sharedInstance().signIn()
        }
    }
    
    func sign(_ signIn: GIDSignIn!,
                present viewController: UIViewController!) {
        self.present(viewController, animated: true, completion: nil)
        
        print("Sign in presented")
        
    }
    
    func sign(_ signIn: GIDSignIn!,
                dismiss viewController: UIViewController!) {
        self.dismiss(animated: true, completion: nil)
        
        print("Sign in dismissed")
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!,
                withError error: Error!) {
        if (error == nil) {
            let userId = user.userID
            let idToken = user.authentication.idToken
            self.save.setValue(idToken, forKey: "ID")

        } else {
            print("\(error.localizedDescription)")
        }
        let authentication = user.authentication
        let credential = FIRGoogleAuthProvider.credential(withIDToken: (authentication?.idToken)!,
                                                                     accessToken: (authentication?.accessToken)!)
        self.MyKeychainWrapper.mySetObject(((authentication?.accessToken)!), forKey: kSecValueData)
        
        self.MyKeychainWrapper.writeToKeychain()
        
        FIRAuth.auth()?.signIn(with: credential){ (user, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
        
            self.save.set(true, forKey: "keyForCredentials")
            self.save.set(true, forKey: "keyForUser")
            self.save.synchronize()

            self.configureDatabase(user!)
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
    }
    
    override func viewDidLoad() {
        print("didLoad")
        let hasCredKey = save.bool(forKey: "keyForCredentials")
        print(hasCredKey)
        if hasCredKey == true {
            let hasUserKey = save.bool(forKey: "keyForUser")
            if hasUserKey == true {
              
                let id = save.value(forKey: "ID") as! String
                let cred = MyKeychainWrapper.myObject(forKey: "v_Data")
                print("retrieved data")
                let credential = FIRGoogleAuthProvider.credential(withIDToken: id,
                                                                             accessToken: cred as! String)
                FIRAuth.auth()?.signIn(with: credential){ (user, error) in
                    if let error = error {
                        print(error.localizedDescription)
                        return
                    }
                    print("authorized")
                    self.configureDatabase(user!)
                }
            }
            let hasEmailKey = save.bool(forKey: "keyForEmail")
            let hasPassKey = save.bool(forKey: "keyForPass")
            if hasEmailKey == true {
                if hasPassKey == true {
                    let email = save.value(forKey: "keyForEmail") as! String
                    let password = save.value(forKey: "keyForPass") as! String
                    FIRAuth.auth()?.signIn(withEmail: email, password: password) { (user, error) in
                        if let error = error {
                            print(error.localizedDescription)
                            return
                        }
                        self.configureDatabase(user!)
                    }
                }
            }
        }

        super.viewDidLoad()

        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().signInSilently()
        
        toggleAuthUI()
    }
    

    @IBAction func didTapSignOut(_ sender: AnyObject) {
        GIDSignIn.sharedInstance().signOut()
        toggleAuthUI()
    }

    @IBAction func didTapDisconnect(_ sender: AnyObject) {
        GIDSignIn.sharedInstance().disconnect()

    }

    func toggleAuthUI() {
    }
    
    @IBAction func didTapSignUp(_ sender: AnyObject) {
        let email = emailField.text
        
        let password = passwordField.text
        FIRAuth.auth()?.createUser(withEmail: email!, password: password!) { (user, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            self.setDisplayName(user!)
        }
    }
    
    func setDisplayName(_ user: FIRUser) {
        let changeRequest = user.profileChangeRequest()
        changeRequest.displayName = AppState.sharedInstance.displayName
        changeRequest.commitChanges(){ (error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            self.signedIn(FIRAuth.auth()?.currentUser)
        }
    }
    
    @IBAction func didRequestPasswordReset(_ sender: AnyObject) {
        let prompt = UIAlertController.init(title: nil, message: "Email:", preferredStyle: UIAlertControllerStyle.alert)
        let okAction = UIAlertAction.init(title: "OK", style: UIAlertActionStyle.default) { (action) in
            let userInput = prompt.textFields![0].text
            if (userInput!.isEmpty) {
                return
            }
            FIRAuth.auth()?.sendPasswordReset(withEmail: userInput!) { (error) in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
            }
        }
        prompt.addTextField(configurationHandler: nil)
        prompt.addAction(okAction)
        present(prompt, animated: true, completion: nil);
    }
    
    func signedIn(_ user: FIRUser?) {
        AppState.sharedInstance.photoUrl = user?.photoURL
        AppState.sharedInstance.signedIn = true
        AppState.sharedInstance.email = user!.email!.components(separatedBy: "@").first as String!
        let new = save.bool(forKey: "notNewUser")
        if (new == false) {
            performSegue(withIdentifier: Constants.Segues.NewUser, sender: nil)
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NotificationKeys.SignedIn), object: nil, userInfo: nil)
        }
        else {
            performSegue(withIdentifier: Constants.Segues.SideMenu, sender: nil)
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NotificationKeys.SignedIn), object: nil, userInfo: nil)
        }
    }
}

