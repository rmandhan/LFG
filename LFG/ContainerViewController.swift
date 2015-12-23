//
//  ContainerViewController.swift
//  LFG
//
//  Created by Rakesh Mandhan on 2015-12-21.
//  Copyright © 2015 Rakesh. All rights reserved.
//

import UIKit

class ContainerViewController: ViewController, UIScrollViewDelegate , PanelDelegate {
    
    @IBOutlet var scrollView: UIScrollView!
    
    // This value matches the left menu's width in the Storyboard
    let leftMenuWidth: CGFloat = 200
    
    var panelEnabled = false {
        didSet {
            self.scrollView.scrollEnabled = panelEnabled
        }
    }
    
    var mainNVC: MainNavigationController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dispatch_async(dispatch_get_main_queue()) {
            self.closePanel(animated: false)
        }
    }
    
    func togglePanel() {
        if self.panelEnabled {
            print("Panel toggled")
            self.scrollView.contentOffset.x == 0  ? closePanel(animated: true) : openPanel()
        }
    }
    
    // Open is the natural state of the menu because of how the storyboard is setup
    func openPanel() {
        self.scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
    }
    
    // Use scrollview content offset-x to slide the menu.
    func closePanel(animated animated: Bool){
        self.scrollView.setContentOffset(CGPoint(x: leftMenuWidth, y: 0), animated: animated)
    }
    
    // MARK: Segue
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "mainView" {
            self.mainNVC = segue.destinationViewController as! MainNavigationController
        } else if segue.identifier == "panelView" {
            let panelNVC = segue.destinationViewController as! UINavigationController
            let panelVC = panelNVC.topViewController as! PanelViewController
            panelVC.delegate = self
        }
    }
    
    // MARK: PanelDelegate
    
    func userDidSelectPanelOption(option: PanelOption) {
        self.closePanel(animated: true)
        self.mainNVC?.showViewForPanelOption(option)
    }
    
    // MARK: UIScrollViewDelegate
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        self.scrollView.pagingEnabled = true
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        self.scrollView.pagingEnabled = false
    }
    
}
