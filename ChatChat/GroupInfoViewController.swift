//
//  GroupInfoViewController.swift
//  ChatChat
//
//  Created by Patrick James White on 6/8/17.
//  Copyright © 2017 Razeware LLC. All rights reserved.
//

import UIKit
import ChameleonFramework
import Firebase

class GroupInfoViewController: UIViewController, UITableViewDataSource,UITableViewDelegate {

    @IBOutlet weak var leaveGroupButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    var channelRef: FIRDatabaseReference?
    
    var currentUserGroupRef = ""
    
    var currentUsers = [[String:AnyObject]]()
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        self.view.backgroundColor = UIColor(netHex: 0x2f373e)
        
        tableView.backgroundColor = UIColor.clear
        //leaveGroupButton.backgroundColor = FlatWhite()
        leaveGroupButton.layer.cornerRadius = 1.5
        leaveGroupButton.layer.masksToBounds = true
        //leaveGroupButton.layer.borderColor = FlatWhite().cgColor
        //leaveGroupButton.layer.borderWidth = 1.5
        
        tableView.layer.cornerRadius = 1.5
        tableView.layer.masksToBounds = true
        tableView.layer.borderColor = FlatWhite().cgColor
        tableView.layer.borderWidth = 1.5
        
        
        // Do any additional setup after loading the view.
    }
    
    
    
    // MARK: UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1 // 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { // 2
        
        return currentUsers.count
        
    }
    
    // 3
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = "userCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        print("in cell")
        let title = cell.contentView.viewWithTag(1) as! UILabel
        
        title.text = currentUsers[indexPath.row]["name"] as! String
        title.textColor = FlatWhite()
        cell.backgroundColor = UIColor.clear

        
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1.50
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView!
    {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 1.50))
        //let shadow = UIView(frame: CGRect(x: 18, y: 0, width: tableView.bounds.size.width - 36, height: 2))
        //shadow.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        //headerView.addSubview(shadow)
        headerView.backgroundColor = UIColor.clear
        
        return headerView
    }

    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func leaveGroupPressed(_ sender: Any) {
        
        var groupUsersRef: FIRDatabaseReference = channelRef!.child("users")
        print(currentUserGroupRef)
        print(groupUsersRef)
        
        groupUsersRef.child(currentUserGroupRef).removeValue { error in
           if error != nil {
                print("error \(error)")
            }
        }
        
    
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if segue.identifier == "addUsers"{
            
            print("here we go")
            let chatVc = segue.destination as! SecondAddGroupViewController
            
            let channel = self.channelRef
            chatVc.addUserChannelRef = channel
            chatVc.justAddUsers = true
            
            
        }
        
    }

}
