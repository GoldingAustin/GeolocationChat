//
//  SettingsViewController.swift
//  PokeTradeChat
//
//  Created by Austin Golding on 8/31/16.
//

import UIKit


class SettingsViewController: UIViewController, UIPopoverPresentationControllerDelegate, ColorPickerDelegate, UITextFieldDelegate {
    @IBOutlet var colorPreview: UIView!
    
    @IBOutlet var changeColorButton: UIButton!
    
    @IBOutlet var changeUserName: UITextField!
    @IBAction func changeColorButtonClicked(_ sender: UIButton) {
        let image = UIImage(named: "Image")
        self.showColorPicker()
    }

    
    
    var selectedColor: UIColor = UIColor.blue
    var selectedColorHex: String = "0000ff"
    

    override func viewDidLoad() {
        super.viewDidLoad()

        self.changeUserName.delegate = self

        self.colorPreview.layer.cornerRadius = self.colorPreview.layer.frame.width/6
        selectedColor = convertHexToUIColor(hexColor: AppState.sharedInstance.nameColor!)
        selectedColorHex = AppState.sharedInstance.nameColor!

        self.colorPreview.backgroundColor = self.selectedColor
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {

        return UIModalPresentationStyle.none
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        AppState.sharedInstance.displayName = changeUserName.text
        return true
    }

    func colorPickerDidColorSelected(selectedUIColor: UIColor, selectedHexColor: String) {

        self.selectedColor = selectedUIColor
        AppState.sharedInstance.nameColor = selectedHexColor
        
        self.selectedColorHex = selectedHexColor

        self.colorPreview.backgroundColor = selectedUIColor
    }
    
    fileprivate func showColorPicker(){
        
        let colorPickerVc = storyboard?.instantiateViewController(withIdentifier: "sbColorPicker") as! ColorPickerViewController
        
        colorPickerVc.modalPresentationStyle = .popover
        
        colorPickerVc.preferredContentSize = CGSize(width: 265, height: 400)
        
        colorPickerVc.colorPickerDelegate = self
        
        if let popoverController = colorPickerVc.popoverPresentationController {
            
            popoverController.sourceView = self.view
            
            popoverController.sourceRect = self.changeColorButton.frame
            
            popoverController.permittedArrowDirections = UIPopoverArrowDirection.any
            
            popoverController.delegate = self
        }
        
        present(colorPickerVc, animated: true, completion: nil)
    }
    
    fileprivate func convertHexToUIColor(hexColor : String) -> UIColor {
        
        let characterSet = CharacterSet.whitespacesAndNewlines as CharacterSet
        
        var colorString : String = hexColor.trimmingCharacters(in: characterSet)
        
        colorString = colorString.uppercased()
        
        if colorString.hasPrefix("#") {
            colorString =  colorString.substring(from: colorString.characters.index(colorString.startIndex, offsetBy: 1))
        }
        
        if colorString.characters.count != 6 {
            return UIColor.black
        }
        
        var rgbValue: UInt32 = 0
        Scanner(string:colorString).scanHexInt32(&rgbValue)
        let valueRed    = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let valueGreen  = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let valueBlue   = CGFloat(rgbValue & 0x0000FF) / 255.0
        let valueAlpha  = CGFloat(1.0)

        return UIColor(red: valueRed, green: valueGreen, blue: valueBlue, alpha: valueAlpha)
    }
}
