//
//  HelpViewController.swift
//  LFG
//
//  Created by Rakesh Mandhan on 2015-12-23.
//  Copyright © 2015 Rakesh. All rights reserved.
//

import UIKit

class HelpViewController: TableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Help"
        
        self.tableView.tableFooterView = UIView()
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 44
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 4
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        var title = ""
        
        if section == 0 {
            title = "How to make a post"
        }
        else if section == 1 {
            title = "How to filter posts"
        }
        else if section == 2 {
            title = "How to delete a post"
        }
        else if section == 3 {
            title = "Why is my post disappearing?"
        }
        
        return title
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell: UITableViewCell!
        
        if let dequedCell = tableView.dequeueReusableCellWithIdentifier("Cell") {
            cell = dequedCell
        } else {
            cell = UITableViewCell(style: .Subtitle, reuseIdentifier: "Cell")
        }
        
        if indexPath.section == 0 {
            cell?.textLabel?.text = "1. Tap the plus button in the navigation bar \n2. Fill in all the fields (description is optional) \n3. Finally, tap \"Post!\""
        }
        else if indexPath.section == 1 {
            cell?.textLabel?.text = "1. Tap the filter button in the navigation bar \n2. Choose any combination of Platform and Gametype \n3. Finally, hit \"Apply\" \n"
            cell?.detailTextLabel?.text = "To remove the filter: simply tap \"Reset\" and \"Apply\""
        }
        else if indexPath.section == 2 {
            cell?.textLabel?.text = "1. Tap on your post \n2. The delete button should come up at the bottom \n3. Now, just tap \"Delete\""
        }
        else if indexPath.section == 3 {
            cell?.textLabel?.text = "There are 2 possible reasons:\n\n 1. When you make a new post, your last post automatically gets deleted regardless of what game it was for\n 2. Posts automatically disappear after a certain ammount of time. Typically, a post \"expires\" after 2-3 hours. It may be different for each game.\n"
            cell?.detailTextLabel?.text = "You can only have one post at a time"
        }
        
        cell?.textLabel?.numberOfLines = 0
        cell?.textLabel?.font = UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline)
        cell?.userInteractionEnabled = false
        
        return cell!
    }
    
}
