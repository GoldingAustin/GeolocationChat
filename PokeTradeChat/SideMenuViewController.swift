//
//  SideMenuViewController.swift
//  PokeTradeChat
//
//  Created by Austin Golding on 8/30/16.
//

import Foundation
import SideMenuController

class SideMenuViewController: SideMenuController {

override func viewDidLoad() {
    super.viewDidLoad()
    performSegue(withIdentifier: "embededCenterControllerChat", sender: nil)
    performSegue(withIdentifier: "embededSideController", sender: nil)
}
}
