//
//  PrivateChatter.swift
//  PokeTrade
//
//  Created by Austin Golding on 9/14/16.
//

import Foundation
import SwiftyJSON
import Firebase

class PrivateChatter: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var chatterTable: UITableView!
    @IBOutlet weak var textField: UITextField!
    
    var ref: FIRDatabaseReference!
    var messages: [FIRDataSnapshot]! = []
    var msglength: NSNumber = 10
    var oldHash = ""
    var hexConvert = ColorPickerViewController()
    var _refHandle: FIRDatabaseHandle!

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(PrivateChatter.keyboardWillShow(_:)), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PrivateChatter.keyboardWillHide(_:)), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
        chatterTable.delegate = self
        chatterTable.dataSource = self
        textField.delegate = self
        self.hideKeyboardWhenTappedAround()
        configureDatabase()
        self.chatterTable.register(UITableViewCell.self, forCellReuseIdentifier: "tableViewCell")
        self.chatterTable.estimatedRowHeight = 20
        self.chatterTable.rowHeight = UITableViewAutomaticDimension
        messages.removeAll()        
    }
    
    deinit {
        messages.removeAll()
    }
    
    let serverDateFormatter: DateFormatter = {
        let result = DateFormatter()
        result.dateFormat = "yyyy-MM-dd HH:mm.SSSSSS"
        result.timeZone = TimeZone(secondsFromGMT: 0)
        return result
    }()
    
    func configureDatabase() {
        ref = FIRDatabase.database().reference()
        _refHandle = self.ref.child("Users").child(AppState.sharedInstance.email!).child("Chats").child(AppState.sharedInstance.privateUSer!).observe(.childAdded, with: { (snapshot) -> Void in
            if (snapshot.key != "Date") {
            self.messages.append(snapshot)
            self.chatterTable.insertRows(at: [IndexPath(row: self.messages.count-1, section: 0)], with: .automatic)
            }
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print(messages.count)
        tableViewScrollToBottom(false)
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell! = self.chatterTable .dequeueReusableCell(withIdentifier: "tableViewCell", for: indexPath)
        let messageSnapshot: FIRDataSnapshot! = messages[(indexPath as IndexPath).row]
        
        let message = messageSnapshot.value as! Dictionary<String, String>
        let messager: JSON = JSON(message)

        let Name = messager[Constants.MessageFields.name].stringValue
        let tempColor = messager[Constants.MessageFields.nameColor].stringValue
        let color: UIColor! = hexConvert.convertHexToUIColor(hexColor: tempColor)

        
        let text = messager[Constants.MessageFields.text].stringValue
        
        
        
        var myMutableString = NSMutableAttributedString()
        if #available(iOS 8.2, *) {
            cell!.textLabel?.font = UIFont.systemFont(ofSize: 18.0, weight: UIFontWeightRegular)
        } else {
        }
        let myString:String = Name + ": " + text
        myMutableString = NSMutableAttributedString(string: myString as String)
        myMutableString.addAttribute(NSForegroundColorAttributeName, value: color, range: NSRange(location:0,length:((Name.characters.count) + 1)))
        
        cell!.textLabel?.attributedText = myMutableString
        cell!.textLabel?.numberOfLines = 0
        cell!.textLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
        
        return cell!
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        
        let newLength = text.utf16.count + string.utf16.count - range.length
        return newLength <= (self.msglength.intValue + 200)
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
        print(textField.text!)
        let data = [Constants.MessageFields.text: textField.text! as String]
        
        sendMessage(data)

        return true
    }
    
    
    
    func tableViewScrollToBottom(_ animated: Bool) {
        
        let delay = 0.5 * Double(NSEC_PER_SEC)
        let time = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
        
        DispatchQueue.main.asyncAfter(deadline: time, execute: {
            
            let numberOfSections = self.chatterTable.numberOfSections
            let numberOfRows = self.chatterTable.numberOfRows(inSection: numberOfSections-1)
            
            if numberOfRows > 0 {
                let indexPath = IndexPath(row: numberOfRows-1, section: (numberOfSections-1))
                self.chatterTable.scrollToRow(at: indexPath, at: UITableViewScrollPosition.bottom, animated: animated)
            }
            
        })
    }

    
    func sendMessage(_ data: [String: String]) {
        var mdata = data
        mdata[Constants.MessageFields.name] = AppState.sharedInstance.email
        mdata[Constants.MessageFields.nameColor] = AppState.sharedInstance.nameColor
        let s = Date()
        let d = serverDateFormatter.string(from: s)
        
        mdata[Constants.MessageFields.date] = d as String!

        print("email" + AppState.sharedInstance.email!)
        print("name" + AppState.sharedInstance.privateUSer!)
        print("data" + d)
        let recent = [Constants.MessageFields.date: d as String!]
        self.ref.child("Users").child(AppState.sharedInstance.email!).child("Chats").child(AppState.sharedInstance.privateUSer!).childByAutoId().setValue(mdata)
        self.ref.child("Users").child(AppState.sharedInstance.privateUSer!).child("Chats").child(AppState.sharedInstance.email!).childByAutoId().setValue(mdata)
        self.ref.child("Users").child(AppState.sharedInstance.email!).child("Chats").child(AppState.sharedInstance.privateUSer!).child("Date").setValue(recent)
        self.ref.child("Users").child(AppState.sharedInstance.privateUSer!).child("Chats").child(AppState.sharedInstance.email!).child("Date").setValue(recent)
    }
}
