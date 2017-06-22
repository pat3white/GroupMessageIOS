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
import Firebase
import ChameleonFramework
import JSQMessagesViewController

final class ChatViewController: JSQMessagesViewController {
  // MARK: Properties
    lazy var outgoingBubbleImageView: JSQMessagesBubbleImage = self.setupOutgoingBubble()
    lazy var incomingBubbleImageView: JSQMessagesBubbleImage = self.setupIncomingBubble()
    
    private lazy var messageRef: FIRDatabaseReference = self.channelRef!.child("messages")
    private var newMessageRefHandle: FIRDatabaseHandle?
    
    private var changeUserReadHandle: FIRDatabaseHandle?
  // MARK: View Lifecycle
    var messages = [JSQMessage]()
    var channelRef: FIRDatabaseReference?
    var channel: Channel? {
        didSet {
            title = channel?.name
        
        }
    }
    
    var currentUsers = [[String:AnyObject]]()
    var currentUserGroupRef: String = ""
  
    private lazy var usersTypingQuery: FIRDatabaseQuery =
        self.channelRef!.child("typingIndicator").queryOrderedByValue().queryEqual(toValue: true)
    
    private lazy var userIsTypingRef: FIRDatabaseReference =
        self.channelRef!.child("typingIndicator").child(self.senderId) // 1
    private var localTyping = false // 2
    var isTyping: Bool {
        get {
            return localTyping
        }
        set {
            // 3
            localTyping = newValue
            userIsTypingRef.setValue(newValue)
        }
    }
    
