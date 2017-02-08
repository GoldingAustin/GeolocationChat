//
//  PrivateChatView.swift
//  PokeTrade
//
//  Created by Austin Golding on 9/14/16.
//

import UIKit
import SwiftyJSON

@objc(PrivateChatView)
class PrivateChatView: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var privateTable: UITableView!
    var chats: [FIRDataSnapshot]! = []
    var ref: FIRDatabaseReference!
    var names: [String]! = []
    var hexConvert = ColorPickerViewController()
    var _refHandle: FIRDatabaseHandle!
    var i: Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.privateTable.delegate = self
        self.privateTable.register(UITableViewCell.self, forCellReuseIdentifier: "tableViewCell")
        configureDatabase()
    }
    
    let serverDateFormatter: DateFormatter = {
        let result = DateFormatter()
        result.dateFormat = "yyyy-MM-dd HH:mm.SSSSSS"
        result.timeZone = TimeZone(secondsFromGMT: 0)
        return result
    }()
    
    let localDateFormatter: DateFormatter = {
        let result = DateFormatter()
        result.dateStyle = .medium
        result.timeStyle = .medium
        return result
    }()

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print(chats.count)
        return chats.count
    }
    
    deinit {
        chats.removeAll()
        names.removeAll()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let indexPath = privateTable.indexPathForSelectedRow
        
        let currentCell = privateTable.cellForRow(at: indexPath!)! as UITableViewCell
        AppState.sharedInstance.privateUSer = names[(indexPath?.row)!]
        performSegue(withIdentifier: "privateChatFromList", sender: nil)
        print(currentCell.textLabel!.text!)
    }
    
    func configureDatabase() {
        ref = FIRDatabase.database().reference()
        _refHandle = self.ref.child("Users").child(AppState.sharedInstance.email!).child("Chats").observe(.childAdded, with: { (snapshot) -> Void in
            self.chats.append(snapshot)
            self.privateTable.insertRows(at: [IndexPath(row: self.chats.count-1, section: 0)], with: .automatic)
        })
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell: UITableViewCell! = self.privateTable .dequeueReusableCell(withIdentifier: "tableViewCell", for: indexPath)
    let messageSnapshot: FIRDataSnapshot! = chats[(indexPath as IndexPath).row]
    
    let message = messageSnapshot.childSnapshot(forPath: "Date").value as! Dictionary<String, String>
    let messager: JSON = JSON(message)

        let Name = messageSnapshot.key as String!
        print(Name!)
        names.append(Name!)
    
    var date = messager[Constants.MessageFields.date].stringValue
    let s = date
    let d = serverDateFormatter.date(from: s)!
    date = localDateFormatter.string(from: d)
    
    var myMutableString = NSMutableAttributedString()
    if #available(iOS 8.2, *) {
    cell!.textLabel?.font = UIFont.systemFont(ofSize: 18.0, weight: UIFontWeightRegular)
    } else {
    }
    let myString:String = Name! + " - " + date
    myMutableString = NSMutableAttributedString(string: myString as String)
    
    cell!.textLabel?.attributedText = myMutableString
    cell!.textLabel?.numberOfLines = 0
    cell!.textLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
    
    return cell!
}
}


