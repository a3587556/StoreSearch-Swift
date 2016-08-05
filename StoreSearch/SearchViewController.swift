//
//  ViewController.swift
//  StoreSearch
//
//  Created by xyy on 16/3/10.
//  Copyright © 2016年 xyy. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    var searchResults = [SearchResult]()
    var hasSearched = false
    var isLoading = false
    
    struct TableViewCellIdentifiers {
        static let searchResultCell = "SearchResultCell"
        static let nothingFoundCell = "NothingFoundCell"
        static let loadingCell = "LoadingCell"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.contentInset = UIEdgeInsets(top: 64, left: 0, bottom: 0, right: 0)
        tableView.rowHeight = 80
        var cellNib = UINib(nibName: TableViewCellIdentifiers.searchResultCell, bundle: nil)
        tableView.registerNib(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.searchResultCell)
        
        cellNib = UINib(nibName: TableViewCellIdentifiers.nothingFoundCell, bundle: nil)
        tableView.registerNib(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.nothingFoundCell)
        
        cellNib = UINib(nibName: TableViewCellIdentifiers.loadingCell, bundle: nil)
        tableView.registerNib(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.loadingCell)
        searchBar.becomeFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func urlWithSearchText(searchText: String) -> NSURL {
        let escapedSearchText = searchText.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
        let urlString = String(format: "https://itunes.apple.com/search?term=%@", escapedSearchText)
        let url = NSURL(string: urlString)
        return url!
    }
    
    
    
    func parseJSON(data: NSData) -> [String: AnyObject]? {
        do {
            return try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String: AnyObject]
        } catch {
            print("JSON Error: \(error)")
            return nil
        }
    }
    
    func parseDictionary(dictionary: [String: AnyObject]) -> [SearchResult] {
        guard let array = dictionary["results"] as? [AnyObject] else {
            print("Expected 'results' array")
            return []
        }
        
        var searchResults = [SearchResult]()
        
        for resultDict in array {
            if let resultDict = resultDict as? [String: AnyObject] {
                var searchResult: SearchResult?
                
                if let wrapperType = resultDict["wrapperType"] as? String {
                    switch wrapperType {
                    case "track":
                        searchResult = parseTrack(resultDict)
                    case "audiobook":
                        searchResult = parseAudioBook(resultDict)
                    case "software":
                        searchResult = parseSoftware(resultDict)
                    default:
                        break
                    }
                } else if let kind = resultDict["kind"] as? String
                    where kind == "ebook" {
                    searchResult = parseEBook(resultDict)
                }
                
                if let result = searchResult {
                    searchResults.append(result)
                }
            }
        }
        
        return searchResults
    }

    func parseTrack(dictionary: [String: AnyObject]) -> SearchResult {
        let searchRestult = SearchResult()
        
        searchRestult.name = dictionary["trackName"] as! String
        searchRestult.artistName = dictionary["artistName"] as! String
        searchRestult.artworkURL60 = dictionary["artworkUrl60"] as! String
        searchRestult.artworkURL100 = dictionary["artworkUrl100"] as! String
        searchRestult.storeURL = dictionary["trackViewUrl"] as! String
        searchRestult.kind = dictionary["kind"] as! String
        searchRestult.currency = dictionary["currency"] as! String
        
        if let price = dictionary["trackPrice"] as? Double {
            searchRestult.price = price
        }
        if let genre = dictionary["primaryGenName"] as? String {
            searchRestult.genre = genre
        }
        return searchRestult
    }
    
    func parseAudioBook(dictionary: [String: AnyObject]) -> SearchResult {
        let searchRestult = SearchResult()
        searchRestult.name = dictionary["collectionName"] as! String
        searchRestult.artistName = dictionary["artistName"] as! String
        searchRestult.artworkURL60 = dictionary["artworkUrl60"] as! String
        searchRestult.artworkURL100 = dictionary["artworkUrl100"] as! String
        searchRestult.storeURL = dictionary["collectionViewUrl"] as! String
        searchRestult.kind = "audiobook"
        searchRestult.currency = dictionary["currency"] as! String
        
        if let price = dictionary["collectionPrice"] as? Double {
            searchRestult.price = price
        }
        if let genre = dictionary["primaryGenName"] as? String {
            searchRestult.genre = genre
        }
        return searchRestult
    }
    
    func parseSoftware(dictionary: [String: AnyObject]) -> SearchResult {
        let searchRestult = SearchResult()
        searchRestult.name = dictionary["trackName"] as! String
        searchRestult.artistName = dictionary["artistName"] as! String
        searchRestult.artworkURL60 = dictionary["artworkUrl60"] as! String
        searchRestult.artworkURL100 = dictionary["artworkUrl100"] as! String
        searchRestult.storeURL = dictionary["trackViewUrl"] as! String
        searchRestult.kind = dictionary["kind"] as! String
        searchRestult.currency = dictionary["currency"] as! String
        
        if let price = dictionary["price"] as? Double {
            searchRestult.price = price
        }
        if let genre = dictionary["primaryGenName"] as? String {
            searchRestult.genre = genre
        }
        return searchRestult
    }
    
    func parseEBook(dictionary: [String: AnyObject]) -> SearchResult {
        let searchRestult = SearchResult()
        searchRestult.name = dictionary["trackName"] as! String
        searchRestult.artistName = dictionary["artistName"] as! String
        searchRestult.artworkURL60 = dictionary["artworkUrl60"] as! String
        searchRestult.artworkURL100 = dictionary["artworkUrl100"] as! String
        searchRestult.storeURL = dictionary["trackViewUrl"] as! String
        searchRestult.kind = dictionary["kind"] as! String
        searchRestult.currency = dictionary["currency"] as! String
        
        if let price = dictionary["price"] as? Double {
            searchRestult.price = price
        }
        if let genres: AnyObject = dictionary["genres"] {
            searchRestult.genre = (genres as! [String]).joinWithSeparator(", ")
        }
        return searchRestult
    }
    
    func showNetworkError() {
        let alert = UIAlertController(
            title: "Whoops...",
            message: "There was an error reading from the iTunes Store. Please try again.",
            preferredStyle: UIAlertControllerStyle.Alert)
        
        let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alert.addAction(action)
        
        presentViewController(alert, animated: true, completion: nil)
    }

    func kindForDisplay(kind: String) -> String {
        switch kind {
            case "album": return "Album"
            case "audiobook": return "Audio Book"
            case "book": return "Book"
            case "ebook": return "E-Book"
            case "feature-movie": return "Movie"
            case "music-video": return "Music Video"
            case "podcast": return "Podcast"
            case "software": return "Software"
            case "song": return "Song"
            case "tv-episode": return "TV Episode"
            default: return kind
        }
    }
}

