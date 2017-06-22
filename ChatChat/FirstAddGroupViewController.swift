//
//  FirstAddGroupViewController.swift
//  ChatChat
//
//  Created by Patrick James White on 6/16/17.
//  Copyright © 2017 Razeware LLC. All rights reserved.
//

import UIKit

class FirstAddGroupViewController: UIViewController {

    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var groupNameTextField: UITextField!
    @IBOutlet weak var pleaseEnterLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func nextClicked(_ sender: Any) {
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        

        let chatVc = segue.destination as! SecondAddGroupViewController
        
        if groupNameTextField.text != ""{
         
            chatVc.groupName = groupNameTextField.text!
            
        }
        

        
            
    }
    


    


}