  override func viewDidLoad() {
    super.viewDidLoad()
    
    //print("haha")
    //removing avatar
    observeMessages()
    collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
    collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
    
    self.view.backgroundColor = UIColor.clear
    self.collectionView.backgroundColor = UIColor.white
    
    self.inputToolbar.contentView.backgroundColor = FlatWhite()

    self.inputToolbar.contentView.rightBarButtonItem.setTitleColor(FlatBlack(), for: UIControlState.normal)
    
    
    self.inputToolbar.contentView.rightBarButtonItem.setTitleColor(FlatGray(), for: UIControlState.disabled)

    self.senderId = FIRAuth.auth()?.currentUser?.uid
    
    self.collectionView.collectionViewLayout.messageBubbleFont = UIFont (name: "HelveticaNeue-Light", size: 15)
    
    self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.flatBlack(),NSFontAttributeName: UIFont (name: "HelveticaNeue-Light", size: 20)!]
    self.navigationController?.navigationBar.tintColor = FlatBlack()
    


    }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    print(channel!.id)
    
    if UserDefaults.standard.value(forKey: "dict") != nil{
        
        var dict = UserDefaults.standard.value(forKey: "dict") as! [String:String]
        
        dict[channel!.id] = ""
        UserDefaults.standard.set(dict, forKey: "dict")

        
    }
 
    
    
    //self.channelRef!.child("users").child(self.currentUserGroupRef).updateChildValues(["has_read":true])
    observeTyping()
    }

    
    private func setupOutgoingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.outgoingMessagesBubbleImage(with: UIColor.clear)
    }
    
    private func setupIncomingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.incomingMessagesBubbleImage(with: UIColor.clear)
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item] // 1
        if message.senderId == senderId { // 2
            return outgoingBubbleImageView
        } else { // 3
            return incomingBubbleImageView
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }

    
  // MARK: Collection view data source (and related) methods
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath) -> NSAttributedString? {
        let message = messages[indexPath.item]
        
        // Displaying names above messages
        //Mark: Removing Sender Display Name
        /**
         *  Example on showing or removing senderDisplayName based on user settings.
         *  This logic should be consistent with what you return from `heightForCellTopLabelAtIndexPath:`
         */

        //print(message.senderId == senderId)
        if message.senderId == senderId {
            
            
        }
        
    
        return NSAttributedString(string: message.senderDisplayName, attributes: [NSForegroundColorAttributeName: FlatGrayDark()])
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout, heightForCellTopLabelAt indexPath: IndexPath) -> CGFloat {
        /**
         *  Each label in a cell has a `height` delegate method that corresponds to its text dataSource method
         */
        
        /**
         *  This logic should be consistent with what you return from `attributedTextForCellTopLabelAtIndexPath:`
         *  The other label height delegate methods should follow similarly
         *
         *  Show a timestamp for every 3rd message
         */
        if indexPath.item % 6 == 0 {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        
        return 0.0
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, attributedTextForCellTopLabelAt indexPath: IndexPath) -> NSAttributedString? {
        /**
         *  This logic should be consistent with what you return from `heightForCellTopLabelAtIndexPath:`
         *  The other label text delegate methods should follow a similar pattern.
         *
         *  Show a timestamp for every 3rd message
         */
        if (indexPath.item % 6 == 0) {
            let message = self.messages[indexPath.item]
            //print("message:", message)
            //print(message.date)
            return JSQMessagesTimestampFormatter.shared().attributedTimestamp(for: message.date)
        }
        
        return nil
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout, heightForMessageBubbleTopLabelAt indexPath: IndexPath) -> CGFloat {
        
        /**
         *  Example on showing or removing senderDisplayName based on user settings.
         *  This logic should be consistent with what you return from `attributedTextForCellTopLabelAtIndexPath:`
         */

        
        /**
         *  iOS7-style sender name labels
         */
        let currentMessage = self.messages[indexPath.item]
        
        if currentMessage.senderId == self.senderId {
            return 0.0
        }
        
        if indexPath.item - 1 > 0 {
            let previousMessage = self.messages[indexPath.item - 1]
            if previousMessage.senderId == currentMessage.senderId {
                return 0.0
            }
        }
        
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }  // MARK: Firebase related methods
  
    private func addMessage(withId id: String, name: String, text: String,date: Date) {
        if let message = JSQMessage(senderId: id, senderDisplayName: name,date:date, text: text) {
            messages.append(message)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        let message = messages[indexPath.item]
        
        //print(message.senderId)
        
        if message.senderId == senderId {
            cell.textView?.textColor = FlatWhite()
            cell.textView?.backgroundColor = UIColor(netHex: 0x2f373e)
            
            let newX = cell.bounds.width - 4
            if (indexPath.item % 6 == 0) {
                print("yes1")
                let accentView = UIView(frame: CGRect(x: newX, y: 0, width: 2.5, height: cell.bounds.height))
                accentView.backgroundColor = FlatBlack()
                accentView.layer.cornerRadius = 0.8
                accentView.layer.masksToBounds = true
                cell.contentView.insertSubview(accentView, at: 0)
            }else{
                print("yes2")
                let accentView = UIView(frame: CGRect(x: newX, y: 0, width: 2.5, height: cell.bounds.height))
                accentView.backgroundColor = FlatBlack()
                accentView.layer.cornerRadius = 0.8
                accentView.layer.masksToBounds = true
                cell.contentView.insertSubview(accentView, at: 0)
            }

            
        } else {
            
            cell.textView?.textColor = FlatBlack()
            cell.textView?.backgroundColor = UIColor.clear
            cell.textView?.layer.cornerRadius = 1.5
            cell.textView?.layer.masksToBounds = true
            cell.textView.layer.borderColor = UIColor(netHex: 0x2f373e).cgColor
            cell.textView.layer.borderWidth = 1.5
                //UIColor(netHex: 0xA1B8D0)
            
            if (indexPath.item % 6 == 0) {
                print("yada")
            }
            let accentView = UIView(frame: CGRect(x: 0, y: 0, width: 2.5, height: cell.bounds.height))
            //print(message.senderId)
            let index = getIndexOfSenderID(idToFind: message.senderId, arrayToSearch: self.currentUsers)
            //print(index)
            accentView.backgroundColor = colors(row: index)
            accentView.layer.cornerRadius = 0.8
            accentView.layer.masksToBounds = true
            cell.contentView.insertSubview(accentView, at: 0)
            
        }
        

        return cell
    }
    
    func getIndexOfSenderID(idToFind:String,arrayToSearch:[[String:AnyObject]]) -> Int{
        //print(senderId,arrayToSearch)
        for (index,object) in arrayToSearch.enumerated(){
            //print(index,(object["user_uid"] as! String),idToFind)
            if (object["user_uid"] as! String) == idToFind{
                //print(index,object)
                return index
            }
        }
        return -1
        
    }
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        let itemRef = messageRef.childByAutoId() // 1
        let date = Date()
        let messageItem = [ // 2
            "senderId": senderId!,
            "senderName": senderDisplayName!,
            "text": text!,
            "date": String(describing: date),
            "ms": String(date.timeIntervalSince1970)
            ] as [String : Any]
        
        itemRef.setValue(messageItem) // 3
        
        
        let lastUpdateRef = self.channelRef!
        

        
        lastUpdateRef.updateChildValues(["last_update" : Double(date.timeIntervalSince1970)])
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound() // 4
        
        finishSendingMessage() // 5
        
        isTyping = false
    }
    
    private func observeMessages() {
        //print("channelRef:",channelRef)
        messageRef = channelRef!.child("messages")
        //print("messageRef:",messageRef)
        let messageQuery = messageRef.queryLimited(toLast:25)
        //print("messageQuery:",messageQuery)
        // 2. We can use the observe method to listen for new
        // messages being written to the Firebase DB
        newMessageRefHandle = messageQuery.observe(.childAdded, with: { (snapshot) -> Void in
            // 3
            //print("newMessageRefHandle:",self.newMessageRefHandle)
            //print("snapshot:",snapshot)
            let messageData = snapshot.value as! Dictionary<String, String>
            //print("messageData:",messageData)
            if let id = messageData["senderId"] as String!, let name = messageData["senderName"] as String!, let text = messageData["text"] as String!,let date = messageData["date"] as String!, text.characters.count > 0 {
                // 4
                let dateString = date
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss +zzzz"
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                
                let dateObj = dateFormatter.date(from: dateString)
                //print(1,dateObj)
                print(date)
                print(dateObj)
                if dateObj != nil{
                    
                    self.addMessage(withId: id, name: name, text: text,date:dateObj!)
                }
                let date1 = Date()

                
                //print("text:",text)
                self.finishReceivingMessage()
            } else {
                //print("Error! Could not decode message data")
            }
        })
    }
    
    override func textViewDidChange(_ textView: UITextView) {
        super.textViewDidChange(textView)
        // If the text is not empty, the user is typing
        isTyping = textView.text != ""
    }
    
    
    
    private func observeTyping() {
        let typingIndicatorRef = channelRef!.child("typingIndicator")
        userIsTypingRef = typingIndicatorRef.child(senderId)
        userIsTypingRef.onDisconnectRemoveValue()
        
        usersTypingQuery.observe(.value) { (data: FIRDataSnapshot) in
            // 2 You're the only one typing, don't show the indicator
            if data.childrenCount == 1 && self.isTyping {
                return
            }
            
            // 3 Are there others typing?
            self.showTypingIndicator = data.childrenCount > 0
            self.scrollToBottom(animated: true)
        }
    }
    
    
    func colors(row:Int) -> UIColor{
        
        let colorsToChoose = [FlatRedDark(),FlatYellowDark(),FlatMintDark(),FlatNavyBlueDark()]
            
            //UIColor(netHex: 0xFE9476),UIColor(netHex: 0xBB9BFE),UIColor(netHex: 0xF7ED91),UIColor(netHex: 0x7BE987),UIColor(netHex: 0x38F1FA),FlatRedDark(),FlatMaroonDark(),FlatYellowDark(),FlatMintDark(),FlatBlueDark(),FlatMaroonDark(),FlatWatermelonDark(),FlatOrangeDark()]
        
        
        if row > (colorsToChoose.count - 1){
            let compensatedRow = row % colorsToChoose.count
            return colorsToChoose[row]
        }
        else{
            return colorsToChoose[row]
        }
        
    }
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if segue.identifier == "groupInfo"{
            
            
            let chatVc = segue.destination as! GroupInfoViewController
            
            let channel = self.channelRef
            chatVc.channelRef = channel
            chatVc.currentUserGroupRef = self.currentUserGroupRef
            chatVc.currentUsers = self.currentUsers

                
        }
        
    }
  // MARK: UI and User Interaction

  
  // MARK: UITextViewDelegate methods
  
}
