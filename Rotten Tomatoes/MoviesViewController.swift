//
//  MoviesViewController.swift
//  Rotten Tomatoes
//
//  Created by Clover on 8/26/15.
//  Copyright (c) 2015 Clover. All rights reserved.
//

import UIKit

class MoviesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var networkErrMess: UILabel!
    @IBOutlet weak var xButton: UILabel!
    @IBOutlet weak var fadedView: UIView!

    var movies: [NSDictionary]?
    var refreshControl: UIRefreshControl!
    var searchActive : Bool = false
    var filtered: [NSDictionary] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        println(self.networkErrMess.frame.origin.y)
        // Setup delegates
        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self
        
        // Refreshing
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "onRefresh", forControlEvents: UIControlEvents.ValueChanged)
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to Refresh")
        tableView.insertSubview(refreshControl, atIndex: 0)
        
        
        let fadedViewtapGestureRecognizer = UITapGestureRecognizer(target: self, action: "onFadedViewTap")
        self.fadedView.addGestureRecognizer(fadedViewtapGestureRecognizer)
        let fadedViewpanGestureRecognizer = UIPanGestureRecognizer(target: self, action: "onFadedViewTap")
        self.fadedView.addGestureRecognizer(fadedViewpanGestureRecognizer)
        
        let xButtonTapGestureRecognizer = UITapGestureRecognizer(target: self, action: "onXButtonTap")
        self.xButton.addGestureRecognizer(xButtonTapGestureRecognizer)
        
        // Loading state while waiting for API
        let progressView = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        progressView.labelText = "Loading..."
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)) {
        
            self.doIfConnected({
                let url = NSURL(string: "https://gist.githubusercontent.com/timothy1ee/d1778ca5b944ed974db0/raw/489d812c7ceeec0ac15ab77bf7c47849f2d1eb2b/gistfile1.json")!
                let request = NSURLRequest(URL: url)
                NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) { (response: NSURLResponse!, data: NSData!, error: NSError!) -> Void in
                    let json = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil) as? NSDictionary
                    if let json = json {
                        self.movies = json["movies"] as? [NSDictionary]
                        self.tableView.reloadData()
                    }
                }
                }, errorMessageView: self.networkErrMess, closeButton: self.xButton)
            
            dispatch_async(dispatch_get_main_queue()) {
                MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
                //progressView.hide(true)
                println(self.xButton.frame.origin.y)
            }
        }
        println("done")
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table Control
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let movies = movies {
            if (searchActive) {
                return filtered.count
            }
            return movies.count
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("MovieCell", forIndexPath: indexPath) as! MovieCell
        
        var movie = searchActive ? filtered[indexPath.row] : movies![indexPath.row]
        
        cell.titleLabel.text = movie["title"] as? String
        cell.synopsisLabel.text = movie["synopsis"] as? String
        
        // Get image URL
        let url = NSURL(string: movie.valueForKeyPath("posters.thumbnail") as! String)!
        cell.posterView.setImageWithURL(url)
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    // MARK: - Refresh Control & Error Message
    
    func onRefresh() {
        
        self.doIfConnected({
            let url = NSURL(string: "https://gist.githubusercontent.com/timothy1ee/d1778ca5b944ed974db0/raw/489d812c7ceeec0ac15ab77bf7c47849f2d1eb2b/gistfile1.json")!
            let request = NSURLRequest(URL: url)
            NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) { (response: NSURLResponse!, data: NSData!, error: NSError!) -> Void in
                let json = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil) as? NSDictionary
                if let json = json {
                    self.movies = json["movies"] as? [NSDictionary]
                    self.tableView.reloadData()
                }
            }
            }, errorMessageView: self.networkErrMess, closeButton: self.xButton)
    
        self.refreshControl.endRefreshing()
    }
    
    func onXButtonTap() {
        //Turn Network Error bar off
        if self.networkErrMess.frame.origin.y == 64 {
            UIView.animateWithDuration(0.4, delay: 0.5, options: .CurveEaseOut, animations: {
                self.networkErrMess.frame.origin.y -= self.networkErrMess.frame.size.height
                self.xButton.frame.origin.y -= self.networkErrMess.frame.size.height
                }, completion: { finished in
                    println("Network Error bar is off")
            })
        }
    }
    
    // MARK: - Search Bar
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        self.fadedView.userInteractionEnabled = true
        self.fadedView.alpha = 0.35
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        self.searchBar.endEditing(true)
        self.fadedView.userInteractionEnabled = false
        self.fadedView.alpha = 0
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        self.searchBar.endEditing(true)
        self.fadedView.userInteractionEnabled = false
        self.fadedView.alpha = 0
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        if movies != nil {
            filtered = movies!.filter({ (movie) -> Bool in
                let tmpTitle = movie["title"] as? String
                let range = tmpTitle!.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch)
                return range != nil
            })
        }
        
        if (searchText == "" && filtered.count == 0) {
            searchActive = false
        } else {
            searchActive = true
        }
        self.tableView.reloadData()
    }
    
    func onFadedViewTap() {
        self.searchBar.endEditing(true)
        self.fadedView.userInteractionEnabled = false
        self.fadedView.alpha = 0
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let cell = sender as! UITableViewCell
        let indexPath = tableView.indexPathForCell(cell)!
        
        let movie = searchActive ? filtered[indexPath.row] : movies![indexPath.row]
        
        let movieDetailsViewController = segue.destinationViewController as! MovieDetailsViewController
        movieDetailsViewController.movie = movie
        
        self.searchBar.endEditing(true)
        self.fadedView.userInteractionEnabled = false
        self.fadedView.alpha = 0
    }
}
