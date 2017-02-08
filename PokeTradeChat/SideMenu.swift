//
//  SideMenuController.swift
//  PokeTradeChat
//
//  Created by Austin Golding on 8/30/16.
//

import UIKit

class SideMenu: UITableViewController {
    
    let segues = ["embededCenterControllerChat", "embededCenterControllerMap", "embededCenterControllerSettings", "embededCenterControllerPrivate"]
    fileprivate var previousIndex: IndexPath?
    let menuNames = ["Chat", "Map", "Settings", "Private Chat", "Sign Out"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
   
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return segues.count + 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "menuCell")!
        cell.textLabel?.font = UIFont(name: "HelveticaNeue-Light", size: 15)
        cell.textLabel?.text = menuNames[(indexPath as IndexPath).row]
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let index = previousIndex {
            tableView.deselectRow(at: index, animated: true)
        }
        
        if (indexPath.row != 4) {
        sideMenuController?.performSegue(withIdentifier: segues[indexPath.row], sender: nil)
        previousIndex = indexPath
        }
        else {
                let firebaseAuth = FIRAuth.auth()
                do {
                    try firebaseAuth?.signOut()
                    AppState.sharedInstance.signedIn = false
                    dismiss(animated: true, completion: nil)
                } catch let signOutError as NSError {
                    print ("Error signing out: \(signOutError)")
            }
        }
    }
    
}

