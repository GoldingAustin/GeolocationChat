import Photos
import UIKit
import Firebase
import SwiftyJSON


@objc(PokeTradeViewController)
class PokeTradeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource,
UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var Name: UILabel!
    @IBOutlet weak var Message: UILabel!
    var locationManager = CLLocationManager()
    var ref: FIRDatabaseReference!
    var messages: [FIRDataSnapshot]! = []
    var msglength: NSNumber = 10
    var oldHash = ""
    var hexConvert = ColorPickerViewController()
    var _refHandle: FIRDatabaseHandle!
    var remoteConfig: FIRRemoteConfig!
    var uName = ""
    var names: [String]! = []
    var text = ""
    var oldName = ""
    var oldText = ""
    @IBOutlet weak var clientTable: UITableView!
    var kbHeight: CGFloat!
    var json: JSON = JSON.null
    
    
    
    override func viewDidLoad() {

        super.viewDidLoad()
        clientTable.delegate = self
        clientTable.dataSource = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(PokeTradeViewController.keyboardWillShow(_:)), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PokeTradeViewController.keyboardWillHide(_:)), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
        self.hideKeyboardWhenTappedAround()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 500
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        self.clientTable.register(UITableViewCell.self, forCellReuseIdentifier: "tableViewCell")
        self.clientTable.estimatedRowHeight = 20
        self.clientTable.rowHeight = UITableViewAutomaticDimension
               messages.removeAll()

        configureRemoteConfig()
        fetchConfig()
    }
    
    
    func geoHash(lat: Double, long: Double) -> String {
        let geomap = Array("0123456789bcdefghjkmnpqrstuvwxyz".characters)
        var latMnMx = (-90.0, 90.0)
        var lonMnMx = (-180.0, 180.0)
        var finalHash = String()
        var char = 0;
        var bit: UInt8 = 0b10000

        func encode(latitude: Double, longitude: Double) -> String {
            var picker = false
            repeat {
                switch(picker) {
                case false:
                    let mid = (lonMnMx.0 + lonMnMx.1) / 2
                    if (longitude >= mid) {
                        lonMnMx.0 = mid;
                        char |= Int(bit)
                    } else {
                        lonMnMx.1 = mid;
                    }
                case true:
                    let mid = (latMnMx.0 + latMnMx.1) / 2
                    if (latitude >= mid) {
                        latMnMx.0 = mid;
                        char |= Int(bit)
                    } else {
                        latMnMx.1 = mid;
                    }
                }
                
                picker = !picker;
                bit >>= 1
                
                if(bit == 0b00000) {
                    finalHash += String(geomap[char])
                    bit = 0b10000
                    char = 0
                }
                
            } while finalHash.characters.count < 5

            return finalHash
        }


        let geohash = encode(latitude: lat, longitude: long)
        print(geohash.hash)
        return geohash
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        let newLocation = locations.last
        var interval = TimeInterval()
        interval = (newLocation?.timestamp.timeIntervalSinceNow)!
        if (interval > 5) {
            return
        }
        Constants.users.lng = newLocation!.coordinate.longitude
        Constants.users.lat = newLocation!.coordinate.latitude
        let hash = geoHash(lat: Constants.users.lng, long: Constants.users.lat)
        AppState.sharedInstance.locHash = hash
        if (AppState.sharedInstance.locSet == false) {
            oldHash = hash
        }
        if (oldHash != hash || AppState.sharedInstance.locSet == false) {
            self.clientTable.reloadData()
            messages.removeAll()
            self.clientTable.register(UITableViewCell.self, forCellReuseIdentifier: "tableViewCell")
            configureDatabase()
            print("Changed")
            oldHash = hash
        }
        AppState.sharedInstance.locSet = true
        print(hash)
    }
    
    
    deinit {
        messages.removeAll()
        names.removeAll()
    }
    
    func configureDatabase() {
        ref = FIRDatabase.database().reference()
        _refHandle = self.ref.child(AppState.sharedInstance.locHash!).child("messages").observe(.childAdded, with: { (snapshot) -> Void in
            self.messages.append(snapshot)
            AppState.sharedInstance.messages = self.messages
            self.clientTable.insertRows(at: [IndexPath(row: self.messages.count-1, section: 0)], with: .automatic)
        })
    }
    

    
    func configureRemoteConfig() {
        remoteConfig = FIRRemoteConfig.remoteConfig()
        let remoteConfigSettings = FIRRemoteConfigSettings(developerModeEnabled: true)
        remoteConfig.configSettings = remoteConfigSettings!
    }
    
    func fetchConfig() {
        var expirationDuration: Double = 3600
        if (self.remoteConfig.configSettings.isDeveloperModeEnabled) {
            expirationDuration = 0
        }
        remoteConfig.fetch(withExpirationDuration: expirationDuration) { (status, error) in
            if (status == .success) {
                print("Config fetched!")
                self.remoteConfig.activateFetched()
                let friendlyMsgLength = self.remoteConfig["friendly_msg_length"]
                if (friendlyMsgLength.source != .static) {
                    self.msglength = friendlyMsgLength.numberValue!
                    print("Friendly msg length config: \(self.msglength)")
                }
            } else {
                print("Config not fetched")
                print("Error \(error)")
            }
        }
    }
    
    
    
    
    @IBAction func didPressFreshConfig(_ sender: AnyObject) {
        fetchConfig()
    }
    
    @IBAction func didSendMessage(_ sender: UIButton) {
        textFieldShouldReturn(textField)
    }
    
    
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        
        let newLength = text.utf16.count + string.utf16.count - range.length
        return newLength <= (self.msglength.intValue + 200)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("select")
        let indexPath = clientTable.indexPathForSelectedRow
        
        let currentCell = clientTable.cellForRow(at: indexPath!)! as UITableViewCell
        AppState.sharedInstance.privateUSer = names[(indexPath?.row)!]
        print(AppState.sharedInstance.privateUSer!)
        self.ref.child("Users").child(AppState.sharedInstance.email!).child("Chats").child(AppState.sharedInstance.privateUSer!)
        performSegue(withIdentifier: "privateChatFromChat", sender: nil)
        print(currentCell.textLabel!.text!)
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print(messages.count)
        tableViewScrollToBottom(false)
        return messages.count
    }
    
 func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

 let cell: UITableViewCell! = self.clientTable .dequeueReusableCell(withIdentifier: "tableViewCell", for: indexPath)
        let messageSnapshot: FIRDataSnapshot! = messages[(indexPath as IndexPath).row]
    
        let message = messageSnapshot.value as! Dictionary<String, String>
        let messager: JSON = JSON(message)

        oldName = uName
        oldText = text
        uName = messager[Constants.MessageFields.name].stringValue
        names.append(uName)
        let tempColor = messager[Constants.MessageFields.nameColor].stringValue
   
        let color: UIColor! = hexConvert.convertHexToUIColor(hexColor: tempColor)

            text = messager[Constants.MessageFields.text].stringValue
            

           
            var myMutableString = NSMutableAttributedString()
            if #available(iOS 8.2, *) {
                cell!.textLabel?.font = UIFont.systemFont(ofSize: 18.0, weight: UIFontWeightRegular)
            } else {
            }
                let myString:String = uName + ": " + text
                myMutableString = NSMutableAttributedString(string: myString as String)
                myMutableString.addAttribute(NSForegroundColorAttributeName, value: color, range: NSRange(location:0,length:((uName.characters.count) + 1)))
        
            cell!.textLabel?.attributedText = myMutableString
            cell!.textLabel?.numberOfLines = 0
            cell!.textLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
            
           return cell!
    }
    
    func keyboardWillHide(_ sender: Notification) {
        let userInfo: [AnyHashable: Any] = sender.userInfo!
        let keyboardSize: CGSize = (userInfo[UIKeyboardFrameBeginUserInfoKey]! as AnyObject).cgRectValue.size
        self.view.frame.origin.y += keyboardSize.height
    }
    
    func keyboardWillShow(_ sender: Notification) {
        let userInfo: [AnyHashable: Any] = sender.userInfo!
        let keyboardSize: CGSize = (userInfo[UIKeyboardFrameBeginUserInfoKey]! as AnyObject).cgRectValue.size
        let offset: CGSize = (userInfo[UIKeyboardFrameEndUserInfoKey]! as AnyObject).cgRectValue.size
        
        if keyboardSize.height == offset.height {
            UIView.animate(withDuration: 0.1, animations: { () -> Void in
                self.view.frame.origin.y -= keyboardSize.height
            })
        } else {
            UIView.animate(withDuration: 0.1, animations: { () -> Void in
                self.view.frame.origin.y += keyboardSize.height - offset.height
            })
        }
        tableViewScrollToBottom(false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        let data = [Constants.MessageFields.text: textField.text! as String]
        
        sendMessage(data)
        textField.text = ""
        return true
    }
    

    
    func tableViewScrollToBottom(_ animated: Bool) {
        
        let delay = 0.5 * Double(NSEC_PER_SEC)
        let time = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
        
        DispatchQueue.main.asyncAfter(deadline: time, execute: {
            
            let numberOfSections = self.clientTable.numberOfSections
            let numberOfRows = self.clientTable.numberOfRows(inSection: numberOfSections-1)
            
            if numberOfRows > 0 {
                let indexPath = IndexPath(row: numberOfRows-1, section: (numberOfSections-1))
                self.clientTable.scrollToRow(at: indexPath, at: UITableViewScrollPosition.bottom, animated: animated)
            }
            
        })
    }

    
    func sendMessage(_ data: [String: String]) {
        var mdata = data
        mdata[Constants.MessageFields.name] = AppState.sharedInstance.displayName
        mdata[Constants.MessageFields.nameColor] = AppState.sharedInstance.nameColor
        self.ref.child(AppState.sharedInstance.locHash!).child("messages").childByAutoId().setValue(mdata)
    }
    
    @IBAction func userTappedBackground(_ sender: AnyObject) {
        view.endEditing(true)
    }
    
    
    @IBAction func signOut(_ sender: UIButton) {
        let firebaseAuth = FIRAuth.auth()
        do {
            try firebaseAuth?.signOut()
            AppState.sharedInstance.signedIn = false
            dismiss(animated: true, completion: nil)
        } catch let signOutError as NSError {
            print ("Error signing out: \(signOutError)")
        }
    }
    
    func showAlert(_ title:String, message:String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title,
                                          message: message, preferredStyle: .alert)
            let dismissAction = UIAlertAction(title: "Dismiss", style: .destructive, handler: nil)
            alert.addAction(dismissAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
}
