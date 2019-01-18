//
//  ViewController.swift
//  TestDTLS
//
//  Created by Pedro Paulo Oliveira Junior on 15/01/19.
//  Copyright © 2019 Trinity. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var useCell = true
    @IBOutlet weak var ipField: UITextField!
    @IBOutlet weak var ifaceSelector: UISegmentedControl!
    @IBAction func connect(_ sender: Any) {
        let dtls = DTLSiOSNew(gateway: Endpoint(address: ipField.text ?? "", port: "80", version: .four))
        
//        let cell = CellularUDPSession(gateway: Endpoint(address: ipField.text ?? "", port: "80", version: .four))
//        useCell = (ifaceSelector.selectedSegmentIndex == 0)
//        if cell.doSSLHandshake(useCell) == 0 {
//            presentAlert("Works")
//        } else {
//            presentAlert("Does not work")
//        }
    }
    
    func presentAlert(_ message: String!) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .destructive, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}




