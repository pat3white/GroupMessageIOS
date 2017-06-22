//
//  AddGroupChatter.swift
//  ChatChat
//
//  Created by Patrick James White on 6/6/17.
//  Copyright © 2017 Razeware LLC. All rights reserved.
//

import UIKit
import Firebase
import ChameleonFramework

class AddGroupChatter: UIViewController,UISearchBarDelegate, UISearchResultsUpdating, UITableViewDelegate,UITableViewDataSource {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var saveGroupButton: UIButton!
    @IBOutlet weak var textField: UITextField!
    
    
    var selectedRows = [String]()
    var deSelectedRows = [String]()
    
    var candies = [Dictionary<String, AnyObject>]()
    var filteredCandies = [Dictionary<String, AnyObject>]()
    let searchController = UISearchController(searchResultsController: nil)
    
    private lazy var userRef: FIRDatabaseReference = FIRDatabase.database().reference().child("users")
    private var userRefHandle: FIRDatabaseHandle?

    
    private lazy var channelRef: FIRDatabaseReference = FIRDatabase.database().reference().child("channels")
    private var channelRefHandle: FIRDatabaseHandle?
    
    var addUserChannelRef: FIRDatabaseReference?
    
    
    private var channels: [FBUser] = []
    
    var currentUserData = [String:AnyObject]()
    
    var justAddUsers = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Add Group"
        
        
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        definesPresentationContext = true
        searchController.dimsBackgroundDuringPresentation = false
        tableView.tableHeaderView = searchController.searchBar
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        if justAddUsers == true{
            
            textField.alpha = 0.0
        }
        retrieveAllUsers()
        /*
        textField.backgroundColor = UIColor.clear
        textField.layer.cornerRadius = 1.5
        textField.layer.masksToBounds = true
        textField.layer.borderWidth = 1.5
        textField.layer.borderColor = FlatWhite().cgColor
        
        tableView.dataSource = self
        tableView.delegate = self
        */
        
    }
    
    func retrieveAllUsers(){
        
        
        userRefHandle = userRef.observe(.childAdded, with: { (snapshot) -> Void in // 1
            let userData = snapshot.value as! Dictionary<String, AnyObject> // 2
            let id = snapshot.key
            if let name = userData["name"] as! String!, let uid = userData["uid"] as! String!, name.characters.count > 0 { // 3
                if uid == (FIRAuth.auth()?.currentUser?.uid)!{
                    self.currentUserData = userData
                }
                else{
                    self.candies.append(userData)
                    self.tableView.reloadData()
                }
            } else {
                print("Error! Could not decode channel data")
            }
        })
    }


    
    
    
    // MARK: UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1 // 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { // 2
        
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredCandies.count
        }
        return candies.count
        
    }
    
    // 3
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = "userName"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        
        let title = cell.contentView.viewWithTag(1) as! UILabel
        let highlighter = cell.contentView.viewWithTag(2)!
        
        var uuid = ""
        

        highlighter.backgroundColor = UIColor.clear
        
        if searchController.isActive && searchController.searchBar.text != "" {
            let candy = filteredCandies[indexPath.row]
            
            uuid = (filteredCandies[indexPath.row])["meuid"] as! String
            title.text = (filteredCandies[indexPath.row])["name"] as! String
        } else {
            let candy = candies[indexPath.row]
            
            uuid = (candies[indexPath.row])["meuid"] as! String
            title.text = (candies[indexPath.row])["name"] as! String
                //candy["name"] as! String!
        }
        

        if selectedRows.contains(uuid){

            highlighter.backgroundColor = FlatPurple()
        }
        
        if deSelectedRows.contains(uuid){

            highlighter.backgroundColor = UIColor.clear
            
            selectedRows = selectedRows.filter {$0 != uuid}
            deSelectedRows = deSelectedRows.filter {$0 != uuid}
        }
        
        
        
        
        
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
        headerView.backgroundColor = FlatWhite()
        return headerView
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //print(indexPath)
        
        
        var uuid = ""
        if searchController.isActive && searchController.searchBar.text != "" {
            uuid = (filteredCandies[indexPath.row])["meuid"] as! String
        }
        else{
            uuid = (candies[indexPath.row])["meuid"] as! String
        }
        
        print("selected:",uuid)
        
        if selectedRows.contains(uuid){
            print("already selected")
            deSelectedRows.append(uuid)
        }
        else{
            print("not selected yet")
            selectedRows.append(uuid)
        }
        
        print(selectedRows)
        
        self.tableView.reloadData()
    }
    


    
    func filterContentForSearchText(searchText: String) {
        filteredCandies = candies.filter { candy in
            return (candy["name"] as! String!).lowercased().contains(searchText.lowercased())
        }
        
        tableView.reloadData()
    }
    
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        filterContentForSearchText(searchText: searchBar.text!)
    }

    
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
    
    @IBAction func saveGroup(_ sender: Any) {
        
        
        // 1
        if justAddUsers == false{
            if textField.text != ""{
                
                let newChannelRef = channelRef.childByAutoId() // 2
                let channelItem = [ // 3
                    "name": textField.text,
                    "last_update": 0.0
                    ] as [String : Any]
                newChannelRef.setValue(channelItem) // 4
                
                var groupUsersRef: FIRDatabaseReference = newChannelRef.child("users")
                
                
                
                for selectedRow in selectedRows{
                    var itemRef = groupUsersRef.childByAutoId()
                    
                    
                    let foundEntry = candies.filter { (($0)["meuid"] as! String) == selectedRow}
                    
                    if foundEntry.count > 0{
                        let user = foundEntry[0]
                        print(user)
                        let user_uid = user["uid"] as! String!
                        let name = user["name"] as! String!
                        //print(user_uid)
                        let userItem = [
                            "user_uid": user_uid,
                            "has_read": true,
                            "name": name] as [String : Any]
                        
                        itemRef.setValue(userItem)
                    }
                }
                
                let itemRef = groupUsersRef.childByAutoId()
                let user_uid = currentUserData["uid"] as! String!
                let name = currentUserData["name"] as! String!
                //print(user_uid)
                let userItem = [
                    "user_uid": user_uid,
                    "name": name]
                
                itemRef.setValue(userItem)
                
            }


        }
        else{
            
// 2

            
            var groupUsersRef: FIRDatabaseReference = addUserChannelRef!.child("users")
            
            
            
            for selectedRow in selectedRows{
                var itemRef = groupUsersRef.childByAutoId()
                
                
                let foundEntry = candies.filter { (($0)["meuid"] as! String) == selectedRow}
                
                if foundEntry.count > 0{
                    let user = foundEntry[0]
                    print(user)
                    let user_uid = user["uid"] as! String!
                    let name = user["name"] as! String!
                    //print(user_uid)
                    let userItem = [
                        "user_uid": user_uid,
                        "name": name]
                    
                    itemRef.setValue(userItem)
                }
            }
            

        }
        
        
        
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

