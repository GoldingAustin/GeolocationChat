//
//  PokeMessage.swift
//  PokeTrade
//
//  Created by Austin Golding on 9/12/16.
//

import UIKit

class PokeMessage: UIViewController {
    @IBOutlet var Message: UITextField!
    @IBOutlet var CP: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func SubmitPoke(_ sender: AnyObject) {
        if (Message.text != "" && CP.text != "") {
            AppState.sharedInstance.mess = Message.text
            AppState.sharedInstance.cp = CP.text
            AppState.sharedInstance.markerSet = true
            if let navigationController = self.navigationController
            {
                navigationController.popViewController(animated: false)
                navigationController.popViewController(animated: false)
            }
        }
    }
    
}
