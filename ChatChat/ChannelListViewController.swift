/*
 * Copyright (c) 2015 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import ChameleonFramework
import Firebase
import Darwin

enum Section: Int {
    case createNewChannelSection = 0
    case currentChannelsSection
}


//00dcfe

class ChannelListViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate {

    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var popUpView: UIView!
    
    @IBOutlet weak var loadingView: UIView!
    
    var groupUsers = [String:[[String:AnyObject]]]()
    var groupMeUserRef = [String:String]()
    var groupMeUserData = [String:[String:AnyObject]]()
    
    @IBOutlet weak var bottomLayoutGuideConstraint: NSLayoutConstraint!
    
    // MARK: Properties
    var senderDisplayName: String? // 1
    var newChannelTextField: UITextField? // 2
    private var channels: [Channel] = [] // 3
    
    @IBOutlet weak var tableView: UITableView!

    private lazy var userRef: FIRDatabaseReference = FIRDatabase.database().reference().child("users")
    private var userRefHandle: FIRDatabaseHandle?
    
    private lazy var channelRef: FIRDatabaseReference = FIRDatabase.database().reference().child("channels")
    private var channelRefHandle: FIRDatabaseHandle?
    
    var currentUserData = [String:AnyObject]()

    
    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Groups"
        
        
        self.view.backgroundColor = UIColor(netHex: 0x2f373e)
        self.tableView.backgroundColor = UIColor.clear
        //09142E top/bottom
        //112158 middle
        
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        //print(self.tableView.frame)
        //print(self.tableView.bounds)
        
        self.senderDisplayName = ""
        
        loginButton.titleLabel?.adjustsFontSizeToFitWidth = true
        
        self.tableView.alpha = 0.0
        
        self.popUpView.alpha = 0.0
        
        self.loadingView.backgroundColor = UIColor.clear
        
        
        

        
        let date = Date()
        
        let defaults = UserDefaults.standard
        let arrayOfObjectsKey = "joined"
        //if start of it, there is no saved key, basically when the user just downloads the app, very start
        if defaults.data(forKey: arrayOfObjectsKey) == nil{

            //print("first time, have not logged in yet")
            self.popUpView.alpha = 1.0
            
            
        }
        else{
            
            let userData = UserDefaults.standard.object(forKey: "joined") as? NSData
            if let userData = userData {
                var user = NSKeyedUnarchiver.unarchiveObject(with: userData as Data) as? FBUser
                
                self.senderDisplayName = user!
                    .name
            }

            //print("not first time, have logged in")
            self.tableView.alpha = 1.0
            FIRAuth.auth()?.signInAnonymously(completion: { (user, error) in // 2
                if let err = error { // 3
                    print(err.localizedDescription)
                    return
                }
                self.observeChannels()
            })
        }


        // Do any additional setup after loading the view.
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShowNotification(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHideNotification(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
       

        
        nameTextField.delegate = self
    }
    
    
    func colors(row:Int) -> UIColor{
        
        let colorsToChoose = [FlatRedDark(),FlatMaroonDark(),FlatYellowDark(),FlatMintDark(),FlatBlueDark(),FlatMaroonDark(),FlatWatermelonDark(),FlatOrangeDark()]
            
            //UIColor(netHex: 0xBB9BFE),UIColor(netHex: 0xFE9476),UIColor(netHex: 0xF7ED91),UIColor(netHex: 0x7BE987),UIColor(netHex: 0x38F1FA)]
        
        
        if row > (colorsToChoose.count - 1){
            let compensatedRow = row % (colorsToChoose.count - 1)
            return colorsToChoose[compensatedRow]
        }
        else{
            return colorsToChoose[row]
        }
        
        
        
        
        
        
    }
    
    /**
     * Called when 'return' key pressed. return NO to ignore.
     */
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func unwindToChannelList(_ segue:UIStoryboardSegue) {

    }
    
    /**
     * Called when the user click on the view (outside the UITextField).
     */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShowNotification(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHideNotification(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        self.navigationController?.navigationBar.titleTextAttributes = [ NSFontAttributeName: UIFont (name: "HelveticaNeue-Light", size: 25)!,NSForegroundColorAttributeName: FlatBlack()]
        
        self.tableView.reloadData()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

    }
    
    
    func keyboardWillShowNotification(_ notification: Notification) {
        let keyboardEndFrame = ((notification as NSNotification).userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let convertedKeyboardEndFrame = view.convert(keyboardEndFrame, from: view.window)
        bottomLayoutGuideConstraint.constant = view.bounds.maxY - convertedKeyboardEndFrame.minY
    }
    
    func keyboardWillHideNotification(_ notification: Notification) {
        bottomLayoutGuideConstraint.constant = 48
    }
    

    @IBAction func loginAction(_ sender: Any) {
        if nameTextField.text != ""{
            
            self.nameTextField.resignFirstResponder()
            FIRAuth.auth()?.signInAnonymously(completion: { (user, error) in // 2
                if let err = error { // 3
                    //print(err.localizedDescription)
                    return
                }
                
                let uuid = UUID().uuidString
                
                let newUserRef = self.userRef.childByAutoId() // 2
                let userItem = [ // 3
                    "uid": user?.uid,
                    "name": self.nameTextField.text!,
                    "meuid": uuid
                ]
                newUserRef.setValue(userItem) // 4
                
                
                
                let object:FBUser = FBUser(uid: (user?.uid)!, name: self.nameTextField.text!, meuid: uuid)
                //print("sign in")
                let defaults = UserDefaults.standard
                let objectKey = "joined"
                var objectData = NSKeyedArchiver.archivedData(withRootObject: object)
                
                
                defaults.set(objectData, forKey: objectKey)
                
                self.senderDisplayName = self.nameTextField.text!
                self.observeChannels()
                
                self.popUpView.alpha = 0.0
                self.tableView.alpha = 1.0
                
                
                
            })
        }

    }
    
    deinit {
        if let refHandle = channelRefHandle {
            channelRef.removeObserver(withHandle: refHandle)
        }
    }
    
    
    @IBAction func createChannel(_ sender: AnyObject) {
        if let name = newChannelTextField?.text { // 1
            let newChannelRef = channelRef.childByAutoId() // 2
            let channelItem = [ // 3
                "name": name
            ]
            newChannelRef.setValue(channelItem) // 4
        }
    }
    
    func getUsers(){
        
    }
    
    private func observeChannels() {
        // Use the observe method to listen for new
        // channels being written to the Firebase DB
        let currentUserUID = FIRAuth.auth()?.currentUser?.uid
        //print("channelRef",channelRef)
        
        
        //

        
        
        
        channelRefHandle = channelRef.observe(.childAdded, with: { (snapshot) -> Void in // 1
            let channelData = snapshot.value as! Dictionary<String, AnyObject> // 2
            let id = snapshot.key
            if let name = channelData["name"] as! String!,let last_update = channelData["last_update"] as? Double, name.characters.count > 0 { // 3

                
                
                
                var userChannelRef: FIRDatabaseReference = self.channelRef.child(id).child("users")
                var userChannelRefHandle: FIRDatabaseHandle?
                
                
                userChannelRefHandle = userChannelRef.observe(.childAdded, with: { (data) -> Void in
                    
                    let userChannelData = data.value as! Dictionary<String, AnyObject> // 2
                    let user_id = data.key
                    self.currentUserData = userChannelData
                    if self.groupUsers[id] == nil{
                        self.groupUsers[id] = [userChannelData]
                    }
                    else{
                        self.groupUsers[id]?.append(userChannelData)
                    }

                    if currentUserUID! == userChannelData["user_uid"] as! String{
                        
                        self.groupMeUserRef[id] = user_id
                        self.groupMeUserData[id] = userChannelData
                        
                        self.channels.append(Channel(id: id, name: name,last_update:last_update))
                        
                    }
                    
                    if self.channels.count > 0{
                        
                        
                        self.channels.sort {
                            return $0.last_update > $1.last_update
                        }
                        
                        self.tableView.reloadData()
                    }
                    
                    
                    
                })
                
                
                
                

                
            } else {
                print("Error! Could not decode channel data")
            }
        })
    }
    
    
    // MARK: UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        //print(channels.count)
        if channels.count > 0{
            self.loadingView.alpha = 0.0
        }
        return channels.count // 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { // 2

                return 1

    }
    
    // 3
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        //print("in cell")
        let reuseIdentifier = "groupCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        
        let title = cell.contentView.viewWithTag(1) as! UILabel
        let subtitle = cell.contentView.viewWithTag(2) as! UILabel
        let highlightView = cell.contentView.viewWithTag(3)!
        let dateLabel = cell.contentView.viewWithTag(4) as! UILabel
        let ifReadView = cell.contentView.viewWithTag(5)!
        
        let channel = channels[(indexPath as NSIndexPath).section]
        //print(channel.id)
        let cellChannelRef = channelRef.child(channel.id)
        

        
        ifReadView.backgroundColor = UIColor.clear
        
        
        var messageRef: FIRDatabaseReference = cellChannelRef.child("messages")
        var newMessageRefHandle: FIRDatabaseHandle?
        subtitle.text = "No recent messages"
        let messageQuery = messageRef.queryLimited(toLast:1)
        newMessageRefHandle = messageQuery.observe(.childAdded, with: { (snapshot) -> Void in

            print(channel.name)
            let messageData = snapshot.value as! Dictionary<String, String>
            //print(channel.id,snapshot.key)
            
            let messageKey = snapshot.key
            //print(indexPath)
            if UserDefaults.standard.value(forKey: "dict") != nil{
                
                
                var dict = UserDefaults.standard.value(forKey: "dict") as! [String:String]
                
                if dict[channel.id] != nil{
                    
                    let messageIdToCompare = dict[channel.id]!
                    print("\t",1,messageIdToCompare,messageKey)
                    
                    if (messageIdToCompare != messageKey){
                        print("\t",5)
                        dict[channel.id] = messageKey
                        UserDefaults.standard.set(dict, forKey: "dict")
                        
                        ifReadView.backgroundColor = FlatWhite()


                    }
                    else{
                        print("\t",2)
                        ifReadView.backgroundColor = UIColor.clear
                    }
                }
                else{
                    print("\t",3)
                    dict[channel.id] = messageKey
                    ifReadView.backgroundColor = FlatWhite()
                    UserDefaults.standard.set(dict, forKey: "dict")
                    
                }
            }
            else{
                print("\t",4)
                let dict:[String:String] = [channel.id:messageKey]
                ifReadView.backgroundColor = FlatWhite()
                UserDefaults.standard.set(dict, forKey: "dict")
            }
            
            if let id = messageData["senderId"] as String!, let name = messageData["senderName"] as String!, let text = messageData["text"] as String!,var ms = messageData["ms"] as String!, text.characters.count > 0 {
                // 4
                
                let cur_ms = Date().timeIntervalSince1970
                
                let ms = Double(ms)!
                
                let diffSeconds = cur_ms-ms
                
                let daysSince = Int((diffSeconds/60/60/24).rounded(.down))
                
                if daysSince == 0{
                    dateLabel.text = "Today"
                }
                else if daysSince == 1{
                    dateLabel.text = String(daysSince) + " day"
                }
                else{
                    dateLabel.text = String(daysSince) + " days"
                }
                
                
                subtitle.text = name + ": " + text
            } else {
                //print("Error! Could not decode message data")
            }
        })
        
        title.text = channel.name
        title.textColor = UIColor.white
            //UIColor(netHex: 0x00dcfe)
        dateLabel.textColor = FlatGray()
        subtitle.textColor =  FlatGray()
        
        ifReadView.layer.cornerRadius = ifReadView.frame.size.width/2
        ifReadView.clipsToBounds = true
        
        highlightView.layer.cornerRadius = 1.0
        highlightView.layer.masksToBounds = true
        highlightView.backgroundColor = UIColor.clear

            //
            //FlatWhiteDark()
            //colors(row: indexPath.section)
            
        
        cell.backgroundColor = UIColor.clear
        cell.contentView.backgroundColor = UIColor.clear
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1.5
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView!
    {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 1.50))
        //let shadow = UIView(frame: CGRect(x: 18, y: 0, width: tableView.bounds.size.width - 36, height: 2))
        //shadow.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        //headerView.addSubview(shadow)
        headerView.backgroundColor = self.view.backgroundColor?.adjust(-0.015, green: -0.015, blue: -0.015, alpha: 0.0)
            //.adjust(-0.015, green: -0.015, blue: -0.015, alpha: 0.0)
        return headerView
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        
        
        tableView.deselectRow(at: indexPath, animated:true)
        //hideTableView()
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if segue.identifier == "showChat"{
            if let indexPath = tableView.indexPathForSelectedRow {
                let chatVc = segue.destination as! ChatViewController
                
                let channel = channels[indexPath.section]
                chatVc.senderDisplayName = senderDisplayName
                chatVc.channel = channel
                chatVc.channelRef = channelRef.child(channel.id)
                chatVc.currentUsers = self.groupUsers[channel.id]!
                chatVc.currentUserGroupRef = self.groupMeUserRef[channel.id]!
                //print(chatVc.currentUserGroupRef)
                
            }
        }
        
    }
    

}