extension SearchViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        if !searchBar.text!.isEmpty {
            searchBar.resignFirstResponder()
            
            isLoading = true
            tableView.reloadData()
            
            hasSearched = true
            searchResults = [SearchResult]()
            
            let url = urlWithSearchText(searchBar.text!)
            let session = NSURLSession.sharedSession()
            let dataTask = session.dataTaskWithURL(url, completionHandler: {
                data, response, error in
                if let error = error {
                    print("Failure! \(error)")
                } else if let httpResponse = response as? NSHTTPURLResponse
                    where httpResponse.statusCode == 200 {
                        if let data = data, dictionary = self.parseJSON(data) {
                            self.searchResults = self.parseDictionary(dictionary)
                            self.searchResults.sortInPlace(<)
                            
                            dispatch_async(dispatch_get_main_queue()) {
                                self.isLoading = false
                                self.tableView.reloadData()
                            }
                            return
                        }
                } else {
                    print("Failure! \(response!)")
                }
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.hasSearched = false
                    self.isLoading = false
                    self.tableView.reloadData()
                    self.showNetworkError()
                }
            })
            dataTask.resume()
            
            
            /*let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
            
            dispatch_async(queue) {
                let url = self.urlWithSearchText(searchBar.text!)
                //print("URL: '\(url)'")
                if let jsonString = self.performStoreRequestWithURL(url),
                   let dictionary = self.parseJSON(jsonString) {
                        //print("Received JSON string '\(jsonString)'")
                        //print("Dictionary \(dictionary)")
                        
                        self.searchResults = self.parseDictionary(dictionary)
                        self.searchResults.sortInPlace { $0 < $1}
                    
                        dispatch_async(dispatch_get_main_queue()) {
                            self.isLoading = false
                            self.tableView.reloadData()
                        }
                        //print("DONE!")
                        return
                    }
                dispatch_async(dispatch_get_main_queue()) {
                    self.showNetworkError()
                }
            }*/
        }
    }

    
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return .TopAttached
    }
}

extension SearchViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isLoading {
            return 1
        } else if !hasSearched {
            return 0
        } else if searchResults.count == 0 {
            return 1
        } else {
            return searchResults.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
//        let cellIdentifier = "SearchResultCell"
//        
//        var cell: UITableViewCell! = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)
//        if cell == nil {
//            cell = UITableViewCell(style: .Subtitle, reuseIdentifier: cellIdentifier)
//        }
        
        
        if  isLoading {
            return tableView.dequeueReusableCellWithIdentifier(TableViewCellIdentifiers.loadingCell, forIndexPath: indexPath)
        } else if searchResults.count == 0 {
            return tableView.dequeueReusableCellWithIdentifier(TableViewCellIdentifiers.nothingFoundCell, forIndexPath: indexPath)
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(TableViewCellIdentifiers.searchResultCell, forIndexPath: indexPath) as! SearchResultCell
            let searchResult = searchResults[indexPath.row]
            cell.nameLabel.text = searchResult.name
            //cell.artistNameLabel.text = searchResult.artistName
            if searchResult.artistName.isEmpty {
                cell.artistNameLabel.text = "Unknown"
            } else {
                cell.artistNameLabel.text = String(format: "%@ (%@)", searchResult.artistName, kindForDisplay(searchResult.kind))
            }
                
            return cell
        }
    }
}

extension SearchViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if searchResults.count == 0 || isLoading {
            return nil
        } else {
            return indexPath
        }
    }
}

